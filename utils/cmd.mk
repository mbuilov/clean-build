#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# system shell utilities

# this file included by $(CLEAN_BUILD_DIR)/core/_defs.mk

# synchronize make output for parallel builds
MAKEFLAGS += -O

ifneq (,$(filter /cygdrive/%,$(CURDIR)))
$(error Cygwin version of Gnu Make is used with cmd.exe shell - this configuration is not supported,\
 please use native windows tools.$(newline)Tip; under Cygwin build may be started as:\
 /cygdrive/c/tools/gnumake-4.2.1.exe SED=C:/tools/sed.exe <args>)
endif

# Windows programs need TMP, PATHEXT, SYSTEMROOT and COMSPEC variables to be defined in environment
# note: assume variable name cannot contain = character
WIN_EXPORTED := $(filter TMP=% PATHEXT=% SYSTEMROOT=% COMSPEC=%,$(join \
  $(addsuffix =,$(call toupper,$(.VARIABLES))),$(.VARIABLES)))

#      if SYSTEMROOT is defined, define SystemRoot = $(value SYSTEMROOT)
# else if SystemRoot is defined, define SYSTEMROOT = $(value SystemRoot)
$(foreach t,TMP PATHEXT SYSTEMROOT COMSPEC,\
  $(if $(filter %=$t,$(WIN_EXPORTED)),\
    $(foreach v,$(filter-out %=$t,$(filter $t=%,$(WIN_EXPORTED))),\
      $(eval override $(lastword $(subst =, ,$v))=$(value $t))\
    )\
  ,\
    $(foreach v,$(firstword $(filter $t=%,$(WIN_EXPORTED))),\
      $(eval $t=$(value $(lastword $(subst =, ,$v))))\
    )\
  )\
)

# export all SYSTEMROOT, SystemRoot, etc.
WIN_EXPORTED := $(sort $(subst =, ,$(WIN_EXPORTED)))
export $(WIN_EXPORTED)

# shell must be cmd.exe, not /bin/sh if build was started under Cygwin
ifneq (cmd.exe,$(notdir $(SHELL)))
ifneq (undefined,$(origin COMSPEC))
override SHELL := $(COMSPEC)
else ifneq (undefined,$(origin SYSTEMROOT))
override SHELL := $(SYSTEMROOT)\System32\cmd.exe
else
$(error unable to determine cmd.exe for the SHELL)
endif
endif

# save exported variables in generated config
# note: SHELL may be overridden just above, save it's new value also
ifdef CONFIG
ifneq (,$(filter conf,$(MAKECMDGOALS)))
conf: override CONFIG_TEXT += $(foreach v,SHELL $(WIN_EXPORTED),$(OVERRIDE_VAR_TEMPLATE))
endif
endif

# strip off Cygwin paths - to use only native windows tools
# for example, sed.exe from Cygwin handles quotes in format string differently than C:/GnuWin32/bin/sed.exe
# note: Cygwin paths may look like: C:\cygwin64\usr\local\bin;C:\cygwin64\bin
# note: assume paths separated with ; and there is no ; inside paths
CYGWIN_STRING := cygwin
override PATH := $(call tospaces,$(subst $(space),;,$(strip $(foreach p,$(subst \
  ;, ,$(call unspaces,$(PATH))),$(if $(findstring $(CYGWIN_STRING),$p),,$p)))))

# print prepared environment in verbose mode (used for generating one-big-build instructions batch file)
PRINT_ENV = $(info setlocal$(newline)FOR /F "delims==" %%V IN ('SET') DO $(foreach \
  x,PATH TMP PATHEXT SYSTEMROOT COMSPEC $(PASS_ENV_VARS),IF /I NOT "$x"=="%%V") SET "%%V="$(foreach \
  v,PATH $(filter TMP PATHEXT SYSTEMROOT COMSPEC,$(WIN_EXPORTED)) $(PASS_ENV_VARS),$(newline)SET "$v=$($v)"))

# command line length of cmd.exe is limited:
# for Windows 95   - 127 chars;
# for Windows 2000 - 2047 chars;
# for Windows XP   - 8191 chars (max 31 path arguments of 260 chars length each);
# define maximum number of path arguments that may be passed via command line,
# assuming we use Windows XP or later and paths do not exceed 120 chars:
PATH_ARGS_LIMIT := 68

