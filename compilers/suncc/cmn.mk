#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# common suncc compiler definitions, included by $(CLEAN_BUILD_DIR)/compilers/suncc.mk

# $(SED) script to generate dependencies file from suncc compiler output
#
# note: '-xMD' cc option generates only partial makefile-dependency .d file
#  - it doesn't include empty targets for dependency headers:
#
#  e.o: e.c
#  e.o: e.h
#  e.h:      <--- missing in generated .d file
#
# $1 - compiler with options (unused)
# $2 - target object file
# $3 - prefixes of system includes to filter out, e.g. /usr/include/

# /^$(tab)*\//!{p;d;}             - print all lines not started with optional tabs and /, start new circle
# s/^\$(tab)*//;                  - strip-off leading tabs
# $(foreach x,$3,\@^$x.*@d;)      - delete lines started with system include paths, start new circle
# s@.*@&:\$(newline)$2: &@;w $2.d - make dependencies, then write to generated dep-file

SUNCC_DEPS_SCRIPT = \
-e '/^$(tab)*\//!{p;d;}' \
-e 's/^\$(tab)*//;$(foreach x,$3,\@^$x.*@d;)s@.*@&:\$(newline)$2: &@;w $(basename $2).d'

# either just call compiler or call compiler and auto-generate dependencies
# $1 - compiler with options
# $2 - target object file
# $3 - prefixes of system includes to filter out, e.g. /usr/include/
ifdef NO_DEPS
WRAP_SUNCC = $1
else
WRAP_SUNCC = { { $1 -H 2>&1 && echo OK >&2; } | $(SED) -n $(SUNCC_DEPS_SCRIPT) 2>&1; } 3>&2 2>&1 1>&3 3>&- | grep OK > /dev/null
endif

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,SUNCC_DEPS_SCRIPT WRAP_SUNCC)
