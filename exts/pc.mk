#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# pkg-config file generation

ifndef PKGCONF_DEF_TEMPLATE

include $(MTOP)/exts/echo_inst.mk

# $1   - Library name (human-readable)
# $2   - Version
# $3   - Description
# $4   - Comment (author, description, etc.)
# $5   - Project URL
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
# note: PKGCONF_TEMPLATE may be already defined in $(TOP)/make/project.mk
ifndef PKGCONF_TEMPLATE
define PKGCONF_TEMPLATE
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
endef
endif

# define standard pkg-config values
# note: some of PKGCONF_... variables may be already defined in $(TOP)/make/project.mk
pc_escape   = $(subst %,%%,$(subst $(space),$$(space),$1))
pc_unescape = $(subst $$(space), ,$(subst %%,%,$1))
# $2 == $1 ? $3 : $2
pc_nchoose  = $(firstword $(filter-out $(pc_escape),$(call pc_escape,$2) $3))

PKGCONF_PREFIX      ?= $(if $(PREFIX),$(PREFIX),/usr/local)
PKGCONF_EXEC_PREFIX ?= $(call pc_unescape,$(call pc_nchoose,$(PKGCONF_PREFIX),$(EXEC_PREFIX),$${prefix}))
PKGCONF_INCLUDEDIR  ?= $(call pc_unescape,$(foreach d,$(firstword $(call pc_escape,$(notdir $(INCLUDEDIR))) include),$(call \
  pc_nchoose,$(PKGCONF_PREFIX)/$d,$(INCLUDEDIR),$${prefix}/$d)))
PKGCONF_LIBDIR      ?= $(foreach d,$(firstword $(call pc_escape,$(notdir $(LIBDIR))) lib),$(call pc_unescape,$(call \
  pc_nchoose,$(PKGCONF_PREFIX)/$d,$(call pc_nchoose,$(EXEC_PREFIX)/$d,$(LIBDIR),$${exec_prefix}/$d),$${prefix}/$d)))
PKGCONF_CFLAGS      ?= -I$${includedir}
PKGCONF_LIBS        ?= -L$${libdir}

# generate pkg-config file contents for dynamic or static library using $(PKGCONF_...) predefined values
# $1    - library name
# $2    - library version ($(MODVER))
# $3    - library description
# $4    - library comment (author, description, etc.)
# $5    - project url     (likely $(VENDOR_URL))
# $6    - Requires section
# $7    - Requires.private section
# $8    - Conflicts section
# $9    - additional Cflags
# $(10) - additional dependency Libs
# $(11) - Libs.private section
# $(12) - ${includedir},  if not specified, then $(PKGCONF_INCLUDEDIR)
# $(13) - ${libdir},      if not specified, then $(PKGCONF_LIBDIR)
# $(14) - ${exec_prefix}, if not specified, then $(PKGCONF_EXEC_PREFIX)
# $(14) - ${prefix},      if not specified, then $(PKGCONF_PREFIX)
PKGCONF_DEF_TEMPLATE = $(call PKGCONF_TEMPLATE,$1,$2,$3,$4,$5,$6,$7,$8,$(PKGCONF_CFLAGS)$(if \
  $9, $9),$(PKGCONF_LIBS) -l$1$(if $(10), $(10)),$(11),$(if $(12),$(12),$(PKGCONF_INCLUDEDIR)),$(if \
  $(13),$(13),$(PKGCONF_LIBDIR)),$(if $(14),$(14),$(PKGCONF_EXEC_PREFIX)),$(if $(15),$(15),$(PKGCONF_PREFIX)))

# get path to installed .pc-file
# $1 - static or dynamic library name
INSTALLED_PKGCONF ?= '$(DESTDIR)$(PKG_CONFIG_DIR)/$1.pc'

# get paths to installed .pc-files
# $1 - all built libraries (result of $(GET_ALL_LIBS))
INSTALLED_PKGCONFS ?= $(foreach r,$1,$(call INSTALLED_PKGCONF,$(firstword $(subst ?, ,$r))))

# install .pc-file
# $1 - <lib> <variant>
# $2 - .pc-file contents generator, called with parameters: <lib>,<variant>
# Note: .pc-file contents generator generally expands $(PKGCONF_TEMPLATE) or $(PKGCONF_DEF_TEMPLATE)
INSTALL_PKGCONF ?= $(foreach l,$(firstword $1),$(call ECHO_INSTALL,$(call $2,$l,$(word 2,$1)),$(call INSTALLED_PKGCONF,$l),644))

# install .pc-files
# $1 - all built libraries (result of $(GET_ALL_LIBS))
# $2 - .pc-file contents generator, called witch parameters: <lib>,<variant>
# Note: .pc-file contents generator generally expands $(PKGCONF_TEMPLATE) or $(PKGCONF_DEF_TEMPLATE)
INSTALL_PKGCONFS ?= $(foreach r,$1,$(newline)$(call INSTALL_PKGCONF,$(subst ?, ,$r),$2))

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,PKGCONF_TEMPLATE PKGCONF_DEF_TEMPLATE pc_escape pc_unescape pc_nchoose \
  PKGCONF_PREFIX PKGCONF_EXEC_PREFIX PKGCONF_LIBDIR PKGCONF_INCLUDEDIR PKGCONF_CFLAGS PKGCONF_LIBS PKGCONF_DEF_TEMPLATE \
  INSTALLED_PKGCONF INSTALLED_PKGCONFS INSTALL_PKGCONF INSTALL_PKGCONFS)

endif
