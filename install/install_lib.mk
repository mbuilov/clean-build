#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define 'install_lib' - library installation macro

# this file is likely included at end (e.g. after $(define_targets)) of a target makefile, which builds (and/or):
# lib - static flavor of a library (in one or more variants: pic, pie, etc.)
# dll - dynamic flavor of a library (in one or more variants: with statically or dynamically linked libc, etc.)

# anyway, 'lib' and/or 'dll' variables _must_ be defined before expanding 'install_lib' macro
# note: if library names specified in 'lib' and 'dll' variables do not match, then assume that two different libraries are built

ifeq (,$(filter-out undefined environment,$(origin install_lib)))
include $(dir $(lastword $(MAKEFILE_LIST)))impl/_install_lib.mk
endif

# set default values of variables which form a specification of a library installation
# note: these variables are normally redefined in the library target makefile anywhere before expanding 'install_lib' macro
# note: CBLD_NO_DEVEL - defined in $(cb_dir)/install/impl/inst_dirs.mk
# note: CBLD_NO_INSTALL_... - defined in $(cb_dir)/install/impl/_install_lib.mk
lib_no_devel           := $(CBLD_NO_DEVEL)
lib_no_install_headers  = $(CBLD_NO_INSTALL_HEADERS)# -> $($1_library_no_devel) -> $(lib_no_devel)
lib_no_install_static   = $(CBLD_NO_INSTALL_STATIC)#  -> $($1_library_no_devel) -> $(lib_no_devel)
lib_no_install_shared   = $(CBLD_NO_INSTALL_SHARED)#  ->
lib_no_install_import   = $(CBLD_NO_INSTALL_IMPORT)#  -> $($1_library_no_devel) -> $(lib_no_devel)
lib_no_install_pkgconf  = $(CBLD_NO_INSTALL_PKGCONF)# -> $($1_library_no_devel) -> $(lib_no_devel)

# list of library header files to install, may be empty
lib_headers:=

# name of installed library headers sub-directory, may be empty, must not contain spaces
lib_hdir:=

# the name of pkg-config file generator macro, must be defined if $(lib_no_install_pkgconf) gives an empty value
# $1 - library name without variant suffix, as specified in $(lib) or $(dll), e.g. mylib for built libmylib_pie.a
# $2 - full library name (with variant suffix) and names of static/dynamic variants, e.g. mylib_pie/X/Y, where:
#  mylib_pie - library name 'mylib' with variant suffix '_pie',
#  X/Y - specification of variants of static/dynamic flavors of the library, each variant may be optional, but not both:
#   mylib_pie/X/  - only static flavor in variant X of a library was built,
#   mylib_pie//Y  - only dynamic flavor in variant Y of a library was built,
#   mylib_pie/X/Y - both static and dynamic flavors in variants X (static) and Y (dynamic) of a library were built.
# $3 - name of generated pkg-config file, e.g. mylib_pie.pc for mylib_pie/X/Y
# $4 - directory where to install generated configuration file, should be $$(d_pkg_libdir), $$(d_pkg_datadir) or similar
# tip: for implementing this macro use helper macro 'pkgconf_lib_generate' from $(cb_dir)/install/pkgconf_gen.mk
lib_pkgconf_generator:=

# directory where to install pkg-config files:
# $(PKG_LIBDIR)  - for ordinary libraries
# $(PKG_DATADIR) - for header-only libraries
lib_pkgconf_dir = $(PKG_LIBDIR)

# after (re-)defining above variables, just expand $(install_lib) to define next targets based on the values of $(lib) and/or $(dll):
#
# for lib := mylib                            |
#  or dll := mylib                            |
#  or lib := mylib and dll := mylib           |  for lib := mylibS and dll := mylibD
#                                             |
# (if names of 'lib' and 'dll' are the same,  |  (if names of 'lib' and 'dll' do not match,
#  this means that one library is built       |   this means that two different libraries were built:
#  in two flavors: static and dynamic)        |   one in static flavor and other - in dynamic flavor)
#                                             |
# install_lib_mylib                           |  install_lib_mylibS               install_lib_mylibD
# install_lib_mylib_static                    |  install_lib_mylibS_static        install_lib_mylibD_static
# install_lib_mylib_shared                    |  install_lib_mylibS_shared   and  install_lib_mylibD_shared
# install_lib_mylib_headers                   |  install_lib_mylibS_headers       install_lib_mylibD_headers
# install_lib_mylib_pkgconf                   |  install_lib_mylibS_pkgconf       install_lib_mylibD_pkgconf
#
# and their uninstall_... counterparts,
#
# also, install_lib_mylib/uninstall_lib_mylib targets are will be added as dependencies for standard install/uninstall goals.
