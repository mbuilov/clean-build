#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# system shell utilities - WINDOWS specific

# this file is included by $(cb_dir)/core/_defs.mk

# synchronize make output for parallel builds
MAKEFLAGS += -O

ifneq (,$(filter /%,$(CURDIR)))
$(error Unix version of Gnu Make is used with cmd.exe shell utilities - this configuration is not supported, \
  please use Gnu Make executable built natively for the Windows platform (see https://github.com/mbuilov/gnumake-windows).$(newline)Tip: \
  under Cygwin, native Gnu Make may be called as: /cygdrive/c/tools/gnumake-4.2.1.exe SED=C:/tools/sed.exe <args>)
endif

# shell must be cmd.exe, not /bin/sh (if build was started under Cygwin)
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
  set the SHELL explicitly, e.g. $(MAKE) SHELL=C:\Windows\System32\cmd.exe)
endif
endif # SHELL != cmd.exe

# by default, strip off paths to Unix tools from the PATH - to use only native windows shell utilities (find, del, move, md, etc.)
CBLD_DONT_STRIP_PATH ?=

ifndef CBLD_DONT_STRIP_PATH

# note: Cygwin paths may look like: C:\cygwin64\usr\local\bin;C:\cygwin64\bin
# note: Msys paths may look like: C:\msys64\mingw64\bin;C:\msys64\usr\local\bin;C:\msys64\usr\bin
ifneq (,$(or $(findstring \
  :\msys\,$(PATH)),$(findstring \
  :\msys64\,$(PATH)),$(findstring \
  :\cygwin\,$(PATH)),$(findstring \
  :\cygwin64\,$(PATH))))
$(warning stripping off msys/cygwin paths from the PATH - only native Windows tools should be used for the build)
PATH := $(call tospaces,$(subst $(space),;,$(strip $(foreach p,$(subst ;, ,$(call unspaces,$(PATH))),$(if $(or $(findstring \
  :\msys\,$p),$(findstring \
  :\msys64\,$p),$(findstring \
  :\cygwin\,$p),$(findstring \
  :\cygwin64\,$p))),,$p))))
endif

# save new PATH value to the generated configuration makefile
# note: pass 1 as second argument to 'config_remember_vars' - to forcibly export variable PATH
# note: pass 1 as third argument to 'config_remember_vars' - to save a new value of the PATH
$(call config_remember_vars,PATH,1,1)

endif # !CBLD_DONT_STRIP_PATH

# script to print prepared environment in verbose mode (used for generating one-big-build instructions shell file)
# note: 'print_env' - used by $(cb_dir)/core/all.mk
print_env = setlocal$(newline)$(foreach =,$(project_exported_vars),SET "$==$($=)"$(newline)|)

# command line length of cmd.exe is limited:
# for Windows 95   - 127 chars;
# for Windows 2000 - 2047 chars;
# for Windows XP   - 8191 chars (max 31 path arguments of 260 chars length each);
# define the maximum number of path arguments that may be passed via the command line,
# assuming we use Windows XP or later and paths do not exceed 120 chars:
CBLD_MAX_PATH_ARGS ?= 68

# convert forward slashes used by make to backward ones accepted by windows programs
# note: override 'ospath' macro from $(cb_dir)/core/_defs.mk
ospath = $(subst /,\,$1)

# $1 - prefix
# $2 - list of disks (C: D:)
# $3 - list of files prefixed with $1
nonrelpath1 = $(if $2,$(call nonrelpath1,$1,$(wordlist 2,999999,$2),$(patsubst $1$(firstword $2)%,$(firstword $2)%,$3)),$3)

# make path not relative: add prefix $1 only to non-absolute paths in $2
# note: path prefix $1 must end with /
# a/b c:/1 -> xxx/a/b xxx/c:/1 -> xxx/a/b c:/1
# note: override 'nonrelpath' macro from $(cb_dir)/core/_defs.mk
nonrelpath = $(if $(findstring :,$2),$(call nonrelpath1,$1,$(sort $(filter %:,$(subst :,: ,$2))),$(addprefix $1,$2)),$(addprefix $1,$2))

# null device for redirecting output into
NUL ?= NUL

# standard tools
# note: most of them are the commands of the cmd.exe, except: find, findstr, fc, sed
DEL     ?= del
RD      ?= rd
CD      ?= cd
FIND    ?= find
FINDSTR ?= findstr
COPY    ?= copy
MOVE    ?= move
MKDIR   ?= mkdir
FC      ?= fc
SED     ?= sed
TYPE    ?= type
ECHO    ?= echo

