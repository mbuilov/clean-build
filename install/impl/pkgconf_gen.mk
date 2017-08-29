#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# pkg-config file generation

# text of generated .pc file
# $1  - library name (abbreviated)
# $2  - Version: major.minor.patch
# $3  - Description (arbitrary text)
# $4  - Comment (author, description, etc.)
# $5  - Project URL
# $6  - Requires
# $7  - Requires.private
# $8  - Conflicts
# $9  - Cflags (flags and include dirs)
# $10 - dependency libraries (names and paths)
# $11 - private dependency libs (names and paths)
# $12 - ${prefix}
# $13 - ${exec_prefix}
# $14 - ${libdir}
# $15 - ${includedir}
define PKGCONF_TEXT
$(if $4,# $(subst $(newline),$(newline)# ,$4)$(newline))
prefix=$(12)
exec_prefix=$(13)
libdir=$(14)
includedir=$(15)

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

# normalize path: replace backward slashes with forward ones, remove trailing slash
pc_path = $(patsubst %/,%,$(subst \,/,$1))

# try to replace in $1 prefix $2 with $3, make $(OS)-specific path
# note: paths $1 and $2 are previously processed by pc_path, so there are no backslashes in them
pc_replace = $(call ospath,$(patsubst \%/,%,$(subst \$2/,\$3/,\$1/)))

# try to replace:
# $(EXEC_PREFIX) -> ${prefix}
# $(LIBDIR)      -> ${exec_prefix}/lib/x86_64-linux-gnu
# $(INCLUDEDIR)  -> ${prefix}/include
PKGCONF_GEN1 = $(call PKGCONF_TEXT,$1,$2,$3,$4,$5,$6,$7,$8,$9,$(10),$(11),$(12),$(call \
  pc_replace,$(13),$(12),$${prefix}),$(call pc_replace,$(14),$(13),$${exec_prefix}),$(call pc_replace,$(15),$(12),$${prefix}))

# generate pkg-config file contents for the library
# $1    - library name (abbreviated), e.g. mylib
# $2    - library version, e.g. $(MODVER)
# $3    - library description (arbitrary text)
# $4    - library comment (author, description, etc.)
# $5    - project url, e.g. $(VENDOR_URL)
# $6    - Requires section
# $7    - Requires.private section
# $8    - Conflicts section
# $9    - Cflags, e.g -I$${includedir}/mylib
# $(10) - dependency libraries, e.g. -L$${libdir} -lmylib
# $(11) - Libs.private section
# $(12) - ${prefix},      e.g. $(PREFIX)
# $(13) - ${exec_prefix}, e.g. $(EXEC_PREFIX)
# $(14) - ${libdir},      e.g. $(LIBDIR)/x86_64-linux-gnu
# $(15) - ${includedir},  e.g. $(INCLUDEDIR)
PKGCONF_GEN = $(call PKGCONF_GEN1,$1,$2,$3,$4,$5,$6,$7,$8,$9,$(10),$(11),$(call \
  pc_path,$(12)),$(call pc_path,$(13)),$(call pc_path,$(14)),$(call pc_path,$(15)))

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,PKGCONF_TEXT pc_path pc_replace PKGCONF_GEN1 PKGCONF_GEN)

## get path to installed .pc-file
## $1 - static or dynamic library name
#INSTALLED_PKGCONF = '$(DESTDIR)$(PKG_CONFIG_DIR)/$1.pc'
#
## get paths to installed .pc-files
## $1 - all built libraries (result of $(GET_ALL_LIBS))
#INSTALLED_PKGCONFS = $(foreach r,$1,$(call INSTALLED_PKGCONF,$(firstword $(subst ?, ,$r))))
#
## install .pc-file
## $1 - <lib> <variant>
## $2 - .pc-file contents generator, called with parameters: <lib>,<variant>
## Note: .pc-file contents generator generally expands $(PKGCONF_TEXT_TEMPLATE) or $(PKGCONF_DEF_TEMPLATE)
#INSTALL_PKGCONF = $(foreach l,$(firstword $1),$(call ECHO_INSTALL,$(call $2,$l,$(word 2,$1)),$(call INSTALLED_PKGCONF,$l),644))
#
## install .pc-files
## $1 - all built libraries (result of $(GET_ALL_LIBS))
## $2 - .pc-file contents generator, called witch parameters: <lib>,<variant>
## Note: .pc-file contents generator generally expands $(PKGCONF_TEXT_TEMPLATE) or $(PKGCONF_DEF_TEMPLATE)
#INSTALL_PKGCONFS = $(foreach r,$1,$(newline)$(call INSTALL_PKGCONF,$(subst ?, ,$r),$2))
