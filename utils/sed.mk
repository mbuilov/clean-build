#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# stream editor, standard Unix utility, for Windows version of Gnu Sed - see https://github.com/mbuilov/sed-windows
SED ?= sed

# assume native sed is used, e.g. Windows version of Gnu Sed under Windows, except under Cygwin/Msys
CBLD_IS_NATIVE_SED ?= $(filter-out CYGWIN% MINGW%,$(CBLD_OS))

# convert path from Gnu Make representation to the form accepted by SED
ifneq (,$(CBLD_IS_NATIVE_SED:0=))
sed_path = $(ospath)
else
sed_path = $1
endif

# assume Gnu Sed is used under these OSes
CBLD_IS_GNU_SED ?= $(filter WIN% CYGWIN% MINGW% LINUX%,$(CBLD_OS))

# escape command line argument to pass it to $(SED)
# note: 'shell_escape' - defined in $(utils_mk), e.g. $(cb_dir)/utils/unix.mk
ifneq (,$(CBLD_IS_GNU_SED:0=))

# Gnu Sed understands \n and \t escape sequences
sed_expr = $(shell_escape)

else # !Gnu Sed

# standard unix sed do not understands \n and \t escape sequences
sed_expr = $(call shell_escape,$(subst \n,\$(newline),$(subst \t,\$(tab),$1)))

endif # !Gnu Sed

# helper macro: convert multi-line sed script $1 to multiple sed expressions - one expression for each line of the script
# note: hide_tab_spaces/unhide_comments - defined in $(cb_dir)/core/functions.mk
sed_multi_expr = $(foreach s,$(subst $(newline), ,$(hide_tab_spaces)),-e $(call sed_expr,$(call unhide_comments,$s)))

# utilities colors - for the 'suppress' function (and cb_colorize/cb_show_tool macros)
CBLD_SED_COLOR ?= [32m

# remember value of variables that may be taken from the environment
$(call config_remember_vars,SED CBLD_IS_NATIVE_SED CBLD_IS_GNU_SED)

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,SED CBLD_IS_NATIVE_SED CBLD_IS_GNU_SED CBLD_SED_COLOR)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: sed
$(call set_global,sed_path sed_expr sed_multi_expr,sed)
