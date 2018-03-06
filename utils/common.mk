#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# system shell utilities - common definitions
# included by:
#  $(cb_dir)/utils/cmd.mk
#  $(cb_dir)/utils/unix.mk

# utilities colors - for the 'suppress' function (and cb_colorize/cb_show_tool macros) from $(cb_dir)/core/suppress.mk
CBLD_CP_COLOR    ?= [1;36m
CBLD_RM_COLOR    ?= [1;31m
CBLD_RMDIR_COLOR ?= [1;31m
CBLD_MKDIR_COLOR ?= [36m
CBLD_TOUCH_COLOR ?= [36m
CBLD_CAT_COLOR   ?= [32m
CBLD_CMP_COLOR   ?= [32m

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,CBLD_CP_COLOR CBLD_RM_COLOR CBLD_RMDIR_COLOR CBLD_MKDIR_COLOR CBLD_TOUCH_COLOR CBLD_CAT_COLOR CBLD_CMP_COLOR)