# delete file(s) $1 (short list, no more than CBLD_MAX_PATH_ARGS)
# note: if a path contains a space, it must be in double-quotes: "1 2\3 4" "5 6\7 8\9" ...
delete_files = for %%f in ($(ospath)) do if exist %%f $(DEL) /f/q %%f

# delete directories $1 (recursively) (short list, no more than CBLD_MAX_PATH_ARGS)
# note: if a path contains a space, it must be in double-quotes: "1 2\3 4" "5 6\7 8/9" ...
delete_dirs = for %%f in ($(ospath)) do if exist %%f $(RD) /s/q %%f

# try to non-recursively delete directories $1 if they are empty (short list, no more than CBLD_MAX_PATH_ARGS)
# note: if a path contains a space, it must be in double-quotes: "1 2\3 4" "5 6\7 8\9" ...
# note: if directory is not empty, ignore an error
try_delete_dirs = $(RD) $(ospath) 2>$(NUL)

# in a directory $1 (path may contain spaces), delete files $2 (long list)
# note: to support long list, paths in $2 _must_ not contain spaces
# note: if path to the directory $1 contains a space, it must be in double-quotes: "1 2\3 4"
# note: $6 - empty on first call, $(newline) on next calls
delete_files_in1 = $(if $6,$(quiet))$(CD) $2 && for %%f in ($1) do if exist %%f $(DEL) /f/q %%f
delete_files_in  = $(call xcmd,delete_files_in1,$(call ospath,$2),$(CBLD_MAX_PATH_ARGS),$(ospath),,,)

# delete files and/or directories (recursively) (long list)
# note: to support long list, the paths _must_ not contain spaces
# note: $6 - empty on first call, $(newline) on next calls
del_files_or_dirs1 = $(if $6,$(quiet))for %%f in ($1) do if exist %%f\* ($(RD) /s/q %%f) else if exist %%f $(DEL) /f/q %%f
del_files_or_dirs  = $(call xcmd,del_files_or_dirs1,$(ospath),$(CBLD_MAX_PATH_ARGS),,,,)

# filter the output of the 'copy' or 'move' command:
#  - if there is anything other than the filtered-out string "        1", result will be zero - assume copy/move failed
ifdef FIND
filter_copy_output := $(FIND) /V"        1"
else
filter_copy_output := $(FINDSTR) /VC:"        1"
endif

# code for suppressing output of the 'copy' command, like
# "        1 file(s) copied."
# "Скопировано файлов:         1."
suppress_copy_output := | $(filter_copy_output) & if errorlevel 1 (cmd /c) else cmd /c exit 1

# code for suppressing output of the 'move' command, like
# "        1 file(s) moved."
# "Перемещено файлов:         1."
# note: WinXP's move doesn't output anything on success
suppress_move_output := $(suppress_copy_output)

# copy file(s) (long list) preserving modification date:
# - file(s) $1 to directory $2 (paths to files $1 _must_ not contain spaces, but path to directory $2 may contain spaces) or
# - file $1 to file $2         (path to file $1 _must_ not contain spaces, but path to file $2 may contain spaces)
# note: $6 - empty on first call, $(newline) on next calls
# note: if path to the directory/file $2 contains a space, it must be in double-quotes: "1 2\3 4"
copy_files1 = $(if $6,$(quiet))for %%f in ($1) do $(COPY) /y/b %%f $2$(suppress_copy_output)
copy_files  = $(if $(word 2,$1),$(call xcmd,copy_files1,$(ospath),$(CBLD_MAX_PATH_ARGS),$(call \
  ospath,$2),,,),$(COPY) /y/b $(call ospath,$1 $2)$(suppress_copy_output))

# move file(s) (long list) preserving modification date:
# - file(s) $1 to directory $2 (paths to files $1 _must_ not contain spaces, but path to directory $2 may contain spaces) or
# - file $1 to file $2         (path to file $1 _must_ not contain spaces, but path to file $2 may contain spaces)
# note: $6 - empty on first call, $(newline) on next calls
# note: if path to the directory/file $2 contains a space, it must be in double-quotes: "1 2\3 4"
move_files1 = $(if $6,$(quiet))for %%f in ($1) do $(MOVE) /y %%f $2$(suppress_move_output)
move_files  = $(if $(word 2,$1),$(call xcmd,move_files1,$(ospath),$(CBLD_MAX_PATH_ARGS),$(call \
  ospath,$2),,,),$(MOVE) /y $(call ospath,$1 $2)$(suppress_move_output))