# convert forward slashes used by make to backward ones accepted by windows programs
# note: override ospath from $(CLEAN_BUILD_DIR)/core/_defs.mk
ospath = $(subst /,\,$1)

# $1 - prefix
# $2 - list of disks (C: D:)
# $3 - list of files prefixed with $1
nonrelpath1 = $(if $2,$(call nonrelpath1,$1,$(wordlist 2,999999,$2),$(patsubst $1$(firstword $2)%,$(firstword $2)%,$3)),$3)

# make path not relative: add $1 only to non-absolute paths in $2
# note: path $1 must end with /
# a/b c:/1 -> xxx/a/b xxx/c:/1 -> xxx/a/b c:/1
# note: override nonrelpath from $(CLEAN_BUILD_DIR)/core/_defs.mk
nonrelpath = $(if $(findstring :,$2),$(call nonrelpath1,$1,$(sort $(filter %:,$(subst :,: ,$2))),$(addprefix $1,$2)),$(addprefix $1,$2))

# null device for redirecting output into
NUL := NUL

# delete file(s) $1 (short list, no more than PATH_ARGS_LIMIT), paths may contain spaces: "1 2\3 4" "5 6\7 8\9" ...
DELETE_FILES = for %%f in ($(ospath)) do if exist %%f del /F/Q %%f

# delete directories $1 (short list, no more than PATH_ARGS_LIMIT), paths may contain spaces: "1 2\3 4" "5 6\7 8\9" ...
DELETE_DIRS = for %%f in ($(ospath)) do if exist %%f rd /S/Q %%f

# in directory $1 (path may contain spaces), delete files $2 (long list), to support long list, paths _must_ be without spaces
# note: $6 - <empty> on first call, $(newline) on next calls
DELETE_FILES_IN1 = $(if $6,$(QUIET))cd $2 && for %%f in ($1) do if exist %%f (del /F/Q %%f)
DELETE_FILES_IN  = $(call xcmd,DELETE_FILES_IN1,$(call ospath,$2),$(PATH_ARGS_LIMIT),$(ospath),,,)

# delete files and/or directories (long list), to support long list, paths _must_ be without spaces
# note: $6 - <empty> on first call, $(newline) on next calls
DEL_FILES_OR_DIRS1 = $(if $6,$(QUIET))for %%f in ($1) do if exist %%f\* (rd /S/Q %%f) else if exist %%f (del /F/Q %%f)
DEL_FILES_OR_DIRS  = $(call xcmd,DEL_FILES_OR_DIRS1,$(ospath),$(PATH_ARGS_LIMIT),,,,)

# code for suppressing output of copy command, like
# "        1 file(s) copied."
# "Скопировано файлов:         1."
SUPPRESS_CP_OUTPUT := | findstr /VC:"        1" & if errorlevel 1 (cmd /c exit 0) else (cmd /c exit 1)

# copy file(s) (long list) preserving modification date:
# - file(s) $1 to directory $2 (paths to files $1 _must_ be without spaces, but path to directory $2 may contain spaces) or
# - file $1 to file $2         (path to file $1 _must_ be without spaces, but path to file $2 may contain spaces)
# note: $6 - <empty> on first call, $(newline) on next calls
COPY_FILES1 = $(if $6,$(QUIET))for %%f in ($1) do copy /Y /B %%f $2$(SUPPRESS_CP_OUTPUT)
COPY_FILES  = $(if $(word 2,$1),$(call xcmd,COPY_FILES1,$(ospath),$(PATH_ARGS_LIMIT),$(call \
  ospath,$2),,,),copy /Y /B $(call ospath,$1 $2)$(SUPPRESS_CP_OUTPUT))

# update modification date of given file(s) or create file(s) if they do not exist
# note: to support long list, paths _must_ be without spaces
# note: $6 - <empty> on first call, $(newline) on next calls
TOUCH_FILES1 = $(if $6,$(QUIET))for %%f in ($1) do if exist %%f (copy /Y /B %%f+,, %%f$(SUPPRESS_CP_OUTPUT)) else (rem. > %%f)
TOUCH_FILES  = $(call xcmd,TOUCH_FILES1,$(ospath),$(PATH_ARGS_LIMIT),,,,)

