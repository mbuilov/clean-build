#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

ifndef PKGCONFIG_RULE

# pkg-config file generation

# $1   - Name
# $2   - Version
# $3   - Description
# $4   - library comment (author, description, etc.)
# $5   - URL
# $6   - Requires
# $7   - Requires.private
# $8   - Conflicts
# $9   - Cflags
# $10  - dependency libraries
# $11  - private dependency libs
# $12  - ${includedir}
# $13  - ${libdir}
# $14  - ${exec_prefix}
# $15  - ${prefix}
# note: PKGCONFIG_TEMPLATE may be already defined in $(TOP)/make/project.mk
ifndef PKGCONFIG_TEMPLATE
define PKGCONFIG_TEMPLATE
$(if $4,# $(subst $(newline),$(newline)# ,$4)$(newline))
prefix=$(15)
exec_prefix=$(14)
libdir=$(13)
includedir=$(12)

Name: $1$(if \
$3,$(newline)Description: $3)$(if \
$5,$(newline)URL: $5)$(if \
$2,$(newline)Version: $2)$(if \
$6,$(newline)Requires: $6)$(if \
$7,$(newline)Requires.private: $7)$(if \
$8,$(newline)Conflicts: $8)$(if \
$9,$(newline)Cflags: $9)$(if \
$(10),$(newline)Libs: $(10))$(if \
$(11),$(newline)Libs.private: $(11))
endef # PKGCONFIG_TEMPLATE
endif

# $1 - $(LIB_DIR)/lib$1.pc
# $2 - $(PKGCONFIG_TEMPLATE)
define PKGCONFIG_GEN_RULE1
$1: TEMPLATE := $(subst $(comment),$$$$(comment),$(subst $(newline),$$$$(newline),$(subst $$,$$$$,$2)))
$1: | $(LIB_DIR)
	$$(call SUP,GEN,$$@)$$(call ECHO,$$(subst $$$$(comment),$$(comment),$$(subst $$$$(newline),$$(newline),$$(TEMPLATE)))) > $$@
$(call STD_TARGET_VARS,$1)
endef

# generate pkg-config file for dynamic or static library
# arguments - the same as for $(PKGCONFIG_TEMPLATE)
PKGCONFIG_GEN_RULE = $(eval $(call PKGCONFIG_GEN_RULE1,$(LIB_DIR)/lib$1.pc,$(PKGCONFIG_TEMPLATE)))

# define standard pkg-config values
# note: some of PC_... variables may be already defined in $(TOP)/make/project.mk
pc_escape   = $(subst %,%%,$(subst $(space),$$(space),$1))
pc_unescape = $(subst $$(space), ,$(subst %%,%,$1))
pc_nchoose  = $(firstword $(filter-out $(pc_escape),$(call pc_escape,$2) $3))

PC_PREFIX      ?= $(if $(PREFIX),$(PREFIX),/usr/local)
PC_EXEC_PREFIX ?= $(call pc_unescape,$(call pc_nchoose,$(PC_PREFIX),$(EXEC_PREFIX),$${prefix}))
PC_LIBDIR1      = $(call pc_unescape,$(call pc_nchoose,$(PC_PREFIX)/$1,$(call \
  pc_nchoose,$(EXEC_PREFIX)/$1,$(LIBDIR),$${exec_prefix}/$1),$${prefix}/$1))
PC_LIBDIR      ?= $(call PC_LIBDIR1,$(firstword $(call pc_escape,$(notdir $(LIBDIR))) lib))
PC_INCLUDEDIR  ?= $${prefix}/include
PC_CFLAGS      ?= -I$${includedir}
PC_LIBS        ?= -L$${libdir}

# rule for generation of .pc-file using $(PC_...) predefined values
# $1    - library name
# $2    - library version (for a DLL: $(SOVER))
# $3    - library description
# $4    - library comment (author, description, etc.)
# $5    - project url     (likely $(VENDOR_URL))
# $6    - Requires section
# $7    - Requires.private section
# $8    - Conflicts section
# $9    - additional Cflags
# $(10) - additional dependency Libs
# $(11) - Libs.private section
# $(12) - ${includedir},  if not specified, then $(PC_INCLUDEDIR)
# $(13) - ${libdir},      if not specified, then $(PC_LIBDIR)
# $(14) - ${exec_prefix}, if not specified, then $(PC_EXEC_PREFIX)
# $(14) - ${prefix},      if not specified, then $(PC_PREFIX)
PKGCONFIG_RULE = $(call PKGCONFIG_GEN_RULE,$1,$2,$3,$4,$5,$6,$7,$8,$(PC_CFLAGS)$(if \
  $9, $9),$(PC_LIBS) -l$1$(if $(10), $(10)),$(11),$(if $(12),$(12),$(PC_INCLUDEDIR)),$(if \
  $(13),$(13),$(PC_LIBDIR)),$(if $(14),$(14),$(PC_EXEC_PREFIX)),$(if $(15),$(15),$(PC_PREFIX)))

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS, \
  PKGCONFIG_TEMPLATE PKGCONFIG_GEN_RULE1 PKGCONFIG_GEN_RULE pc_escape pc_unescape pc_nchoose \
  PC_PREFIX PC_EXEC_PREFIX PC_LIBDIR1 PC_LIBDIR PC_INCLUDEDIR PC_CFLAGS PC_LIBS PKGCONFIG_RULE)

endif
