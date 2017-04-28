#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# this file included by $(MTOP)/defs.mk
# check values of $(TOP) and $(BUILD) variables

# make TOP or BUILD non-recursive (simple), then check their values
# $1 (TOP or BUILD) must contain unix-style path to directory without spaces like C:/opt/project or /home/oper/project
define CHECK_TOP1
$1 := $($1)
ifneq ($(words x$($1)x),1)
$$(error $1=$($1), path with spaces is not allowed)
endif
ifneq ($(words $(subst \, ,x$($1)x)),1)
$$(error $1=$($1), path must use unix-style slashes: /)
endif
ifneq ($(subst //,,$($1)/),$($1)/)
$$(error $1=$($1), path must not end with slash: / or contain double-slash: //)
endif
endef
CHECK_TOP = $(eval $(CHECK_TOP1))

ifndef TOP
$(error TOP undefined, example: C:/opt/project,/home/oper/project)
endif

# make TOP non-recursive (simple)
$(call CHECK_TOP,TOP)

# directory for built files - base for $(BIN_DIR), $(LIB_DIR), $(OBJ_DIR), $(GEN_DIR)
# note: make BUILD non-recursive (simple)
ifndef BUILD
BUILD := $(TOP)/build
else
$(call CHECK_TOP,BUILD)
ifneq ($(filter $(BUILD)/%,$(TOP)/),)
$(error BUILD=$(BUILD) cannot be a base for TOP=$(TOP))
endif
endif

# protect variables from modification in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,CHECK_TOP1 CHECK_TOP TOP BUILD)