# create directory, path may contain spaces: "1 2\3 4"
#
# NOTE! there are races in mkdir - if make spawns two parallel jobs:
#
# if not exist aaa
#                        if not exist aaa/bbb
#                        mkdir aaa/bbb
# mkdir aaa - fail
#
# to avoid races, CREATE_DIR must be called only if it's known that destination directory does not exist
# note: CREATE_DIR must create intermediate parent directories of destination directory
CREATE_DIR = mkdir $(ospath)

# compare content of two text files: $1 and $2
# return an error code if they are differ
# note: paths to files may contain spaces
COMPARE_FILES = FC /T $(call ospath,$1 $2)

# escape program argument to pass it via shell: "1 ^ 2" -> "\"1 ^^ 2\""
SHELL_ESCAPE = "$(subst %,%%,$(subst <,^<,$(subst >,^>,$(subst |,^|,$(subst &,^&,$(subst ",\",$(subst ^,^^,$1)))))))"

# stream-editor executable
# note: SED value may be overridden either in command line or in project configuration makefile, like:
# SED := C:\tools\gnused.exe
SED := sed.exe

# escape command line argument to pass it to $(SED)
# note: assume GNU sed is used, which understands \n and \t escape sequences
SED_EXPR = $(SHELL_ESCAPE)

# print contents of given file (to stdout, for redirecting it to output file)
CAT_FILE = type $(ospath)

# prepare echo argument, like SHELL_ESCAPE, but escape " differently,
# also escape braces to be able to enclose call to echo with them, like: (echo.^))
ECHO_LINE_ESCAPE = $(subst $(open_brace),^$(open_brace),$(subst $(close_brace),^$(close_brace),$(subst \
  %,%%,$(subst <,^<,$(subst >,^>,$(subst |,^|,$(subst &,^&,$(subst ",^",$(subst ^,^^,$1)))))))))

# print one line of text (to stdout, for redirecting it to output file)
# note: line must not contain $(newline)s
# note: line will be ended with CRLF
# NOTE: echoed line length must not exceed maximum command line length (8191 characters)
ECHO_LINE = echo.$(ECHO_LINE_ESCAPE)

# print lines of text to output file or to stdout (for redirecting it to output file)
# $1 - non-empty lines list, where entries are processed by $(unescape)
# $2 - if not empty, then file to print to
# $3 - text to prepend before the command when $6 is non-empty
# $4 - text to prepend before the command when $6 is empty
# $6 - empty if overwrite file $2, non-empty if append text to it
# NOTE: total text length must not exceed maximum command line length (8191 characters)
ECHO_LINES = $(if $6,$3,$4)$(call tospaces,(echo.$(subst \
  $(space),$(close_brace)&&$(open_brace)echo.,$(ECHO_LINE_ESCAPE))))$(if $2,>$(if $6,>) $2)

# print lines of text (to stdout, for redirecting it to output file)
# note: each line will be ended with CRLF
# NOTE: total text length must not exceed maximum command line length (8191 characters)
ECHO_TEXT = $(if $(findstring $(newline),$1),$(call ECHO_LINES,$(subst $(newline),$$(empty) $$(empty),$(unspaces))),$(ECHO_LINE))

# write lines of text $1 to file $2 by $3 lines at one time
# NOTE: any line must be less than maximum command length (8191 characters)
# NOTE: number $3 must be adjusted so echoed at one time text length will not exceed maximum command length (8191 characters)
WRITE_TEXT = $(call xargs,ECHO_LINES,$(subst $(newline),$$(empty) $$(empty),$(unspaces)),$3,$2,$(QUIET),,,$(newline))

# execute command $2 in directory $1
EXECUTE_IN = pushd $(ospath) && ($2 && popd || (popd & cmd /c exit 1))

# delete target file(s) (short list, no more than PATH_ARGS_LIMIT) if failed to build them and exit shell with error code 1
DEL_ON_FAIL = || (($(DELETE_FILES)) & cmd /c exit 1)

# standard 'install' utility is not available under windows
INSTALL:=

