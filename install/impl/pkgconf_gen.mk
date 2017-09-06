#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# pkg-config file generation

# text of generated .pc file
# $1  - library name (human-readable)
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
define PKGCONF_LIB_TEMPLATE
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

# normalize path: replace backward slashes with forward ones (for Windows), remove trailing slash
# note: assume no backslashes are used in pkg-config paths on Unix
# note: on Windows, paths must use forward slashes to not confuse pkg-config executable
pkgconf_path = $(patsubst %/,%,$(subst \,/,$1))

# try to replace in $1 prefix $2 with $3
# note: paths $1 and $2 are previously processed by pkgconf_path, so there are no backslashes in them
pkgconf_replace_prefix = $(patsubst \%/,%,$(subst \$2/,\$3/,\$1/))

# try to replace:
# $(12) - $(PREFIX)
# $(13) - $(EXEC_PREFIX) -> ${prefix}
# $(14) - $(DEVLIBDIR)   -> ${exec_prefix}/lib/x86_64-linux-gnu
# $(15) - $(INCLUDEDIR)  -> ${prefix}/include
PKGCONF_LIB_GENERATE1 = $(call PKGCONF_LIB_TEMPLATE,$1,$2,$3,$4,$5,$6,$7,$8,$9,$(10),$(11),$(12),$(call \
  pkgconf_replace_prefix,$(13),$(12),$${prefix}),$(call \
  pkgconf_replace_prefix,$(14),$(13),$${exec_prefix}),$(call \
  pkgconf_replace_prefix,$(15),$(12),$${prefix}))

# generate pkg-config file contents for the library
# $1    - library name (human-readable), e.g. my library
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
# $(14) - ${libdir},      e.g. $(DEVLIBDIR)
# $(15) - ${includedir},  e.g. $(INCLUDEDIR)
PKGCONF_LIB_GENERATE = $(call PKGCONF_LIB_GENERATE1,$1,$2,$3,$4,$5,$6,$7,$8,$9,$(10),$(11),$(call \
  pkgconf_path,$(12)),$(call pkgconf_path,$(13)),$(call pkgconf_path,$(14)),$(call pkgconf_path,$(15)))

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,PKGCONF_LIB_TEMPLATE pkgconf_path pkgconf_replace_prefix PKGCONF_LIB_GENERATE1 PKGCONF_LIB_GENERATE)