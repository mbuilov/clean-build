#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# system shell utilities - WINDOWS specific

# this file is included by $(cb_dir)/core/_defs.mk

# common utilities definitions
include $(dir $(lastword $(MAKEFILE_LIST)))common.mk

ifneq (,$(filter /%,$(CURDIR)))
$(error Unix version of Gnu Make does not work with cmd.exe as SHELL - please \
  select Unix shell utilities (start build with CBLD_UTILS=unix) or use Gnu Make built \
  natively for the Windows platform (see https://github.com/mbuilov/gnumake-windows).$(newline)Tip: \
  under Cygwin, native Gnu Make be called like this: /cygdrive/c/tools/gnumake-4.2.1.exe <goals>)
endif

# synchronize make output for parallel builds
MAKEFLAGS += -O

# by default, check and fix SHELL - internal variable of Gnu Make
CBLD_DONT_FIX_MAKE_SHELL ?=

ifeq (,$(CBLD_DONT_FIX_MAKE_SHELL))

# SHELL must be cmd.exe, not /bin/sh (if build is started from the Cygwin/Msys shell)
# note: by default, ComSpec/SystemRoot are defined if build was started from cmd.exe window
#  else, if build was started from Cygwin/Msys shell - COMSPEC/SYSTEMROOT are defined
ifneq (cmd.exe,$(notdir $(SHELL)))
ifneq (undefined,$(origin ComSpec))
SHELL := $(ComSpec)
else ifneq (undefined,$(origin COMSPEC))
SHELL := $(COMSPEC)
else ifneq (undefined,$(origin SystemRoot))
SHELL := $(SystemRoot)\System32\cmd.exe
else ifneq (undefined,$(origin SYSTEMROOT))
SHELL := $(SYSTEMROOT)\System32\cmd.exe
else
$(error unable to determine path to cmd.exe for the SHELL: both COMSPEC and SYSTEMROOT variables are undefined,$(newline)please \
  specify SHELL explicitly, e.g. $(MAKE) SHELL=C:\Windows\System32\cmd.exe)
endif
endif # SHELL != cmd.exe

endif # !CBLD_DONT_FIX_MAKE_SHELL

# by default, fix environment variable PATH
CBLD_DONT_FIX_ENV_PATH ?=

ifeq (,$(CBLD_DONT_FIX_ENV_PATH))

# system root path, e.g. C:\Windows
# note: do not protect 'sysroot' - it is used temporary
ifneq (undefined,$(origin SystemRoot))
sysroot := $(SystemRoot)
else ifneq (undefined,$(origin SYSTEMROOT))
sysroot := $(SYSTEMROOT)
else
$(error unable to determine system root path: both SystemRoot and SYSTEMROOT variables are undefined)
endif

# fix environment variable PATH - use native Windows utilities (find, cd, mkdir, etc.) over than Cygwin/Msys ones
# note: do not protect 'filt_sysroot' - it is used temporary
filt_sysroot = $(strip $(filter $2,$1) $(filter-out $2,$1))
PATH := $(call unhide_raw,$(subst $(space),;,$(call filt_sysroot,$(subst ;, ,$(call hide_spaces,$(PATH))),$(sysroot) $(sysroot)\\%)))

# do not complain about changed environment variable
$(call env_remember,PATH)

# save new PATH value to the generated configuration makefile
# note: pass 1 as second argument to 'config_remember_vars' - to forcibly export variable PATH
# note: pass 1 as third argument to 'config_remember_vars' - to save a new value of the PATH
$(call config_remember_vars,PATH,1,1)

endif # !CBLD_DONT_FIX_ENV_PATH

# script to print prepared environment in verbose mode (used for generating one-big-build instructions batch file)
# note: 'sh_print_env' - used by $(cb_dir)/core/all.mk
sh_print_env = $(if $(or $(cb_changed_env_vars),$(project_exported_vars)),setlocal$(newline)$(foreach \
  =,$(call uniq,$(project_exported_vars) $(cb_changed_env_vars)),SET "$==$($=)"$(newline)|))

# command line length of cmd.exe is limited:
# for Windows 95   - 127 chars;
# for Windows 2000 - 2047 chars;
# for Windows XP   - 8191 chars (max 31 path arguments of 260 chars length each);
# define the maximum number of path arguments that may be passed via the command line,
# assuming we use Windows XP or later and paths do not exceed 120 chars:
CBLD_MAX_PATH_ARGS ?= 68

# null device for redirecting output into
NUL ?= NUL

# standard tools
# note: most of them are builtin commands of cmd.exe, except: find, findstr, fc
DEL     ?= del
RD      ?= rd
CD      ?= cd
CMD     ?= cmd
FIND    ?= find
EXIT    ?= exit
FINDSTR ?= findstr
COPY    ?= copy
MOVE    ?= move
DIR     ?= dir
MD      ?= md
FC      ?= fc
TYPE    ?= type

# note: assume 'echo' and 'rem' are builtin commands of cmd.exe, they are used in special forms:
#  'echo.' - to print an empty line (ended with CRLF)
#  'rem.>' - to create an empty file (of zero size)

# escape program argument to pass it via shell: 1 " 2 -> "1 "" 2"
# NOTE: assume Gnu Make calls a rule in batch-mode (via temporary created .bat-file), otherwise no need to escape %
#  (this may be a bug in Gnu Make - it should run command via .bat-file if there is % in the command)
# NOTE: cmd.exe requires escaping backslashes \ only if they are before double-quote ", proper escaping described here:
#  https://blogs.msdn.microsoft.com/twistylittlepassagesallalike/2011/04/23/everyone-quotes-command-line-arguments-the-wrong-way
# note: for now, process maximum 4 backslashes before double-quote or at end of argument: \\\\" or x\\\\
# note: not expecting newlines in $1
shell_escape = $(subst \
  \\\\\\\",\\\\\\\\",$(subst \
  \\\\\",\\\\\\",$(subst \
  \\\",\\\\",$(subst \
  \",\\",$(subst %,%%,"$(subst ","",$1)")))))

# convert escaped program arguments string to the form accepted by standard unix shell, e.g.: c:\file "1 "" 2" -> c:\\file '1 " 2'
# note: assume arguments are escaped by 'shell_escape' macro, except paths, which are - result of 'ospath' macro
# NOTE: cmd.exe requires escaping backslashes \ only if they are before double-quote ", proper escaping described here:
#  https://blogs.msdn.microsoft.com/twistylittlepassagesallalike/2011/04/23/everyone-quotes-command-line-arguments-the-wrong-way
# note: for now, process maximum 4 escaped backslashes before double-quotes: \\\\\\\\"
# note: not expecting newlines in $1
# note: assume double-quotes are escaped only by two double-quotes inside double-quotes, e.g.: "1""2" -> 1"2
# note: assume single quotes may be found only inside double-quotes, e.g.: "a'b" -> a'b
# algorithm:
# 1) hide $, tabs and spaces, so there are no single $ inside the result, except $(space) or $(tab): <1 2$3> -> <1$(space)2$$3>
# 2) un-escape % escaped by two %: %% -> %
# 3) un-escaped backslashes before double-quotes: \\" -> \"
# 4) replace two adjacent double-quotes and identify tokens: <1""2> -> <1 +$+ 2>
# 5) identify backslashes as tokens:                         <1/2>  -> <1 / 2>
# 6) identify double-quotes as tokens:                       <"1">  -> < " 1 " >
# 7) in "quote-mode":
#   "    - ends "quote-mode",          print '     "..."    ->   '...'
#   +$+  - escaped double quote,       print "     "...""   ->   '..."
#   '    - escape quote to pass it via unix shell  "...a'b  ->   '...a'"'"'b
# 8) in "double-quote-mode":
#   "    - escaped double quote,       print "     """      ->   '"   change to "quote-mode"  (for ex. """1"    -> '"1')
#   +$+  - escaped double quote,       print "     """"     ->   '"                           (for ex. """""1"  -> '""1'  or """" -> '"')
#   else - ends "double-quote-mode",   print '     ""a      ->   ''a
# 9)  "   - enter "quote-mode",        print '
# 10) +$+ - enter "double-quote-mode", print '
# 11) else - escape unquoted backslashes: \\ -> \
# 12) at end of line, if in "double-quote-mode", then add terminating quote
shell_args_to_unix = $(call unhide_comments,$(subst $(space),,$(eval _q:=)$(eval _d:=)$(foreach x,$(subst \
  ", " ,$(subst \
  \, \ ,$(subst \
  "", +$$+ ,$(subst \
  \\\\\",\\\\",$(subst \
  \\\\",\\\",$(subst \
  \\\",\\",$(subst \
  \\",\",$(subst \
  %%,%,$(hide_tab_spaces))))))))),$(if \
  $(_q),$(if $(findstring \
    ",$x),$(eval _q:=)',$(if $(findstring \
    +$$+,$x),",$(subst ','"'"',$x))),$(if \
  $(_d),$(if $(findstring \
    ",$x),"$(eval _d:=)$(eval _q:=1),$(if $(findstring \
    +$$+,$x),",$(eval _d:=)')),$(if $(findstring \
  ",$x),$(eval _q:=1)',$(if $(findstring \
  +$$+,$x),$(eval _d:=')',$(subst \,\\,$x))))))))$(_d)

# remove (delete) files $1 (short list, no more than CBLD_MAX_PATH_ARGS)
# note: if a path contains a space, use 'ifaddq' to add double-quotes: "1 2/3 4" "5 6/7 8/9" ...
sh_rm_some_files = for %%f in ($(ospath)) do if exist %%f $(DEL) /f /q %%f

# remove (delete) directories $1 (recursively) (short list, no more than CBLD_MAX_PATH_ARGS)
# note: if a path contains a space, use 'ifaddq' to add double-quotes: "1 2/3 4" "5 6/7 8/9" ...
sh_rm_some_dirs = for %%f in ($(ospath)) do if exist %%f $(RD) /s /q %%f

# try to non-recursively remove directories $1 if they are empty (short list, no more than CBLD_MAX_PATH_ARGS)
# note: if a path contains a space, use 'ifaddq' to add double-quotes: "1 2/3 4" "5 6/7 8/9" ...
# note: if directory is not empty, ignore an error
sh_try_rm_some_empty_dirs = $(RD) $(ospath) 2>$(NUL)

# in directory $1 (path may contain spaces), delete files $2 (long list)
# note: to support long list, paths in $2 _must_ not contain spaces
# note: if path to directory $1 contains a space, use 'ifaddq' to add double-quotes: "1 2/3 4"
# note: $6 - empty on first call, $(newline) on next calls
sh_rm_files_in2 = $(CD) $2 && for %%f in ($1) do if exist %%f $(DEL) /f /q %%f
ifdef quiet
sh_rm_files_in1 = $(if $6,$(quiet))$(sh_rm_files_in2)
else # verbose
# show info about files $1 deleted in directory $2, this info may be printed to build script
sh_rm_files_in1 = $(info ( $(sh_rm_files_in2) ))@$(sh_rm_files_in2)
endif # verbose
sh_rm_files_in  = $(call xcmd,sh_rm_files_in1,$(call ospath,$2),$(CBLD_MAX_PATH_ARGS),$(ospath))

# delete files/directories (recursively) (long list)
# note: to support long list, the paths _must_ not contain spaces
# note: $6 - empty on first call, $(newline) on next calls
sh_rm_recursive1 = $(if $6,$(quiet))for %%f in ($1) do if exist %%f\. ($(RD) /s /q %%f) else if exist %%f $(DEL) /f /q %%f
sh_rm_recursive  = $(call xcmd,sh_rm_recursive1,$(ospath),$(CBLD_MAX_PATH_ARGS))

# filter output of the 'copy' or 'move' command:
#  - if there is anything other than the filtered-out string "        1", result will be zero - assume copy/move failed
# note: send error messages to stderr
cmd_filter_copy_output := >&2 $(FIND) /V"        1"

# code for suppressing output of the 'copy' command, like
# "        1 file(s) copied."
# "Скопировано файлов:         1."
cmd_suppress_copy_output := | $(cmd_filter_copy_output) & if errorlevel 1 ($(CMD) /c) else $(CMD) /c $(EXIT) 1

# code for suppressing output of the 'move' command, like
# "        1 file(s) moved."
# "Перемещено файлов:         1."
# "        1 папок перемещено."
# note: WinXP's move doesn't output anything on success
cmd_suppress_move_output := $(cmd_suppress_copy_output)

# copy files (long list) preserving modification date:
# - files $1 to directory $2 (paths to files $1 _must_ not contain spaces, but path to directory $2 may contain spaces) or
# - file $1 to file $2       (path to file $1 _must_ not contain spaces, but path to file $2 may contain spaces)
# note: $6 - empty on first call, $(newline) on next calls
# note: if path to directory/file $2 contains a space, use 'ifaddq' to add double-quotes: "1 2/3 4"
sh_copy_files1 = $(if $6,$(quiet))for %%f in ($1) do $(COPY) /y /b %%f $2$(cmd_suppress_copy_output)
sh_copy_files  = $(if $(findstring $(space),$1),$(call xcmd,sh_copy_files1,$(ospath),$(CBLD_MAX_PATH_ARGS),$(call \
  ospath,$2)),$(COPY) /y /b $(call ospath,$1 $2)$(cmd_suppress_copy_output))

# move files/directories (long list) preserving modification date:
# - files/directories $1 to directory $2 (paths to entries $1 _must_ not contain spaces, but path to directory $2 may contain spaces) or
# - file $1 to file $2                   (path to file $1 _must_ not contain spaces, but path to file $2 may contain spaces) or
# - directory $1 to directory $2         (path to directory $1 _must_ not contain spaces, but path to directory $2 may contain spaces)
# note: if $2 is an existing directory, files/directories $1 are moved _under_ it
# note: $6 - empty on first call, $(newline) on next calls
# note: if path to directory/file $2 contains a space, use 'ifaddq' to add double-quotes: "1 2/3 4"
sh_move1 = $(if $6,$(quiet))for %%f in ($1) do $(MOVE) /y %%f $2$(cmd_suppress_move_output)
sh_move  = $(if $(findstring $(space),$1),$(call xcmd,sh_move1,$(ospath),$(CBLD_MAX_PATH_ARGS),$(call \
  ospath,$2)),$(MOVE) /y $(call ospath,$1 $2)$(cmd_suppress_move_output))

# create symbolic links to files (long list):
# - to files $1 in directory $2 (paths to files $1 _must_ not contain spaces, but path to directory $2 may contain spaces) or
# - to file $1 by simlink $2    (path to file $1 _must_ not contain spaces, but path to simlink $2 may contain spaces)
# note: if path to directory/file $2 contains a space, use 'ifaddq' to add double-quotes: "1 2/3 4"
# note: may be use mklink command - starting with Windows Vista... but mklink requires special privileges, see:
#  https://superuser.com/questions/124679/how-do-i-create-a-link-in-windows-7-home-premium-as-a-regular-user/125981#125981
# note: for now, just copy files (preserving modification date)
sh_simlink_files = $(sh_copy_files)

# update modification date of given files (long list) or create them if they do not exist
# note: to support long list, the paths _must_ not contain spaces
# note: $6 - empty on first call, $(newline) on next calls
sh_touch1 = $(if $6,$(quiet))for %%f in ($1) do if exist %%f ($(COPY) /y /b %%f+,, %%f$(cmd_suppress_copy_output)) else rem.> %%f
sh_touch  = $(call xcmd,sh_touch1,$(ospath),$(CBLD_MAX_PATH_ARGS))

# create directory
#
# NOTE! there are races in mkdir - if make spawns two parallel jobs:
#
# if not exist aaa
#                        if not exist aaa/bbb
#                        mkdir aaa/bbb
# mkdir aaa - fail
#
# note: to avoid races, 'sh_mkdir' must be called only if it's known that destination directory does not exist
# note: 'sh_mkdir' must create intermediate parent directories of the destination directory
# note: if path to directory $1 contains a space, use 'ifaddq' to add double-quotes: "1 2/3 4"
# NOTE: to avoid races, there must be no other commands running in parallel and creating child sub-directories of new sub-directories
#  created by this command
sh_mkdir = $(MD) $(ospath)

# copy recursively directory $1 (path may contain spaces) to directory $2 (path may contain spaces)
# note: if $2 - is an existing directory, a copy is created _under_ it
# note: if path to directory $1 or $2 contains a space, use 'ifaddq' to add double-quotes: "1 2/3 4"
# note: preserve modification date of copied files and directories
# note: paths $1 and $2 _must_ be absolute (Windows-implementation specific requirement)
# note: send error messages to stderr
# NOTE: to avoid races, there must be no other commands running in parallel and creating child sub-directories of new sub-directories
#  created by this command
sh_copy_dir = $(call sh_copy_dir1,$(call ospath,$(if $(findstring ",$1),$1,"$1")),$(call \
  ospath,$(if $(findstring ",$2),$2,"$2")),$(words $(filter /,$(subst /, / ,$1))))

# $1 - "C:\1\2\3 4"
# $2 - "C:\1\2\5\6 7"
# $3 - 3
sh_copy_dir1 = $(call sh_copy_dir2,$1,$2,$3,$(subst "%%x\%%y,%%x\%%y",$2%%x\%%y),$(subst "%%y,%%y",$2%%y))

# $1 - "C:\1\2\3 4"
# $2 - "C:\1\2\5\6 7"
# $3 - 3
# $4 - "C:\1\2\5\6 7\%%x\%%y"
# $5 - "C:\1\2\5\6 7\%%y"
sh_copy_dir2 = 2>&1 (^(if exist $2 \
  ^(for /r $1 %%f in ^(.^) do @for /f "tokens=$3* delims=$(backslash)" %%x in ^("%%~pnf"^) do \
  @^(if not exist $4 $(MD) $4^) ^& ^(^>$(NUL) 2^>^&1 $(DIR) /b /a-d "%%~dpnf" ^&^& ^>$(NUL) $(COPY) /y /b "%%~dpnf\*" $4^)^) else \
    for /r $1 %%f in ^(.^) do @for /f "tokens=$3* delims=$(backslash)" %%x in ^("%%~pnf"^) do \
  @^(if not exist $5 $(MD) $5^) ^& ^(^>$(NUL) 2^>^&1 $(DIR) /b /a-d "%%~dpnf" ^&^& ^>$(NUL) $(COPY) /y /b "%%~dpnf\*" $5^)^)) \
  | >&2 $(FIND) /V"" & if errorlevel 1 ($(CMD) /c) else $(CMD) /c $(EXIT) 1

# create symbolic link to directory $1 from $2
# note: if $2 - is an existing directory, a simlink is created _under_ it
# note: if path to directory $1 or $2 contains a space, use 'ifaddq' to add double-quotes: "1 2/3 4"
# note: may be use mklink command - starting with Windows Vista... but mklink requires special privileges, see:
#  https://superuser.com/questions/124679/how-do-i-create-a-link-in-windows-7-home-premium-as-a-regular-user/125981#125981
# note: for now, just copy files (preserving modification date)
sh_simlink_dir = $(sh_copy_dir)

# compare content of two text files: $1 and $2
# raise an error if they are differ
# note: if path to a file contains a space, use 'ifaddq' to add double-quotes: "1 2/3 4"
sh_cmp_files = $(FC) /t $(call ospath,$1 $2)

# print content of a given file (to stdout, for redirecting it to output file)
# note: if path to file $1 contains a space, use 'ifaddq' to add double-quotes: "1 2/3 4"
sh_cat = $(TYPE) $(ospath)

# escape special characters in unquoted argument of 'echo' or 'set' builtin commands of cmd.exe
cmd_unquoted_escape = $(subst $(open_brace),^$(open_brace),$(subst $(close_brace),^$(close_brace),$(subst \
  %,%%,$(subst !,^!,$(subst <,^<,$(subst >,^>,$(subst |,^|,$(subst &,^&,$(subst ",^",$(subst ^,^^,$1))))))))))

# print short string of options (to stdout, for redirecting it to output file)
# note: string $1 must not begin with '=', leading spaces and tabs are will be ignored
# note: there must be no $(newline)s in the string $1
# note: surround whole set expression by braces to specify the end of argument (to not ignore trailing spaces)
# note: ignore result of builtin command 'set' - it's failed always
# NOTE: printed string length must not exceed the maximum command line length (8191 characters)
sh_print_some_options = ((set/p=$(cmd_unquoted_escape))<NUL & $(CMD) /c)

# write batch of text token groups to output file or to stdout (for redirecting it to output file)
# $1 - list of token groups, where entries are processed by $(call hide,$(cmd_unquoted_escape))
# $2 - if not empty, then a file to print to (path to the file may contain spaces)
# $3 - text to prepend before the command when $6 is non-empty
# $4 - text to prepend before the command when $6 is empty
# $6 - empty if overwrite file $2, non-empty if append text to it
# note: first token of any group must not be '=', leading $(space)s and $(tab)s are will be ignored
# note: there must be no $(newline)s among text tokens
# note: surround whole set expression by braces to specify the end of argument (to not ignore trailing spaces)
# note: ignore result of builtin command 'set' - it's failed always
# note: if path to file $2 contains a space, use 'ifaddq' to add double-quotes: "1 2/3 4"
# NOTE: printed batch length must not exceed the maximum command line length (8191 characters)
sh_write_options1 = $(if $6,$3,$4)((set/p=$(call unhide_comments,$(subst $(space),,$1)))<NUL & $(CMD) /c)$(if $2,>$(if $6,>) $2)

# tokenize string so each token group will not begin with $(space), $(tab) or '=', except if they are at the beginning
# "1  2 =3" -> "1 $s  $s 2 $s =3" -> "1 $s  $s 2 $s = 3" -> "1 $s $s 2 $s = 3" -> "1$(space)$(space) 2$(space)= 3"
# note: ignore spaces, tabs or = at the beginning
tokenize_options = $(wordlist 2,999999,$(subst $(space)=,=,$(subst $(space)$$t,$$(tab),$(subst $(space)$$s,$$(space),$(strip \
  $(subst $(space)=, = ,$(subst $(tab), $$t ,$(subst $(space), $$s , $(hide)))))))))

# write string of options $1 to file $2, by $3 token groups at one time
# note: string $1 must not begin with '=', leading spaces and tabs are will be ignored
# note: there must be no $(newline)s in the string $1
# note: if path to file $2 contains a space, use 'ifaddq' to add double-quotes: "1 2/3 4"
# NOTE: number $3 must be adjusted so printed at one time text length will not exceed the maximum command length (8191 characters)
# NOTE: nothing is printed if string $1 is empty, output file is _not_ created in this case
sh_write_options = $(call xargs,sh_write_options1,$(call tokenize_options,$(cmd_unquoted_escape)),$3,$2,$(quiet),,,$(newline))

# print one short line of text (to stdout, for redirecting it to output file)
# note: line must not contain $(newline)s
# note: line will be ended with CRLF: line -> line\n
# note: use dot '.' after 'echo' to print just an empty line if text $1 is empty
# note: surround whole echo expression by braces to specify the end of argument (to not ignore trailing spaces)
# NOTE: printed line length must not exceed the maximum command line length (8191 characters)
sh_print_short_line = (echo.$(cmd_unquoted_escape))

# print small batch of short text lines (to stdout, for redirecting it to output file)
# note: each line will be ended with CRLF: line1$(newline)line2 -> line1\nline2\n
# note: use dot '.' after 'echo' to print just an empty line if text line is empty
# note: surround whole echo expression by braces to specify the end of argument (to not ignore trailing spaces)
# NOTE: total text length must not exceed the maximum command line length (8191 characters)
sh_print_some_lines = ((echo.$(subst $(newline),$(close_brace)&&$(open_brace)echo.,$(cmd_unquoted_escape))))

# write batch of text lines to output file or to stdout (for redirecting it to output file)
# $1 - lines list, where entries are processed by $(call hide_tab_spaces,$(cmd_unquoted_escape))
# $2 - if not empty, then a file to print to (path to the file may contain spaces)
# $3 - text to prepend before the command when $6 is non-empty
# $4 - text to prepend before the command when $6 is empty
# $6 - empty if overwrite file $2, non-empty if append text to it
# note: if path to file $2 contains a space, use 'ifaddq' to add double-quotes: "1 2/3 4"
# note: each line will be ended with CRLF: line1$(space)line2 -> line1\nline2\n
# NOTE: printed batch length must not exceed the maximum command line length (8191 characters)
sh_write_lines1 = $(if $6,$3,$4)((echo.$(call \
  unhide_comments,$(subst $(space),$(close_brace)&&$(open_brace)echo.,$1))))$(if $2,>$(if $6,>) $2)

# write lines of text $1 to file $2, by $3 lines at one time
# note: if path to file $2 contains a space, use 'ifaddq' to add double-quotes: "1 2/3 4"
# NOTE: any line must be less than the maximum command length (8191 characters)
# NOTE: number $3 must be adjusted so printed at one time text length will not exceed the maximum command length (8191 characters)
# NOTE: nothing is printed if text $1 is empty, output file is _not_ created in this case
sh_write_lines = $(call xargs,sh_write_lines1,$(subst $(space) , $$(empty) ,$(subst $(space) , $$(empty) ,$(subst \
  $(newline), ,$$(empty)$(call hide_tab_spaces,$(cmd_unquoted_escape))$$(empty)))),$3,$2,$(quiet),,,$(newline))

# set mode $1 of given files $2 (short list, no more than CBLD_MAX_PATH_ARGS)
# note: UNIX-specific, so not defined for WINDOWS
sh_chmod_some_files:=

# set mode $1 of given files $2 (long list)
# note: UNIX-specific, so not defined for WINDOWS
sh_chmod:=

# execute command $2 in the directory $1
# note: if path to directory $1 contains a space, use 'ifaddq' to add double-quotes: "1 2/3 4"
sh_execute_in = $(CD) $(ospath) && $2

# show info about command $2 executed in the directory $1, this info may be printed to build script
# note: if path to directory $1 contains a space, use 'ifaddq' to add double-quotes: "1 2/3 4"
sh_execute_in_info = pushd $(ospath) && ($2 && popd || (popd & $(CMD) /c $(EXIT) 1))

# delete target files (short list, no more than CBLD_MAX_PATH_ARGS) if failed to build them and exit shell with error code 1
del_on_fail = || (($(sh_rm_some_files)) & $(CMD) /c $(EXIT) 1)

# create directory (with intermediate parent directories) while installing things
# $1 - path to the directory to create, path may contain spaces
# note: if path to directory $1 contains a space, use 'ifaddq' to add double-quotes: "1 2/3 4"
# note: directory $1 must not exist, 'sh_install_dir' may be implemented via 'sh_mkdir' (e.g. under WINDOWS)
sh_install_dir = $(sh_mkdir)

# install files (long list) to directory or copy file to file
# $1 - files to install (to support long list, paths _must_ not contain spaces)
# $2 - destination directory or file, path may contain spaces
# $3 - optional access mode, such as 644 (rw--r--r-) or 755 (rwxr-xr-x)
# note: if path to directory/file $2 contains a space, use 'ifaddq' to add double-quotes: "1 2/3 4"
sh_install_files = $(sh_copy_files)

# paths separator, as used in %PATH% environment variable
# note: override 'pathsep' macro from $(cb_dir)/core/runtool.mk
pathsep := ;

# if PATH environment variable was modified for calling a tool, print new PATH value for the generated batch
# $1 - tool to execute (with parameters - escaped by 'shell_escape' macro)
# $2 - additional paths separated by $(pathsep) to append to $(dll_path_var)
# $3 - directory to change to for executing a tool
# $4 - names of variables to set in the environment (export) to run given tool
# note: override 'show_tool_vars' macro from $(cb_dir)/core/runtool.mk
show_tool_vars = $(info setlocal$(foreach =,$(if $2,PATH) $4,$(newline)set $==$(call \
  cmd_unquoted_escape,$($=)))$(newline)$(if $3,$(call sh_execute_in_info,$3,$1),$1))

# show after executing a command
# note: override 'show_tool_vars_end' macro from $(cb_dir)/core/runtool.mk
show_tool_vars_end = $(newline)@echo endlocal

# filter and process command's output through pipe, then send it to stderr
# $1 - command
# $2 - pipe expression to process stdout, must be non-empty, for example: |$(FINDSTR) /BC:ABC |$(FINDSTR) /BC:CDE
# note: when sending output of echo to stderr, cmd.exe inserts a space after 'a', e.g.:
#  3>&2 2>&1 1>&3 echo a>&2|c:\cygwin64\bin\xxd.exe        -> 00000000: 6120 0d0a
#  3>&2 2>&1 1>&3 (echo a)>&2|c:\cygwin64\bin\xxd.exe      -> 00000000: 6120 0d0a
#  3>&2 2>&1 1>&3 ^(echo a^)>&2|c:\cygwin64\bin\xxd.exe    -> invalid command
#  (3>&2 2>&1 1>&3 ^(echo a^)>&2)|c:\cygwin64\bin\xxd.exe  -> 00000000: 610d 0a
cmd_filter_output = (($1 2>&1 &&^(echo ok^)>&2)$2)3>&2 2>&1 1>&3|$(FINDSTR) /XC:ok >$(NUL)

# remember values of variables possibly taken from the environment
$(call config_remember_vars,CBLD_DONT_FIX_MAKE_SHELL SHELL CBLD_DONT_FIX_ENV_PATH CBLD_MAX_PATH_ARGS \
  NUL DEL RD CD CMD FIND EXIT FINDSTR COPY MOVE DIR MD FC TYPE)

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,CBLD_DONT_FIX_MAKE_SHELL SHELL CBLD_DONT_FIX_ENV_PATH CBLD_MAX_PATH_ARGS \
  NUL DEL RD CD CMD FIND EXIT FINDSTR COPY MOVE DIR MD FC TYPE sh_chmod_some_files sh_chmod)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: utils
$(call set_global,sh_print_env=project_exported_vars shell_escape shell_args_to_unix sh_rm_some_files sh_rm_some_dirs \
  sh_try_rm_some_empty_dirs sh_rm_files_in2 sh_rm_files_in1 sh_rm_files_in sh_rm_recursive1 sh_rm_recursive \
  cmd_filter_copy_output cmd_suppress_copy_output cmd_suppress_move_output sh_copy_files1 sh_copy_files sh_move1 sh_move \
  sh_simlink_files sh_touch1 sh_touch sh_mkdir sh_copy_dir sh_copy_dir1 sh_copy_dir2 sh_simlink_dir sh_cmp_files sh_cat \
  cmd_unquoted_escape sh_print_some_options sh_write_options1 tokenize_options sh_write_options sh_print_short_line sh_print_some_lines \
  sh_write_lines1 sh_write_lines sh_execute_in sh_execute_in_info del_on_fail sh_install_dir sh_install_files cmd_filter_output,utils)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: runtool
# note: override macros defined in $(cb_dir)/code/runtool.mk
$(call set_global,pathsep show_tool_vars show_tool_vars_end,runtool)
