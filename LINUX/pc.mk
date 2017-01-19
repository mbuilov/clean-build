#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPLv2+, see COPYING
#----------------------------------------------------------------------------------

# pkg-config file generation

# example:

define PC_EXAMPLE
#
# Author: John Smith
#
# This file has been put into the public domain.
# You can do whatever you want with this file.
#

prefix=/usr/local
exec_prefix=/usr/local
libdir=/usr/local/lib
includedir=/usr/local/include

Name: libmylib
Description: General purpose library
URL: http://aa.bb.cc.dd.ee.com
Version: 1.2.3
Cflags: -I${includedir}
Libs: -L${libdir} -lmylib
Libs.private: -pthread
endef

# $1    - library comment (author, description, etc.)
# $2    - ${prefix}
# $3    - ${exec_prefix}
# $4    - ${libdir}
# $5    - ${includedir}
# $6    - Name
# $7    - Description
# $8    - URL
# $9    - Version
# $(10) - Requires
# $(11) - Requires.private
# $(12) - Conflicts
# $(13) - CFLAGS
# $(14) - dependent libraries
# $(15) - private libs
# note: PKGCONFIG_TEMPLATE may be already defined in $(TOP)/make/project.mk
ifndef PKGCONFIG_TEMPLATE
define PKGCONFIG_TEMPLATE
$(if $1,# $(subst $(newline),$(newline)# ,$1)$(newline))
prefix=$2
exec_prefix=$3
libdir=$4
includedir=$5

Name: $6$(if \
$7,$(newline)Description: $7)$(if \
$8,$(newline)URL: $8)$(if \
$9,$(newline)Version: $9)$(if \
$(10),$(newline)Requires: $(10))$(if \
$(11),$(newline)Requires.private: $(11))$(if \
$(12),$(newline)Conflicts: $(12))$(if \
$(13),$(newline)Cflags: $(13))$(if \
$(14),$(newline)Libs: $(14),$(14))$(if \
$(15),$(newline)Libs.private: $(15))
endef # PKGCONFIG_TEMPLATE
endif

# generate pkg-config file for dynamic or static library
# arguments - the same as for $(PKGCONFIG_TEMPLATE)
define PKGCONFIG_GEN_RULE1
$1: TEMPLATE := $(subst $(comment),$$$$(comment),$(subst $(newline),$$$$(newline),$(subst $$,$$$$,$2)))
$1: | $(LIB_DIR)
	$$(call SUP,GEN,$$@)$$(call ECHO,$$(subst $$$$(comment),$$(comment),$$(subst $$$$(newline),$$(newline),$$(TEMPLATE)))) > $$@
$(call STD_TARGET_VARS,$1)
endef
PKGCONFIG_GEN_RULE = $(eval $(call PKGCONFIG_GEN_RULE1,$(LIB_DIR)/lib$6.pc,$(PKGCONFIG_TEMPLATE)))

# define standard pkg-config values
# note: some of PC_... variables may be already defined in $(TOP)/make/project.mk
INST_RPATH_DIR := $(patsubst %/,%,$(dir $(INST_RPATH)))
PC_PREFIX      ?= $(firstword $(INST_PATH) $(INST_RPATH_DIR) /usr/local)
PC_EXEC_PREFIX ?= $(if $(filter $(INST_RPATH_DIR),$(PC_PREFIX)),$${prefix},$(firstword $(INST_RPATH_DIR) $${prefix}))
PC_LIBDIR      ?= $(if $(filter $(INST_RPATH_DIR),$(PC_EXEC_PREFIX)$(if \
  $(filter $${prefix},$(PC_EXEC_PREFIX)), $(PC_PREFIX))),$${exec_prefix}/$(notdir \
  $(INST_RPATH)),$(firstword $(INST_RPATH) $${exec_prefix}/lib))
PC_INCLUDEDIR  ?= $${prefix}/include
PC_CFLAGS      ?= -I$${includedir}
PC_LIBS        ?= -L$${libdir}

# rule for generation of .pc-file using $(PC_...) predefined values
# $1    - library name
# $2    - library description
# $3    - library version (for a DLL: $(SOVER))
# $4    - library comment (author, description, etc.)
# $5    - project url     (likely $(VENDOR_URL))
# $6    - Requires section
# $7    - Requires.private section
# $8    - Conflicts section
# $9    - additional CFLAGS
# $(10) - Libs section
# $(11) - Libs.private section
PKGCONFIG_RULE = $(call PKGCONFIG_GEN_RULE,$4,$(PC_PREFIX),$(PC_EXEC_PREFIX),$(strip \
$(PC_LIBDIR)),$(PC_INCLUDEDIR),$1,$2,$5,$3,$6,$7,$8,$(PC_CFLAGS) -l$1$(if $9, $9),$(10),$(11))

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS, \
  PKGCONFIG_TEMPLATE PKGCONFIG_GEN_RULE1 PKGCONFIG_GEN_RULE INST_RPATH_DIR \
  PC_PREFIX PC_EXEC_PREFIX PC_LIBDIR PC_INCLUDEDIR PC_CFLAGS PC_LIBS PKGCONFIG_RULE)
