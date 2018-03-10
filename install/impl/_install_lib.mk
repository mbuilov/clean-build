#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# included by $(cb_dir)/install/install_lib.mk

ifeq (,$(filter-out undefined environment,$(origin need_install_dir)))
include $(dir $(lastword $(MAKEFILE_LIST)))inst_utils.mk
endif

ifeq (,$(filter-out undefined environment,$(origin install_text)))
include $(cb_dir)/install/impl/inst_text.mk
endif

# next CBLD_NO_... macros are used to form default specification of a library installation,
# for example, setting CBLD_NO_INSTALL_HEADERS:=1 in the command line prevents installation of headers for all libraries of the package
# by default, use library settings specified in the target makefile, here $1 - library name without variant suffix
#  (e.g. mylib for libmylib_pie.a)

# non-empty if do not install/uninstall header files
# note: '$1_library_no_devel' - global variable defined for the library $1 by 'define_install_lib_vars' template (see below)
CBLD_NO_INSTALL_HEADERS ?= $($1_library_no_devel)

# non-empty if do not install/uninstall static libraries
# note: '$1_library_no_devel' - global variable defined for the library $1 by 'define_install_lib_vars' template (see below)
CBLD_NO_INSTALL_STATIC ?= $($1_library_no_devel)

# non-empty if do not install/uninstall shared libraries
# note: by default, install shared libraries if they are built (e.g. 'no_shared' is not set)
CBLD_NO_INSTALL_SHARED ?=

# non-empty if do not install/uninstall dll import libraries (for Windows)
# note: '$1_library_no_devel' - global variable defined for the library $1 by 'define_install_lib_vars' template (see below)
CBLD_NO_INSTALL_IMPORT ?= $($1_library_no_devel)

# non-empty if do not install/uninstall pkg-config .pc-files
# note: '$1_library_no_devel' - global variable defined for the library $1 by 'define_install_lib_vars' template (see below)
CBLD_NO_INSTALL_PKGCONF ?= $($1_library_no_devel)

# write result of $(lib_pkgconf_generator) by fixed number of lines at a time
# note: command line length is limited (by 8191 chars on Windows), so must not write more
#  than that number of chars (lines * max_chars_in_line) at a time.
CBLD_INST_CONF_WRITE_BY_LINES ?= 35

# file access mode of installed static libraries (rw-r--r--)
CBLD_STATIC_LIB_ACCESS_MODE ?= 644

# file access mode of installed shared libraries (rwxr-xr-x)
CBLD_SHARED_LIB_ACCESS_MODE ?= 755

# file access mode of installed library headers (rw-r--r--)
CBLD_LIB_HEADERS_ACCESS_MODE ?= 644

# file access mode of installed library descriptions (rw-r--r--)
CBLD_LIB_CONF_ACCESS_MODE ?= 644

# define library-specific variables for use in installation templates
# $1 - library name without variant suffix (e.g. mylib for libmylib_pie.a)
# note: assume 'lib' and 'dll' variables are defined before expanding this template
# note: variable 'lib_no_devel' and other 'lib_no_...' variables are may be set in the target makefile before
#  expanding 'install_lib' macro to specify per-library installation configuration
# note: it is possible to override library-specific options either in the command line or in project configuration makefile,
#  for example: 'mylib_library_no_devel:=1' prevents installation of development files for library 'mylib'
# note: use $(addprefix /) to set empty value to '$1_library_hdir' variable if $(lib_hdir) is empty (by default)
define define_install_lib_vars
$1_built_lib_variants         := $(if $(lib),$(call get_variants,lib))
$1_built_dll_variants         := $(if $(dll),$(call get_variants,dll))
$1_built_libs                 := $$(foreach v,$$($1_built_lib_variants),$$(call form_trg,lib,$$v))
$1_built_dlls                 := $$(foreach v,$$($1_built_dll_variants),$$(call form_trg,dll,$$v))
$1_library_no_devel           := $$(lib_no_devel)
$1_library_no_install_headers := $$(lib_no_install_headers)# -> $$(CBLD_NO_INSTALL_HEADERS) -> $$($$1_library_no_devel)
$1_library_no_install_static  := $$(lib_no_install_static)#  -> $$(CBLD_NO_INSTALL_STATIC)  -> $$($$1_library_no_devel)
$1_library_no_install_shared  := $$(lib_no_install_shared)#  -> $$(CBLD_NO_INSTALL_SHARED)  ->
$1_library_no_install_import  := $$(lib_no_install_import)#  -> $$(CBLD_NO_INSTALL_IMPORT)  -> $$($$1_library_no_devel)
$1_library_no_install_pkgconf := $$(lib_no_install_pkgconf)# -> $$(CBLD_NO_INSTALL_PKGCONF) -> $$($$1_library_no_devel)
ifeq (,$$($1_library_no_install_headers))
$1_library_headers            := $$(call fixpath,$$(lib_headers))
$1_library_hdir               := $$(addprefix /,$$(lib_hdir))
endif
endef

