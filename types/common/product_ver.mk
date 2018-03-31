#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# product version in form "major.minor" or "major.minor.patch"
# Note: this is the default value of 'modver' variable - per-module version number defined by 'c_prepare_base_vars' template from
#  $(cb_dir)/types/c/c_base.mk
product_version := 0.0.1

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: product_version
$(call set_global,product_version,product_version)
