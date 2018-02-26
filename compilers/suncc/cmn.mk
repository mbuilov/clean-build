#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# common suncc compiler definitions, included by $(cb_dir)/compilers/suncc.mk

# note: c_dep_suffix - defined in $(cb_dir)/types/c/c_base.mk
ifdef c_dep_suffix

# $(SED) script used to generate dependencies file from suncc compiler output
#
# note: cannot use '-xMD' cc option - it generates .d files without phony targets for the header files, e.g.:
#  e.o: e.c
#  e.o: e.h
#  e.h:      <--- wasn't added to generated .d file
#
# $1 - compiler with options (unused)
# $2 - target object file
# $3 - prefixes of system includes to filter out, e.g. /usr/include/
#
# /^$(tab)*\//!{p;d;}                         - print all lines not started with optional tabs and /, start new circle
# s/^\$(tab)*//;                              - strip-off leading tabs
# $(foreach x,$3,\@^$x.*@d;)                  - delete lines beginning with system include paths, start new circle
# s@.*@&:\$(newline)$2: &@;w $(basename $2).d - construct dependencies, then write them to the generated dep-file
#
suncc_deps_script = \
-e '/^$(tab)*\//!{p;d;}' \
-e 's/^\$(tab)*//;$(foreach x,$3,\@^$x.*@d;)s@.*@&:\$(newline)$2: &@;w $(basename $2)$(c_dep_suffix)'

# optimization: replace references to $(tab), $(newline) and $(c_dep_suffix) with their values
$(call expand_partially,suncc_deps_script,tab newline c_dep_suffix)

# call compiler and auto-generate dependencies
# $1 - compiler with options
# $2 - target object file
# $3 - prefixes of system includes to filter out, e.g. /usr/include/
# note: redirect compiler output to stderr, stdout is used for build-script generation (in verbose mode)
# note: SED, GREP, NUL - defined in $(utils_mk) (e.g. $(cb_dir)/utils/unix.mk)
wrap_suncc = { { $1 -H 2>&1 && $(ECHO) OK >&2; } | $(SED) -n $(suncc_deps_script) 2>&1; } 3>&2 2>&1 1>&3 3>&- | $(GREP) OK > $(NUL)

else # !c_dep_suffix

# just call compiler
# $1 - compiler with options
wrap_suncc = $1

endif # !c_dep_suffix

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: suncc
$(call set_global,suncc_deps_script wrap_suncc,suncc)