# install static libs
# $1 - library name without variant suffix (e.g. mylib for libmylib_pie.a)
# $2 - where to install static libraries, should be $$(d_devlibdir)
define install_lib_static
install_lib_$1_static uninstall_lib_$1_static: built_libs := $$($1_built_libs)
install_lib_$1_static: $$($1_built_libs) | $$(call need_install_dir_r,$2)
	$$(call do_install_files,$$(built_libs),$2,$(CBLD_STATIC_LIB_ACCESS_MODE))
uninstall_lib_$1_static:
	$$(call do_uninstall_files_in,$2,$$(notdir $$(built_libs)))
install_lib_$1:   install_lib_$1_static
uninstall_lib_$1: uninstall_lib_$1_static
$(call cb_makefile_info_templ,install_lib_$1_static uninstall_lib_$1_static)
endef

# install shared libs
# $1 - library name without variant suffix (e.g. mylib for libmylib_pie.a)
# $3 - where to install shared libraries, may be $$(d_libdir) (Unix) or $$(d_bindir) (Windows)
# note: this template is overridden in $(cb_dir)/install/impl/install_lib_unix.mk
define install_lib_shared
install_lib_$1_shared uninstall_lib_$1_shared: built_dlls := $$($1_built_dlls)
install_lib_$1_shared: $$($1_built_dlls) | $$(call need_install_dir_r,$3)
	$$(call do_install_files,$$(built_dlls),$3,$(CBLD_SHARED_LIB_ACCESS_MODE))
uninstall_lib_$1_shared:
	$$(call do_uninstall_files_in,$3,$$(notdir $$(built_dlls)))
install_lib_$1:   install_lib_$1_shared
uninstall_lib_$1: uninstall_lib_$1_shared
$(call cb_makefile_info_templ,install_lib_$1_shared uninstall_lib_$1_shared)
endef

# library headers installation template
# $1 - library name without variant suffix (e.g. mylib for libmylib_pie.a)
# note: $(define_install_lib_vars) must be evaluated before expanding this template, so '$1_library_hdir' is defined
define install_lib_headers
install_lib_$1_headers uninstall_lib_$1_headers: headers := $$($1_library_headers)
install_lib_$1_headers: $$($1_library_headers) | $$(call need_install_dir_r,$$(d_includedir)$($1_library_hdir))
	$$(call do_install_files,$$(headers),$$(d_includedir)$($1_library_hdir),$(CBLD_LIB_HEADERS_ACCESS_MODE))
uninstall_lib_$1_headers:
	$$(call do_uninstall_files_in,$$(d_includedir)$($1_library_hdir),$$(notdir $$(headers)))$(if \
  $($1_library_hdir),$(newline)$(tab)$$(call do_try_uninstall_dir,$$(d_includedir)$($1_library_hdir)))
install_lib_$1:   install_lib_$1_headers
uninstall_lib_$1: uninstall_lib_$1_headers
$(call cb_makefile_info_templ,install_lib_$1_headers uninstall_lib_$1_headers)
endef

