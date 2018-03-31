#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# CBLD_NO_DEPS - if defined, then do not generate, process or cleanup previously generated auto-dependencies
# note: by default, do not generate auto-dependencies for release builds
# note: 'debug' - defined in $(cb_dir)/core/_defs.mk
ifeq (undefined,$(origin CBLD_NO_DEPS))
CBLD_NO_DEPS := $(if $(debug),,1)
endif

# remember values of variables possibly taken from the environment
$(call config_remember_vars,CBLD_NO_DEPS)

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,CBLD_NO_DEPS)
