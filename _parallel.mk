#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

ifndef DEF_HEAD_CODE_EVAL
include $(MTOP)/_defs.mk
endif

# make $(TOP)-related paths to makefiles $1 with suffix $2:
# add $(VPREFIX) if makefile path is not absolute, add /Makefile if makefile path is a directory
NORM_MAKEFILES = $(patsubst $(TOP)/%,%$2,$(abspath $(foreach \
  x,$1,$(if $(call isrelpath,$x),$(VPREFIX))$x$(if $(filter-out %.mk %/Makefile Makefile,$x),/Makefile))))

# add empty rules for $(MDEPS): don't complain if order deps are not resolved when build started in sub-directory
# note: $(ORDER_DEPS) - names of dependency makefiles with '-' suffix
APPEND_MDEPS ?= $(if $1,$1:$(newline)ORDER_DEPS += $1$(newline))

# overwrite code for adding $(MDEPS) - list of makefiles that need to be built before target makefile - to $(ORDER_DEPS)
# note: reset MDEPS to not update ORDER_DEPS on each evaluation of STD_TARGET_VARS in target makefile
FIX_ORDER_DEPS = $(call APPEND_MDEPS,$(filter-out $(ORDER_DEPS),$(call NORM_MAKEFILES,$(MDEPS),-)))MDEPS:=

# don't complain about new FIX_ORDER_DEPS value
# - replace old FIX_ORDER_DEPS value defined in $(MTOP)/defs.mk with a new one
$(call CLEAN_BUILD_PROTECT_VARS,FIX_ORDER_DEPS)

# $m - next $(TOP)-related makefile to include
# NOTE: $(ORDER_DEPS) value may be changed in included makefile, so restore ORDER_DEPS before including next makefile
# NOTE: $(TOOL_MODE) value may be changed (set) in included makefile, so restore TOOL_MODE before including next makefile
define CB_INCLUDE_TEMPLATE
$(empty)
VPREFIX:=$(call GET_VPREFIX,$m)
CURRENT_MAKEFILE:=$m
ORDER_DEPS:=$(ORDER_DEPS)
TOOL_MODE:=$(TOOL_MODE)
include $(TOP)/$m
endef

# note: $(TO_MAKE) - list of $(TOP)-related makefiles to include
ifdef REM_SHOWN_MAKEFILE
# non-verbose build
define CB_INCLUDE
INTERMEDIATE_MAKEFILES+=1
$(foreach m,$(TO_MAKE),$(CB_INCLUDE_TEMPLATE))
endef
else # !REM_SHOWN_MAKEFILE
# verbose build
define CB_INCLUDE
$(foreach m,$(TO_MAKE),$(CB_INCLUDE_TEMPLATE))
endef
endif # !REM_SHOWN_MAKEFILE

# used to remember makefiles include level
CB_INCLUDE_LEVEL:=

# used to remember number of intermediate makefiles which include other makefiles
INTERMEDIATE_MAKEFILES:=

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,NORM_MAKEFILES APPEND_MDEPS CB_INCLUDE_TEMPLATE CB_INCLUDE)
