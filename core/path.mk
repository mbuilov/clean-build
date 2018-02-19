#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define 'fixpath' and 'ospath' functions

# this file is included by $(cb_dir)/core/_defs.mk

# helper macro for 'fixpath'
# make path not relative: add prefix $1 only to non-absolute paths in $2
# note: path prefix $1 must end with /
ifneq (,$(filter /%,$(CURDIR)))
nonrelp = $(patsubst $1/%,/%,$(addprefix $1,$2))
else # win-make

# $1 - prefix
# $2 - list of disks (C: D:)
# $3 - list of files prefixed with $1
nonrelp1 = $(if $2,$(call nonrelp1,$1,$(wordlist 2,999999,$2),$(patsubst $1$(firstword $2)%,$(firstword $2)%,$3)),$3)

# note: path prefix $1 must end with /
# a/b c:/1 -> xxx/a/b xxx/c:/1 -> xxx/a/b c:/1
nonrelp = $(if $(findstring :,$2),$(call nonrelp1,$1,$(sort $(filter %:,$(subst :,: ,$2))),$(addprefix $1,$2)),$(addprefix $1,$2))

endif # win-make

# ***********************************************
# prepend absolute path to directory of target makefile to given non-absolute paths
# - we need absolute paths to sources to work with generated dependencies in .d files
# note: assume there are no spaces in paths (or spaces are 'hidden', e.g. by 'path_unspaces')
# note: 'fixpath' works with Gnu Make paths (/cygdrive/c/file, /c/file or c:/file), not native paths (c:\file), to convert
#  Gnu Make paths to native ones - use 'ospath' macro
fixpath = $(abspath $(call nonrelp,$(dir $(cb_target_makefile)),$1))

# non-empty if MSys version of Gnu Make is used
CBLD_IS_MSYS_MAKE ?= $(filter MINGW%,$(CBLD_OS))

# ***********************************************
# 'ospath' - convert paths from Gnu Make representation to the form accepted by the native build tools, then shell-escape them
#  so they may be passed via the command line
# note: assume there are no spaces in paths (or spaces are 'hidden', e.g. by 'path_unspaces')
# note: assume there are no weird characters in the paths - 'shell_escape' macro from $(utils_mk) should be used
# note: use 'ospath' to pass paths to native tools, it's not required to use 'ospath' when redirecting output in rules, e.g.:
#  "$(command) > $(call ospath,$@)" vs "$(command) > $@"
ifneq (,$(filter /cygdrive/%,$(CURDIR)))

# cyg-make: /cygdrive/c/1/2/3 -> c:\\1\\2\\3
# 'cygdrive' - used for optimization of 'ospath': assume most absolute paths are on $(cygdrive) disk
cygdrive := $(word 2,$(subst /, ,$(CURDIR)))
ospath2 = $(word 2,$1):$(subst $(space),\\,$(wordlist 3,999999,$1))
ospath1 = $(if $(findstring /cygdrive/,$1),$(foreach p,$1,$(if $(filter /cygdrive/%,$p),$(call ospath2,$(subst /, ,$p)),$p)),$1)
ospath = $(subst /,\\,$(if $(findstring /cygdrive/,$1),$(call ospath1,$(patsubst /cygdrive/$(cygdrive)%,$(cygdrive):%,$1)),$1))

else ifneq (,$(filter /%,$(CURDIR)))
ifeq (,$(CBLD_IS_MSYS_MAKE))

# unix-make: /1/2/3 -> /1/2/3
ospath = $1

else # msys

# msys-make: /c/1/2/3 -> c:\\1\\2\\3
# 'msysdrive' - used for optimization of 'ospath': assume most absolute paths are on $(msysdrive) disk
msysdrive := $(firstword $(subst /, ,$(CURDIR)))
ospath2 = $(firstword $1):$(subst $(space),\\,$(wordlist 2,999999,$1))
ospath1 = $(if $(filter /%,$1),$(foreach p,$1,$(if $(filter /%,$p),$(call ospath2,$(subst /, ,$p)),$p)),$1)
ospath = $(subst /,\\,$(if $(filter /%,$1),$(call ospath1,$(patsubst /$(msysdrive)%,$(msysdrive):%,$1)),$1))

endif # msys
else

# win-make: c:/1/2/3 -> c:\1\2\3
ospath = $(subst /,\,$1)

endif

# ***********************************************
# add (double-)quotes if Gnu Make or native path has an embedded spaces:
# $(call ifaddq,a b) -> 'a b'
# $(call ifaddq,ab)  -> ab
# note: quoting type depends on the shell used by Gnu Make, assume Windows version of Gnu Make uses cmd.exe, Unix version - sh
# note: when redirecting output in rules, use 'ifaddq' if output file contains spaces, e.g.:
#  "$(command) > $(call ifaddq,$@)"
ifneq (,$(filter /%,$(CURDIR)))
ifaddq = $(if $(findstring $(space),$1),'$1',$1)
else # win-make
ifaddq = $(if $(findstring $(space),$1),"$1",$1)
endif # win-make

# ***********************************************
# replace spaces in a path by ?
path_unspaces = $(subst $(space),?,$1)

# ***********************************************
# unhide spaces in native paths (result of $(ospath)) adding some prefix:
# $(call qpath,a?b cd,-I) -> -I'a b' -Icd
# note: assume spaces are hidden via 'path_unspaces'
# note: quoting type depends on the shell used by Gnu Make, assume Windows version of Gnu Make uses cmd.exe, Unix version - sh
# note: use 'qpath' to pass paths to native tools:
#  $(call tool,$(call qpath,$(call ospath,$(paths)),-I))
ifneq (,$(filter /%,$(CURDIR)))
qpath = $(if $(findstring ?,$1),$(foreach p,$1,$2$(if $(findstring ?,$x),'$(subst ?, ,$x)',$x)),$(addprefix $2,$1))
else # win-make
qpath = $(if $(findstring ?,$1),$(foreach p,$1,$2$(if $(findstring ?,$x),"$(subst ?, ,$x)",$x)),$(addprefix $2,$1))
endif # win-make

# ***********************************************
# unhide spaces in Gnu Make paths:
# $(call gmake_path,/a?b /cd) -> /a\ b /cd
# note: assume spaces are hidden via 'path_unspaces'
# note: use 'gmake_path' when specifying rule targets which may contain hidden spaces:
#  $(call gmake_path,$(files)):; echo 1 > $(call ifaddq,$@)
gmake_path = $(subst ?,\ ,$1)

# remember value of CBLD_IS_MSYS_MAKE - it may be taken from the environment
$(call config_remember_vars,CBLD_IS_MSYS_MAKE)

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,CBLD_IS_MSYS_MAKE)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: path
$(call set_global,nonrelp nonrelp1 fixpath cygdrive ospath2 ospath1 ospath msysdrive ifaddq path_unspaces qpath gmake_path,path)