# create directory (with intermediate parent directories) while installing things
# $1 - path to directory to create, path may contain spaces, such as: "C:/Program Files/AcmeCorp"
INSTALL_DIR = $(CREATE_DIR)

# install file(s) (long list) to directory or copy file to file
# $1 - file(s) to install (to support long list, paths _must_ be without spaces)
# $2 - destination directory or file, path may contain spaces
# $3 - optional access mode, such as 644 (rw--r--r-) or 755 (rwxr-xr-x)
INSTALL_FILES = $(COPY_FILES)

# suffix of built tool executables
# note: override TOOL_SUFFIX from $(CLEAN_BUILD_DIR)/defs.mk
TOOL_SUFFIX := .exe

# paths separator, as used in %PATH% environment variable
# note: override PATHSEP from $(CLEAN_BUILD_DIR)/defs.mk
PATHSEP := ;

# name of environment variable to modify in $(RUN_WITH_DLL_PATH)
# note: override DLL_PATH_VAR from $(CLEAN_BUILD_DIR)/defs.mk
DLL_PATH_VAR := PATH

# if %PATH% environment variable was modified for calling a tool, print new %PATH% value in generated batch
# $1 - command to run (with parameters)
# $2 - additional paths to append to $(DLL_PATH_VAR)
# $3 - environment variables to set to run executable, in form VAR=value
# note: override show_with_dll_path from $(CLEAN_BUILD_DIR)/defs.mk
show_with_dll_path = $(info setlocal$(if $2,$(newline)set "PATH=$(PATH)")$(foreach \
  v,$3,$(foreach n,$(firstword $(subst =, ,$v)),$(newline)set "$n=$($n)"))$(newline)$1)

# show after executing a command
# note: override show_dll_path_end from $(CLEAN_BUILD_DIR)/defs.mk
show_dll_path_end = $(newline)@echo endlocal

# there is no support for embedding dll search path into executables or dlls
NO_RPATH := 1

# windows terminal do not supports ANSI color escape sequences
# note: override PRINT_PERCENTS from $(CLEAN_BUILD_DIR)/defs.mk
ifeq (,$(filter ansi-colors,$(.FEATURES)))
PRINT_PERCENTS = [$1]
endif

# windows terminal do not supports ANSI color escape sequences
# note: override COLORIZE from $(CLEAN_BUILD_DIR)/defs.mk
ifeq (,$(filter ansi-colors,$(.FEATURES)))
COLORIZE = $1$(padto)$2
endif

# filter command's output through pipe, then send it to stderr
# $1 - command
# $2 - pipe expression for filtering stdout, must be non-empty, for example: |findstr /BC:ABC
FILTER_OUTPUT = (($1 2>&1 && echo OK>&2)$2)3>&2 2>&1 1>&3|findstr /BC:OK>NUL

# protect variables from modifications in target makefiles
# note: do not trace calls to this variables because they either exported or used in ifdefs
$(call SET_GLOBAL,$(sort TMP PATHEXT SYSTEMROOT COMSPEC $(WIN_EXPORTED)) PATH NO_RPATH,0)

# protect variables from modifications in target makefiles
# note: caller will protect variables: MAKEFLAGS SHELL PATH ospath nonrelpath1 nonrelpath
#  TOOL_SUFFIX PATHSEP DLL_PATH_VAR show_with_dll_path, show_dll_path_end, PRINT_PERCENTS, COLORIZE
$(call SET_GLOBAL,WIN_EXPORTED PRINT_ENV PATH_ARGS_LIMIT nonrelpath1 NUL DELETE_FILES DELETE_DIRS \
  DELETE_FILES_IN1 DELETE_FILES_IN DEL_FILES_OR_DIRS1 DEL_FILES_OR_DIRS SUPPRESS_CP_OUTPUT \
  COPY_FILES1 COPY_FILES TOUCH_FILES1 TOUCH_FILES CREATE_DIR COMPARE_FILES SHELL_ESCAPE SED SED_EXPR \
  CAT_FILE ECHO_LINE_ESCAPE ECHO_LINE ECHO_LINES ECHO_TEXT WRITE_TEXT EXECUTE_IN DEL_ON_FAIL \
  INSTALL INSTALL_DIR INSTALL_FILES FILTER_OUTPUT)
