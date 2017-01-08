#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#----------------------------------------------------------------------------------

ifndef DEF_HEAD_CODE_EVAL
include $(MTOP)/_defs.mk
endif

# make $(TOP)-related paths to makefiles $1 with suffix $2:
# add $(VPREFIX) if makefile path is not absolute, add /Makefile if makefile path is a directory
NORM_MAKEFILES = $(patsubst $(TOP)/%,%$2,$(abspath $(foreach \
  x,$1,$(if $(call isrelpath,$x),$(VPREFIX))$x$(if $(filter-out %.mk %/Makefile Makefile,$x),/Makefile))))

# overwrite code for adding $(MDEPS) - list of makefiles that need to be built before target makefile - to $(ORDER_DEPS)
FIX_ORDER_DEPS := ORDER_DEPS := $$(strip $$(ORDER_DEPS) $$(call NORM_MAKEFILES,$$(MDEPS),-))$(newline)MDEPS:=

# don't complain about changed FIX_ORDER_DEPS value - replace old FIX_ORDER_DEPS value with a new one
$(call CLEAN_BUILD_PROTECT_VARS,FIX_ORDER_DEPS)

# $m - next $(TOP)-related makefile to include
# NOTE: $(ORDER_DEPS) value may be changed in included makefile, so restore ORDER_DEPS before including next makefile
# NOTE: $(TOOL_MODE) value may be changed (set) in included makefile, so restore TOOL_MODE before including next makefile
define CB_INCLUDE_TEMPLATE
$(empty)
VPREFIX := $(call GET_VPREFIX,$m)
CURRENT_MAKEFILE := $m
ORDER_DEPS := $(ORDER_DEPS)
TOOL_MODE := $(TOOL_MODE)
include $(TOP)/$m
endef

# note: $(TO_MAKE) - list of $(TOP)-related makefiles to include
ifdef REM_SHOWN_MAKEFILE
define CB_INCLUDE
INTERMEDIATE_MAKEFILES += 1
$(foreach m,$(TO_MAKE),$(CB_INCLUDE_TEMPLATE))
endef
else # !REM_SHOWN_MAKEFILE
define CB_INCLUDE
$(foreach m,$(TO_MAKE),$(CB_INCLUDE_TEMPLATE))
endef
endif # !REM_SHOWN_MAKEFILE

# used to remember makefiles include level
CB_INCLUDE_LEVEL:=

# used to remember number of intermediate makefiles which include other makefiles
INTERMEDIATE_MAKEFILES:=

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,NORM_MAKEFILES CB_INCLUDE_TEMPLATE CB_INCLUDE)
