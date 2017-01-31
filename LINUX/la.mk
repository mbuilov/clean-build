#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# note: LIBTOOL_LA_TEMPLATE may be already defined in $(TOP)/make/project.mk
ifndef LIBTOOL_LA_TEMPLATE

# libtool-archive description file generation

# $1 - dynamic library name
# $2 - dynamic library version
# $3 - static library name
# $4 - private dependency libs
# $5 - dependency libraries
# $6 - library installation directory (if not specified, then $(LIBDIR))
define LIBTOOL_LA_TEMPLATE
# lib$(firstword $1 $3).la - a libtool library file
# Generated by clean-build build system
#
# Please DO NOT delete this file!
# It is needed by libtool for linking the library.

# The name that we can dlopen(3).
dlname='$(if $1,lib$1.so$(addprefix .,$(firstword $(subst ., ,$2))))'

# Names of this library.
library_names='$(if $1,$(addprefix lib$1,$(addprefix .so.,$2 $(filter-out $2,$(firstword $(subst ., ,$2)))) .so))'

# The name of the static archive.
old_library='$(if $3,lib$3.a)'

# Linker flags that cannot go in dependency_libs.
inherited_linker_flags='$4'

# Libraries that this one depends upon.
dependency_libs='$5'

# Names of additional weak libraries provided by this library
weak_library_names=''

# Version information for libmylib.
current=$(firstword $(subst ., ,$2) 0)
age=$(firstword $(word 2,$(subst ., ,$2)) 0)
revision=$(firstword $(word 3,$(subst ., ,$2)) 0)

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
$(call CLEAN_BUILD_PROTECT_VARS,LIBTOOL_LA_TEMPLATE)

endif