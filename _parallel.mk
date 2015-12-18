ifndef DEF_HEAD_CODE_EVAL
include $(MTOP)/_defs.mk
endif

# make $(TOP)-related paths to makefiles $1 with suffix $2:
# add $(VPREFIX) if makefile path is not absolute, add /Makefile if makefile path is a directory
NORM_MAKEFILES = $(patsubst $(TOP)/%,%$2,$(abspath $(foreach \
  x,$1,$(if $(call isrelpath,$x),$(VPREFIX))$x$(if $(filter-out %.mk %/Makefile Makefile,$x),/Makefile))))

# overwrite code for adding $(MDEPS) - list of makefiles that need to be maked before target makefile - to $(ORDER_DEPS)
FIX_ORDER_DEPS := ORDER_DEPS := $$(strip $$(ORDER_DEPS) $$(call NORM_MAKEFILES,$$(MDEPS),-))$(newline)MDEPS:=

# don't complain about changed FIX_ORDER_DEPS value - replace old FIX_ORDER_DEPS value with a new one
$(call CLEAN_BUILD_PROTECT_VARS,FIX_ORDER_DEPS)

# $m - next $(TOP)-related makefile to include
# NOTE: $(ORDER_DEPS) value may be changed in included makefile, so restore ORDER_DEPS before including next makefile
# NOTE: $(TOOL_MODE) value may be changed in included makefile, so restore TOOL_MODE before including next makefile
define CB_INCLUDE_TEMPLATE
$(empty)
VPREFIX := $(call GET_VPREFIX,$m)
CURRENT_MAKEFILE := $m
ORDER_DEPS := $(ORDER_DEPS)
TOOL_MODE := $(TOOL_MODE)
include $(TOP)/$m
endef

# note: $(TO_MAKE) - list of $(TOP)-related makefiles to include
CB_INCLUDE = $(foreach m,$(TO_MAKE),$(CB_INCLUDE_TEMPLATE))

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,NORM_MAKEFILES CB_INCLUDE_TEMPLATE CB_INCLUDE)