# update modification date of given file(s) or create file(s) if they do not exist
# note: to support long list, the paths _must_ not contain spaces
# note: $6 - empty on first call, $(newline) on next calls
touch_files1 = $(if $6,$(quiet))for %%f in ($1) do if exist %%f ($(COPY) /y/b %%f+,, %%f$(suppress_copy_output)) else rem. > %%f
touch_files  = $(call xcmd,touch_files1,$(ospath),$(CBLD_MAX_PATH_ARGS),,,,)

# create a directory
#
# NOTE! there are races in mkdir - if make spawns two parallel jobs:
#
# if not exist aaa
#                        if not exist aaa/bbb
#                        mkdir aaa/bbb
# mkdir aaa - fail
#
# note: to avoid races, 'create_dir' must be called only if it's known that destination directory does not exist
# note: 'create_dir' must create intermediate parent directories of the destination directory
# note: if path to the directory $1 contains a space, it must be in double-quotes: "1 2\3 4"
create_dir = $(MKDIR) $(ospath)

# compare content of two text files: $1 and $2
# return an error code if they are differ
# note: if path to a file contains a space, it must be in double-quotes: "1 2\3 4"
compare_files = $(FC) /t $(call ospath,$1 $2)

# escape program argument to pass it via shell: 1 " 2 -> "1 "" 2"
shell_escape = "$(subst ","",$(subst \",\\",$(subst %,%%,$1)))"

# escape special characters in unquoted argument of 'echo' or 'set' command
unquoted_escape = $(subst $(open_brace),^$(open_brace),$(subst $(close_brace),^$(close_brace),$(subst \
  %,%%,$(subst <,^<,$(subst >,^>,$(subst |,^|,$(subst &,^&,$(subst ",^",$(subst ^,^^,$1)))))))))

# escape command line argument to pass it to $(SED)
# note: assume GNU sed is used, which understands \n and \t escape sequences
sed_expr = $(shell_escape)

# print content of a given file (to stdout, for redirecting it to output file)
# note: if path to the file $1 contains a space, it must be in double-quotes: "1 2\3 4"
cat_file = $(TYPE) $(ospath)

# print one line of text (to stdout, for redirecting it to output file)
# note: line must not contain $(newline)s
# note: line will be ended with CRLF
# NOTE: printed line length must not exceed the maximum command line length (8191 characters)
print_line = $(ECHO).$(unquoted_escape)

# print lines of text to output file or to stdout (for redirecting it to output file)
# $1 - non-empty lines list, where entries are processed by $(unescape)
# $2 - if not empty, then a file to print to (path to the file may contain spaces)
# $3 - text to prepend before the command when $6 is non-empty
# $4 - text to prepend before the command when $6 is empty
# $6 - empty if overwrite file $2, non-empty if append text to it
# note: if path to the file $2 contains a space, it must be in double-quotes: "1 2\3 4"
# NOTE: total text length must not exceed the maximum command line length (8191 characters)
print_lines = $(if $6,$3,$4)$(call tospaces,($(ECHO).$(subst \
  $(space),$(close_brace)&&$(open_brace)$(ECHO).,$(unquoted_escape))))$(if $2,>$(if $6,>) $2)

# print lines of text (to stdout, for redirecting it to output file)
# note: each line will be ended with CRLF
# NOTE: total text length must not exceed the maximum command line length (8191 characters)
print_text = $(if $(findstring $(newline),$1),$(call print_lines,$(subst $(newline),$$(empty) $$(empty),$(unspaces))),$(print_line))

# write lines of text $1 to the file $2 by $3 lines at one time
# note: if path to the file $2 contains a space, it must be in double-quotes: "1 2\3 4"
# NOTE: any line must be less than the maximum command length (8191 characters)
# NOTE: number $3 must be adjusted so printed at one time text length will not exceed the maximum command length (8191 characters)
write_text = $(call xargs,print_lines,$(subst $(newline),$$(empty) $$(empty),$(unspaces)),$3,$2,$(quiet),,,$(newline))

# create symbolic link $2 -> $1
# note: UNIX-specific, so not defined for WINDOWS
create_simlink:=

# set mode $1 of given file(s) $2 (short list, no more than CBLD_MAX_PATH_ARGS)
# note: UNIX-specific, so not defined for WINDOWS
change_mode:=

# execute command $2 in the directory $1
execute_in = pushd $(ospath) && ($2 && popd || (popd & cmd /c exit 1))

# delete target file(s) (short list, no more than CBLD_MAX_PATH_ARGS) if failed to build them and exit shell with error code 1
del_on_fail = || (($(delete_files)) & cmd /c exit 1)

