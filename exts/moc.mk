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

ifndef MOC_SRC_PATTERN
# $1 - moc headers
# $2 - build target name, may be empty
# $3 - EXE_,LIB_,DLL_,... may be empty
define MOC_SRC_PATTERN
MOC_SRC_DIR := $(BLDSRC_DIR)/MOC_$(MOC_DIR_NAME)$(addprefix _,$3$2)
$3MOC_SRC := $$(addprefix $$(MOC_SRC_DIR)/,$(patsubst %.h,%_moc.cpp,$(notdir $1)))
NEEDED_DIRS += $$(MOC_SRC_DIR)
$(foreach x,$1,$(newline)$$(MOC_SRC_DIR)/$(patsubst %.h,%_moc.cpp,$(notdir $x)): $x | $$(MOC_SRC_DIR)
	$$(call SUPRESS,MOC,$$@)$(MOC) -i -f$$(call ospath,$$(call abspath,$$<)) \
  $$(call ospath,$$(call abspath,$$<)) -o $$(call ospath,$$@))
CLEAN += $$($3MOC_SRC)
endef

# $t - EXE,LIB,DLL,...
# NOTE: add moc-generated sources as target dependencies to avoid auto-deleting them as intermediate files
define BLD_MOC_FILES_PATTERN1
ifneq ($($t_MOC_HEADERS),)
$(call MOC_SRC_PATTERN,$(call FIXPATH,$($t_MOC_HEADERS)),$(call GET_TARGET_NAME,$t),$t_)
$t_MOC_SRC+=$(MOC_SRC)
else
$t_MOC_SRC:=$(MOC_SRC)
endif
ifneq ($$($t_MOC_SRC),)
$t_SRC += $$($t_MOC_SRC)
$(foreach v,$(call GET_VARIANTS,$t,VARIANTS_FILTER),$(newline)$(call FORM_TRG,$t,$v): $$($t_MOC_SRC))
endif
endef
BLD_MOC_FILES_PATTERN = $(if $($t),$(newline)$(BLD_MOC_FILES_PATTERN1))

# $t - EXE,LIB,DLL,...
define MOC_DEP_PATTERN1
$(call $(if $($t_MOC_DEPS),$($t_MOC_DEPS),$(MOC_DEPS)),$t,$($t_MOC_SRC))
$t_MOC_DEPS:=
endef
MOC_DEP_PATTERN = $(if $($t),$(if $(MOC_DEPS)$($t_MOC_DEPS),$(MOC_DEP_PATTERN1)$(newline)))

RESET_MOC_HEADERS := MOC_HEADERS:=$(newline)$(foreach t,$(BLD_TARGETS),$t_MOC_HEADERS:=$(newline))
endif # MOC_SRC_PATTERN

$(eval $(call MOC_SRC_PATTERN,$(call FIXPATH,$(MOC_HEADERS)),,))
$(eval $(foreach t,$(BLD_TARGETS),$(BLD_MOC_FILES_PATTERN)))

# add dependencies for generated sources, for example pch-header
$(eval $(foreach t,$(BLD_TARGETS),$(MOC_DEP_PATTERN)))
MOC_DEPS:=

# reset MOC_HEADERS for next included makefiles
$(eval $(RESET_MOC_HEADERS))

MOC_DIR_NAME:=
