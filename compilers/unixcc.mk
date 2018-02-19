#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# common part of unix compiler toolchain (application-level), included by:
#  $(cb_dir)/compilers/gcc.mk
#  $(cb_dir)/compilers/suncc.mk

# 'rpath' - location where to search for external dependency libraries at runtime, e.g.: /opt/lib or $ORIGIN/../lib
# note: use 'rpath' to locate private dynamic libraries only, public ones - should be located via /etc/ld.so.conf or LD_LIBRARY_PATH
# note: 'rpath' variable may be overridden in project configuration makefile or in command line
# note: to define target-specific 'rpath' variable - use 'c_redefine' macro from $(cb_dir)/types/c/c_base.mk, e.g.:
#  exe := my_exe
#  $(call c_redefine,exe,rpath,my_rpath_value)
rpath:=

# reset additional makefile variables at beginning of the target makefile
# 'map' - linker map file (used mostly to list exported symbols)
c_prepare_unix_app_vars := $(newline)map:=

# patch code executed at beginning of the target makefile
$(call define_append,c_prepare_app_vars,$$(c_prepare_unix_app_vars))

# optimization: try to expand 'c_prepare_unix_app_vars' and redefine 'c_prepare_app_vars' as non-recursive variable
$(call try_make_simple,c_prepare_app_vars,c_prepare_unix_app_vars)

# auxiliary defines for an exe
# $1 - $(call form_trg,$t,$v)
# $2 - $(call fixpath,$(map))
# $t - exe
# $v - R,P
# note: target-specific 'map' variable is inherited by the (child) dlls this exe depends on, so dependent dlls _must_ define their own
#  target-specific 'map' variables to override one inherited from the (parent) exe
# note: last line must be empty!
define exe_aux_templv
$1:map := $2
$1:$2

endef

# auxiliary defines for a dll
# $1 - $(call form_trg,$t,$v)
# $2 - $(call fixpath,$(map))
# $t - dll
# $v - R
# note: define dll's own target-specific 'map' variable - override inherited target-specific 'map' variable of a (parent) exe
#  (or another parent dll) which depends on this (child) dll
# note: define target-specific 'modver' variable - it is used by 'mk_soname_option' macro in the $(cb_dir)/compilers/gcc.mk
# note: last line must be empty!
define dll_aux_templv
$1:modver := $(modver)
$1:map := $2
$1:$2

endef

# $1 - $(call fixpath,$(map))
# $t - exe or dll
unix_mod_aux_appt = $(foreach v,$(call get_variants,$t),$(call $t_aux_templv,$(call form_trg,$t,$v),$1))

# auxiliary defines for exe or dll
# define target-specific variables: 'map' and 'modver' (only for dll)
unix_mod_aux_app = $(foreach t,exe dll,$(if $($t),$(call unix_mod_aux_appt,$(call fixpath,$(map)))))

# 'map' variable is used only when building exe or dll
ifdef cb_checking
map_variable_check = $(if $(map),$(if $(lib),$(if $(exe)$(dll),,$(warning 'map' variable is not used when building a lib))))
$(eval unix_mod_aux_app = $$(map_variable_check)$(value unix_mod_aux_app))
endif

# patch 'c_define_app_rules' template (defined in $(cb_dir)/types/_c.mk)
# for dll and exe: define target-specific variables 'rpath' and 'map'
# for dll:         also define target-specific variable 'modver'
$(call define_prepend,c_define_app_rules,$$(eval $$(unix_mod_aux_app)))

# wrapper around ar - files archiver
# $1 - output file      (libmy_lib.a)
# $2 - archiver command (ar -crs)
# $3 - objects          (1.o 2.o ...)
# $4 - number of objects that may be added to archive at once (that number is limited by the maximum command line length)
# note: 'xcmd' - defined in $(cb_dir)/core/functions.mk
unix_ar_wrap = $(call xcmd,ar_add_files,$3,$4,$2,$1)

# callback of 'unix_ar_wrap'
# $1 - objects
# $2 - archiver command
# $3 - output file
ar_add_files = $2 $3 $1

# makefile parsing first phase variables
cb_first_phase_vars += c_prepare_unix_app_vars exe_aux_templv dll_aux_templv unix_mod_aux_appt unix_mod_aux_app map_variable_check

# protect variables from modifications in target makefiles
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,cb_first_phase_vars)

# protect variables from modifications in target makefiles
# note: trace namespace: unixcc
$(call set_global,rpath c_prepare_unix_app_vars \
  exe_aux_templv=t;v dll_aux_templv=t;v unix_mod_aux_appt=t unix_mod_aux_app map_variable_check unix_ar_wrap ar_add_files,unixcc)