# create a directory (with intermediate parent directories) while installing things
# $1 - path to the directory to create, path may contain spaces
# note: if path to the directory $1 contains a space, it must be in double-quotes: "1 2\3 4"
# note: directory $1 must not exist, 'install_dir' may be implemented via 'create_dir' (e.g. under WINDOWS)
install_dir = $(create_dir)

# install file(s) (long list) to directory or copy file to file
# $1 - file(s) to install (to support long list, paths _must_ not contain spaces)
# $2 - destination directory or file, path may contain spaces
# $3 - optional access mode, such as 644 (rw--r--r-) or 755 (rwxr-xr-x)
# note: if path to the directory/file $2 contains a space, it must be in double-quotes: "1 2\3 4"
install_files = $(copy_files)

# suffix of built tool executables
# note: override 'tool_suffix' macro from $(cb_dir)/core/_defs.mk
tool_suffix := .exe

# paths separator, as used in %PATH% environment variable
# note: override 'pathsep' macro from $(cb_dir)/core/runtool.mk
pathsep := ;

# name of environment variable to modify in $(RUN_TOOL)
# note: override 'dll_path_var' macro from $(cb_dir)/core/runtool.mk
dll_path_var := PATH

# if PATH environment variable was modified for calling a tool, print new PATH value for the generated batch
# $1 - tool to execute (with parameters - escaped by 'shell_escape' macro)
# $2 - additional path(s) separated by $(pathsep) to append to $(dll_path_var)
# $3 - directory to change to for executing a tool
# $4 - names of variables to set in the environment (export) to run given tool
# note: override 'show_tool_vars' macro from $(cb_dir)/core/runtool.mk
show_tool_vars = $(info setlocal$(foreach =,$(if $2,PATH) $4,$(newline)set $==$(call \
  unquoted_escape,$($=)))$(newline)$(if $3,$(call execute_in,$3,$1),$1))

# show after executing a command
# note: override 'show_tool_vars_end' macro from $(cb_dir)/core/runtool.mk
show_tool_vars_end = $(newline)@$(ECHO) endlocal

# windows terminal do not supports ANSI color escape sequences
# note: override 'cb_print_percents' macro from $(cb_dir)/core/suppress.mk
ifeq (,$(filter ansi-colors,$(.FEATURES)))
cb_print_percents = [$1]
endif

# windows terminal do not supports ANSI color escape sequences
# note: override 'cb_colorize' macro from $(cb_dir)/core/suppress.mk
ifeq (,$(filter ansi-colors,$(.FEATURES)))
cb_colorize = $1$(padto)$2
endif

# filter command's output through pipe, then send it to stderr
# $1 - command
# $2 - filtering expression to filter stdout, must be non-empty, for example: |$(FINDSTR) /BC:ABC |$(FINDSTR) /BC:CDE
filter_output = (($1 2>&1 && $(ECHO) ok>&2)$2)3>&2 2>&1 1>&3|$(FINDSTR) /BC:ok>$(NUL)

# remember value of variables that may be taken from the environment
$(call config_remember_vars,SHELL CBLD_DONT_STRIP_PATH CBLD_MAX_PATH_ARGS NUL DEL RD CD FIND FINDSTR COPY MOVE MKDIR FC SED TYPE ECHO)

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,SHELL CBLD_DONT_STRIP_PATH CBLD_MAX_PATH_ARGS NUL DEL RD CD FIND FINDSTR COPY MOVE MKDIR FC SED TYPE ECHO \
  create_simlink change_mode)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: utils
$(call set_global,print_env=project_exported_vars delete_files delete_dirs try_delete_dirs delete_files_in1 delete_files_in \
  del_files_or_dirs1 del_files_or_dirs filter_copy_output suppress_copy_output suppress_move_output copy_files1 copy_files \
  move_files1 move_files touch_files1 touch_files create_dir compare_files shell_escape unquoted_escape sed_expr cat_file \
  print_line print_lines print_text write_text execute_in del_on_fail install_dir install_files filter_output,utils)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: core
# note: overridden above 'ospath', 'nonrelpath' and 'tool_suffix' are protected in $(cb_dir)/core/_defs.mk
$(call set_global,nonrelpath1,core)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: runtool
# note: overridde macros defined in $(cb_dir)/code/runtool.mk
$(call set_global,pathsep dll_path_var show_tool_vars show_tool_vars_end,runtool)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: suppress
# note: overridde macros defined in $(cb_dir)/code/suppress.mk
$(call set_global,cb_print_percents cb_colorize,suppress)
