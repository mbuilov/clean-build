#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# note: LIBTOOL_LA_TEMPLATE may be already defined in $(TOP)/make/project.mk
ifndef LIBTOOL_LA_TEMPLATE

# libtool-archive description file generation

# make name of generated .la file
# $1 - static library name (may be empty if $2 is not empty)
# $2 - dynamic library name (may be empty if $1 is not empty)
LIBTOOL_LA_NAME ?= $(if $1,$(LIB_PREFIX)$1,$(DLL_PREFIX)$2).la

# $1 - static library name (may be empty if $3 is not empty)
# $2 - dynamic library name (may be empty if $2 is not empty)
# $3 - library version (major.minor.patch)
# $4 - private dependency libs
# $5 - dependency libraries
# $6 - library installation directory (if not specified, then $(LIBDIR))
define LIBTOOL_LA_TEMPLATE
# $(LIBTOOL_LA_NAME) - a libtool library file
# Generated by clean-build build system
#
# Please DO NOT delete this file!
# It is needed by libtool for linking the library.

# The name that we can dlopen(3).
dlname='$(if $2,$(DLL_PREFIX)$2$(DLL_SUFFIX)$(addprefix .,$(firstword $(subst ., ,$3))))'

# Names of this library.
library_names='$(if $2,$(addprefix $(DLL_PREFIX)$2,$(addprefix \
  $(DLL_SUFFIX).,$3 $(filter-out $3,$(firstword $(subst ., ,$3)))) $(DLL_SUFFIX)))'

# The name of the static archive.
old_library='$(if $1,$(LIB_PREFIX)$1$(LIB_SUFFIX))'

# Linker flags that cannot go in dependency_libs.
inherited_linker_flags='$4'

# Libraries that this one depends upon.
dependency_libs='$5'

# Names of additional weak libraries provided by this library
weak_library_names=''

# Version information for libmylib.
current=$(firstword $(subst ., ,$3) 0)
age=$(firstword $(word 2,$(subst ., ,$3)) 0)
revision=$(firstword $(word 3,$(subst ., ,$3)) 0)

# Is this an already installed library?
installed=yes

# Should we warn about portability when linking against -modules?
shouldnotlink=no

# Files to dlopen/dlpreopen
dlopen=''
dlpreopen=''

# Directory that this library needs to be installed in:
libdir='$(if $6,$6,$(if $(LIBDIR),$(LIBDIR),/usr/local/lib))'
endef

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,LIBTOOL_LA_NAME LIBTOOL_LA_TEMPLATE)

endif
