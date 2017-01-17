#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPLv2+, see COPYING
#----------------------------------------------------------------------------------

# this file included by $(MTOP)/LINUX/c.mk

# define standard pkg-config values
PC_PREFIX      ?= $(firstword $(INST_PATH) $(patsubst %/,%,$(dir $(INST_RPATH))) /usr/local)
PC_EXEC_PREFIX ?= $${prefix}
PC_LIBDIR      ?= $(if $(INST_RPATH),$(if $(filter $${prefix} $(PC_PREFIX),$(PC_EXEC_PREFIX)),$(patsubst $(PC_PREFIX)/%,$${exec_prefix}/%,$(INST_RPATH)),$(patsubst $(PC_EXEC_PREFIX)/%,$${exec_prefix}/%,$(INST_RPATH))),$${exec_prefix}/lib)


INST_RPATH_DIR := $(patsubst %/,%,$(dir $(INST_RPATH)))
PC_PREFIX      ?= $(firstword $(INST_PATH) $(INST_RPATH_DIR) /usr/local)
PC_EXEC_PREFIX ?= $(firstword $(INST_RPATH_DIR) $${prefix})
PC_LIBDIR      ?= $(if $(INST_RPATH_DIR),$(if $(filter $${prefix} $(PC_PREFIX),$(PC_EXEC_PREFIX)),$(patsubst $(PC_PREFIX)/%,$${exec_prefix}/%,$(INST_RPATH)),$(patsubst $(PC_EXEC_PREFIX)/%,$${exec_prefix}/%,$(INST_RPATH))),$${exec_prefix}/lib)


$(info PC_PREFIX=$(PC_PREFIX))
$(info PC_EXEC_PREFIX=$(PC_EXEC_PREFIX))
$(info PC_LIBDIR=$(PC_LIBDIR))



$(firstword $(INST_RPATH) $${exec_prefix}/lib)



# note: some of WIN_RC_... variables may be already defined in $(TOP)/make/project.mk
WIN_RC_PRODUCT_VERSION_MAJOR ?= PRODUCT_VERSION_MAJOR
WIN_RC_PRODUCT_VERSION_MINOR ?= PRODUCT_VERSION_MINOR
WIN_RC_PRODUCT_BUILD_NUM     ?= PRODUCT_BUILD_NUM
WIN_RC_COMMENTS              ?= PRODUCT_TARGET "/" PRODUCT_OS "/" $(if $(filter DRV,$1),PRODUCT_KCPU,PRODUCT_UCPU) "/" PRODUCT_BUILD_DATE
WIN_RC_COMPANY_NAME          ?= VENDOR_NAME
WIN_RC_FILE_DESCRIPTION      ?= "$(GET_TARGET_NAME)"
WIN_RC_FILE_VERSION          ?= PRODUCT_BUILD_VERSION
WIN_RC_INTERNAL_NAME         ?= "$(GET_TARGET_NAME)"
WIN_RC_LEGAL_COPYRIGHT       ?= VENDOR_COPYRIGHT
WIN_RC_LEGAL_TRADEMARKS      ?=
WIN_RC_PRIVATE_BUILD         ?=
WIN_RC_PRODUCT_NAME          ?= PRODUCT_NAME
WIN_RC_PRODUCT_VERSION       ?= PRODUCT_VERSION
WIN_RC_LANG                  ?= 0409
WIN_RC_CHARSET               ?= 04b0

# $1    - library comment (author, description, etc.)
# $2    - ${prefix}
# $3    - ${exec_prefix}
# $4    - ${libdir}
# $5    - ${includedir}
# $6    - Name              $(DLL)
# $7    - Description
# $8    - URL
# $9    - Version            $(SOVER)
# $(10) - Requires
# $(11) - Requires.private
# $(12) - Conflicts
# $(13) - CFLAGS
# $(14) - dependent libraries
# $(15) - private libs
# note: PKGCONFIG_TEXT_TEMPLATE may be already defined in $(TOP)/make/project.mk
ifndef PKGCONFIG_TEXT_TEMPLATE
define PKGCONFIG_TEXT_TEMPLATE
# $(subst $(newline),$(newline)# ,$1)

prefix=$(firstword $2 /usr/local)
exec_prefix=$(firstword $3 $${prefix})
libdir=$(firstword $4 $${exec_prefix}/lib)
includedir=$(firstword $5 $${prefix}/include)

Name: $6$(if \
$7,$(newline)Description: $7)$(if \
$8,$(newline)URL: $8)$(if \
$9,$(newline)Version: $9)$(if \
$(10),$(newline)Requires: $(10))$(if \
$(11),$(newline)Requires.private: $(11))$(if \
$(12),$(newline)Conflicts: $(12))
Cflags: $(if $(13),$(13),-I$${includedir})
Libs: $(if $(14),$(14),-L$${libdir} -l$6)$(if \
$(15),Libs.private: $(15))
endef # PKGCONFIG_TEXT_TEMPLATE

# rule to generate pkg-config file for dynamic or static library
# $1 - DLL or LIB
define PKGCONFIG_TEMPLATE
ifndef CB_TOOL_MODE
ifndef DONT_GEN_PC
TRG_PC := $(LIB_DIR)/lib$(DLL).pc
$$(TRG_PC): | $(LIB_DIR)
	$$(call SUP,GEN,$$@)$$(call ECHO,$$(call PKGCONFIG_TEXT_TEMPLATE,$(DLL),$(strip \
$(PC_PREFIX)),$(strip \
$(PC_EXEC_PREFIX)),$(strip \
$(PC_INCLUDEDIR)),$(strip \
$(PC_LIBDIR)),$(strip \
$(PC_CFLAGS)),$(strip \
$(PC_LIBS))) > $$@
$$(call STD_TARGET_VARS,$$(TRG_PC))
endif
endif
endef

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS, \
  RC_OS RC_FT RC_FST \
  WIN_RC_PRODUCT_DEFS_HEADER \
  WIN_RC_PRODUCT_VERSION_MAJOR WIN_RC_PRODUCT_VERSION_MINOR WIN_RC_PRODUCT_BUILD_NUM \
  WIN_RC_COMMENTS WIN_RC_COMPANY_NAME WIN_RC_FILE_DESCRIPTION WIN_RC_FILE_VERSION WIN_RC_INTERNAL_NAME \
  WIN_RC_LEGAL_COPYRIGHT WIN_RC_LEGAL_TRADEMARKS WIN_RC_PRIVATE_BUILD \
  WIN_RC_PRODUCT_NAME WIN_RC_PRODUCT_VERSION WIN_RC_SPECIAL_BUILD WIN_RC_LANG WIN_RC_CHARSET \
  STD_VERSION_RC_TEMPLATE STD_RES_TEMPLATE1 ADD_RES_TEMPLATE STD_RES_TEMPLATE)