# $1 - library name without variant suffix (e.g. mylib for libmylib_pie.a)
# $2 - name of configuration template
# $3 - parameter for configuration template $2
# $4 - list of built libs+variants, in form name/variant, e.g. mylib_pie/P
# $5 - list of built dlls+variants, in form name/variant, e.g. mylib_st/S
# 1) call template $2 for each built static variant of the library with selected dynamic variant, e.g. mylib_pie/X/Y
# 2) call template $2 for each built dynamic variant of the library with empty static variant, e.g. mylib_pie//Z
# note: assume even if file names of static and dynamic variants of the library are the same, variants may be different,
#  for example: mylib_ww/X (static variant) and mylib_ww/Y (dynamic variant) -> combine as mylib_ww/X/Y
# note: template $2 is called with next parameters:
#  $1 - library name without variant suffix (e.g. mylib for libmylib_pie.a)
#  $2 - full library name (with variant suffix) and names of static/dynamic variants, e.g. mylib_pie/X/Y
#  $3 - parameter
install_lib_configs1 = $(foreach l,$4,$(call $2,$1,$l/$(lastword $(subst /, ,$(filter $(firstword \
  $(subst /, ,$l))/%,$5))),$3)$(newline))$(foreach d,$(filter-out $(foreach l,$4,$(firstword \
  $(subst /, ,$l))/%),$5),$(call $2,$1,$(subst /,//,$d),$3)$(newline))

# helper macro for generating library configurations
# $1 - library name without variant suffix (e.g. mylib for libmylib_pie.a)
# $2 - name of configuration template
# $3 - parameter for configuration template $2
# note: $(define_install_lib_vars) must be evaluated before expanding this macro, so
#  '$1_built_lib_variants', '$1_built_dll_variants', '$1_built_libs' and '$1_built_dlls' are defined
install_lib_configs = $(call install_lib_configs1,$1,$2,$3,$(join \
  $(patsubst $(lib_prefix)%$(lib_suffix),%/,$(notdir $($1_built_libs))),$($1_built_lib_variants)),$(join \
  $(patsubst $(dll_prefix)%$(dll_suffix),%/,$(notdir $($1_built_dlls))),$($1_built_dll_variants)))

# generate configuration file for a combination of static+dynamic variants of a library $1
# $1 - library name without variant suffix (e.g. mylib for libmylib_pie.a)
# $2 - full library name (with variant suffix) and names of static/dynamic variants, e.g. mylib_pie/X/Y
# $3 - name of generated configuration file, e.g. mylib_pie.pc for mylib_pie/X/Y
# $4 - directory where to install generated configuration file, should be $$(d_pkg_libdir), $$(d_pkg_datadir) or similar
# $5 - target suffix, e.g. pkfconf
# $6 - name of configuration generator macro, e.g. 'lib_pkgconf_generator'
define install_lib_config_one
tmp_conf_text := $$($6)
ifdef tmp_conf_text
install_lib_$1_$3 uninstall_lib_$1_$3: conf_text := $$(tmp_conf_text)
install_lib_$1_$3 uninstall_lib_$1_$3: conf_file := $4/$3
install_lib_$1_$3:| $$(call need_install_dir_r,$4)
	$$(call install_text,$$(conf_text),$$(conf_file),$(CBLD_INST_CONF_WRITE_BY_LINES),$(CBLD_LIB_CONF_ACCESS_MODE))
uninstall_lib_$1_$3:
	$$(call do_uninstall_file,$$(conf_file))
install_lib_$1_$5:   install_lib_$1_$3
uninstall_lib_$1_$5: uninstall_lib_$1_$3
build_system_goals += install_lib_$1_$3 uninstall_lib_$1_$3
endif
endef

# called from 'install_lib_configs1' with parameters:
# $1 - library name without variant suffix (e.g. mylib for libmylib_pie.a)
# $2 - full library name (with variant suffix) and names of static/dynamic variants, e.g. mylib_pie/X/Y
# $3 - parameter, should be $$(d_pkg_libdir), $$(d_pkg_datadir) or similar
install_lib_pkgconf_one = $(call install_lib_config_one,$1,$2,$(firstword $(subst /, ,$2)).pc,$3,pkgconf,lib_pkgconf_generator)

# install pkg-config files
# $1 - library name without variant suffix (e.g. mylib for libmylib_pie.a)
# $4 - where to install pkg-configs, should be $$(d_pkg_libdir), $$(d_pkg_datadir) or similar
define install_lib_pkgconf
$(call install_lib_configs,$1,install_lib_pkgconf_one,$4)
install_lib_$1:   install_lib_$1_pkgconf
uninstall_lib_$1: uninstall_lib_$1_pkgconf
$(call cb_makefile_info_templ,install_lib_$1_pkgconf uninstall_lib_$1_pkgconf)
endef

# library base installation template
# $1 - library name (e.g. mylib for libmylib.a)
# $2 - where to install static libraries, should be $$(d_devlibdir)
# $3 - where to install shared libraries, may be $$(d_libdir) or $$(d_bindir)
# $4 - where to install pkg-configs, should be $$(d_pkg_libdir), $$(d_pkg_datadir) or similar
# note: $(define_install_lib_vars) must be evaluated before expanding this template, so next variables are defined:
#  '$1_library_no_install_{static,shared,headers,pkgconf}', '$1_built_libs', '$1_built_dlls' and '$1_library_headers'
define install_lib_base
$(if $($1_library_no_install_static),,$(if $($1_built_libs),$(install_lib_static)))
$(if $($1_library_no_install_shared),,$(if $($1_built_dlls),$(install_lib_shared)))
$(if $($1_library_no_install_headers),,$(if $($1_library_headers),$(install_lib_headers)))
$(if $($1_library_no_install_pkgconf),,$(install_lib_pkgconf))
build_system_goals += \
  install_lib_$1_static uninstall_lib_$1_static \
  install_lib_$1_shared uninstall_lib_$1_shared \
  install_lib_$1_headers uninstall_lib_$1_headers \
  install_lib_$1_pkgconf uninstall_lib_$1_pkgconf \
  install_lib_$1 uninstall_lib_$1
install:   install_lib_$1
uninstall: uninstall_lib_$1
endef

# do not trace calls to macros modified via operator +=
ifdef cb_checking
$(call define_append,install_lib_base,$(newline)$$(call set_global1,build_system_goals))
endif

# makefile with definition of operating system specific 'install_lib' macro
# note: CBLD_INSTALL_OS_TYPE defined in $(cb_dir)/install/impl/inst_dirs.mk
install_lib_mk := $(cb_dir)/install/impl/install_lib_$(CBLD_INSTALL_OS_TYPE).mk

ifeq (,$(wildcard $(install_lib_mk)))
$(error file '$(install_lib_mk)' was not found, check $(if $(findstring file,$(origin \
  install_lib_mk)),value of CBLD_INSTALL_OS_TYPE=$(CBLD_INSTALL_OS_TYPE),value of overridden 'install_lib_mk' variable))
endif

# define operating system specific 'install_lib' macro
include $(install_lib_mk)

# remember values of variables possibly taken from the environment
$(call config_remember_vars,CBLD_NO_INSTALL_HEADERS CBLD_NO_INSTALL_STATIC CBLD_NO_INSTALL_SHARED CBLD_NO_INSTALL_IMPORT \
  CBLD_NO_INSTALL_PKGCONF CBLD_INST_CONF_WRITE_BY_LINES CBLD_STATIC_LIB_ACCESS_MODE CBLD_SHARED_LIB_ACCESS_MODE \
  CBLD_LIB_HEADERS_ACCESS_MODE CBLD_LIB_CONF_ACCESS_MODE)

# makefile parsing first phase variables
cb_first_phase_vars += define_install_lib_vars install_lib_static install_lib_shared install_lib_headers install_lib_configs1 \
  install_lib_configs install_lib_config_one install_lib_pkgconf_one install_lib_pkgconf install_lib_base install_lib

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,CBLD_NO_INSTALL_HEADERS CBLD_NO_INSTALL_STATIC CBLD_NO_INSTALL_SHARED CBLD_NO_INSTALL_IMPORT \
  CBLD_NO_INSTALL_PKGCONF CBLD_INST_CONF_WRITE_BY_LINES CBLD_STATIC_LIB_ACCESS_MODE CBLD_SHARED_LIB_ACCESS_MODE \
  CBLD_LIB_HEADERS_ACCESS_MODE CBLD_LIB_CONF_ACCESS_MODE cb_first_phase_vars)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: install_lib
$(call set_global,define_install_lib_vars install_lib_static install_lib_shared install_lib_headers \
  install_lib_configs1 install_lib_configs install_lib_config_one install_lib_pkgconf_one install_lib_pkgconf \
  install_lib_base install_lib_mk install_lib,install_lib)
