#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define Unix-specific 'install_lib' macro

# included by $(cb_dir)/install/impl/_install_lib.mk

# install shared libs and SONAME simlinks: libmylib.so.1 -> libmylib.so.1.2.3
# $1 - library name without variant suffix (e.g. mylib for libmylib_pie.a)
# $3 - where to install shared libraries, should be $$(d_libdir)
# note: override 'install_lib_shared' template from $(cb_dir)/install/impl/_install_lib.mk
# note: assume $(modver) may be empty, then do not install simlinks
# note: also do not install simlinks if $(modver) contains only one digit, e.g.: libmylib.so.1
define install_lib_shared
install_lib_$1_shared uninstall_lib_$1_shared: built_dlls := $$($1_built_dlls)
install_lib_$1_shared: $$($1_built_dlls) | $$(call need_install_dir_ret,$3)
	$$(foreach d,$$(built_dlls),$$(call \
  do_install_files,$$d,$3/$$(notdir $$d)$(modver:%=.%),$(CBLD_SHARED_LIB_ACCESS_MODE))$$(newline))$(foreach \
  n,$(filter-out $(modver),$(firstword $(subst ., ,$(modver)))),$$(foreach d,$$(notdir $$(built_dlls)),$$(call \
  do_install_simlink,$$d.$(modver),$3/$$d.$n)$$(newline)))
uninstall_lib_$1_shared:
	$$(call do_uninstall_files_in,$3,$$(addsuffix $(modver:%=.%),$$(notdir $$(built_dlls)))$(foreach \
  n,$(filter-out $(modver),$(firstword $(subst ., ,$(modver)))), $$(addsuffix .$n,$$(notdir $$(built_dlls)))))
install_lib_$1:   install_lib_$1_shared
uninstall_lib_$1: uninstall_lib_$1_shared
$(call cb_makefile_info_templ,install_lib_$1_shared uninstall_lib_$1_shared)
endef

# install compile-time development simlinks to the installed shared libs: dev/libmylib.so -> ../lib/libmylib.so.1.2.3
# $1 - library name without variant suffix (e.g. mylib for libmylib_pie.a)
# $2 - where to install compile-time simlinks to shared libraries, should be $$(d_devlibdir)
# $3 - shared libraries are installed, should be $$(d_libdir)
# note: $(modver) must be non-empty
define install_lib_simlinks
install_lib_$1_simlinks uninstall_lib_$1_simlinks: built_dlls := $$(notdir $$($1_built_dlls))
install_lib_$1_simlinks uninstall_lib_$1_simlinks: rel_prefix := $$(call \
  tospaces,$$(call relpath,$$(call unspaces,$2),$$(call unspaces,$3)))
install_lib_$1_simlinks: install_lib_$1_shared | $$(call need_install_dir_ret,$2)
	$$(foreach d,$$(built_dlls),$$(call \
  do_install_simlink,$$(rel_prefix)$$d.$(modver),$2/$$d)$$(newline))
uninstall_lib_$1_simlinks:
	$$(call do_uninstall_files_in,$2,$$(built_dlls))
install_lib_$1:   install_lib_$1_simlinks
uninstall_lib_$1: uninstall_lib_$1_simlinks
$(call cb_makefile_info_templ,install_lib_$1_simlinks uninstall_lib_$1_simlinks)
endef

# implementation of Unix-specific 'install_lib' macro
# $1 - library name without variant suffix (e.g. mylib for libmylib_pie.a)
# $2 - where to install static libraries, should be $$(d_devlibdir)
# $3 - where to install shared libraries, should be $$(d_libdir)
# $4 - where to install pkg-configs, should be $$(d_pkg_libdir), $$(d_pkg_datadir) or similar
# note: $(define_install_lib_vars) was evaluated before expanding this macro (as required by 'install_lib_base'), so next
#  variables are defined: '$1_library_no_install_shared', '$1_library_no_devel', '$1_built_dlls'
define install_lib_unix
$(install_lib_base)
$(if $($1_library_no_install_shared),,$(if $($1_library_no_devel),,$(if $(modver),$(if $($1_built_dlls),$(install_lib_simlinks)))))
build_system_goals += install_lib_$1_simlinks uninstall_lib_$1_simlinks
endef

# Unix specific: rules for installing/uninstalling the library and its headers
# $1 - library name without variant suffix (e.g. mylib for libmylib_pie.a)
# note: assume variables 'lib' and/or 'dll' are defined before expanding this template
# note: install libs to $(d_devlibdir), dlls - to $(d_libdir)
# note: 'lib_pkgconf_dir' - defined in $(cb_dir)/install/install_lib.mk
install_lib = $(eval $(define_install_lib_vars))$(eval $(call \
  install_lib_unix,$1,$$(d_devlibdir),$$(d_libdir),$$(call \
  destdir_normalize,$$(lib_pkgconf_dir))))

# makefile parsing first phase variables
cb_first_phase_vars += install_lib_simlinks install_lib_unix

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: install_lib
$(call set_global,install_lib_simlinks install_lib_unix,install_lib)
