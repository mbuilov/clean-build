#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# rules for building application-level C/C++ libs, dlls and executables

# source base definitions
ifeq (,$(filter-out undefined environment,$(origin c_base_template)))
include $(dir $(lastword $(MAKEFILE_LIST)))c/c_base.mk
endif

# register application-level C/C++ target types
c_app_targets := exe lib dll
c_target_types += $(c_app_targets)

# After a target name may be specified one or more variants of the target to build (for example, exe := my_exe R S).
# If variant is not specified, default variant R will be built, else - only specified variants (may add R to build also default variant).
#
# Interpretation of variants depends on the target type and destination platform, for example:
# R (default, regular variant)
#  for UNIX:
#   exe,lib     - position-dependent code
#   dll         - position-independent code
#  for WINDOWS:
#   exe,lib,dll - dynamically linked multi-threaded libc (compiled with /MD cl.exe option)
# P (position-independent code in executables)
#  for UNIX:
#   exe,lib     - position-independent code in executables (compiled with -fpie gcc option)
# D (position-independent code in shared libraries)
#  for UNIX:
#   lib         - position-independent code in shared libraries (compiled with -fpic gcc option)
# S (statically linked multi-threaded libc)
#  for WINDOWS:
#   exe,lib,dll - statically linked multi-threaded libc (compiled with /MT cl.exe option)
#
# So, available variants of targets types in this example:
# exe:
#  R,P,S
# dll:
#  R,S
# lib:
#  R (for linking to R-variant of exe)
#  P (for linking to P-variant of exe)
#  D (for linking to dll)
#  S (for linking to S-variant of exe or dll)
#
# List of supported target variants and their compatibility matrix (i.e. which variant of lib can be linked to a given variant of
#  exe or dll) are defined by the selected compiler toolchain for the destination platform - in included below $(c_compiler_mk) makefile.

# no non-regular target variants are supported by default
# note: used by 'extra_variants' macro defined in $(cb_dir)/library/variants.mk
# note: $(c_compiler_mk) included below likely overrides next ..._extra_variants definitions
exe_extra_variants:=
lib_extra_variants:=
dll_extra_variants:=

# determine target name suffix (in case if building multiple variants of the target, each variant must have an unique file name)
# $1 - non-empty target variant: P,D,S... (cannot be R - regular - it was filtered out by 'variant_suffix' macro)
# note: used by 'variant_suffix' macro defined in $(cb_dir)/library/variants.mk
exe_variant_suffix = _$1
lib_variant_suffix = _$1
dll_variant_suffix = _$1

# C/C++ compiler and linker flags for the target
# $1 - non-empty variant: R,P,D,S... (one of variants supported by the selected toolchain)
# note: called by trg_cflags/trg_cxxflags/trg_ldflags from $(cb_dir)/types/c/c_base.mk
# note: $(c_compiler_mk) included below likely overrides these definitions to add default compiler/linker flags
exe_cflags:=
exe_cxxflags:=
exe_ldflags:=
lib_cflags:=
lib_cxxflags:=
lib_ldflags:=
dll_cflags:=
dll_cxxflags:=
dll_ldflags:=

# assembler flags for the target
# $1 - non-empty variant: R,P,D,S... (one of variants supported by the selected toolchain)
# note: called by 'trg_asmflags' from $(cb_dir)/types/c/c_asm.mk
ifdef c_asm_supported
exe_asmflags:=
lib_asmflags:=
dll_asmflags:=
endif

# how to mark symbols exported from a dll
# note: overridden in $(cb_dir)/compilers/msvc.mk
dll_exports_define := $(call c_define_special,__attribute__((visibility("default"))))

# how to mark symbols imported from a dll
# note: overridden in $(cb_dir)/compilers/msvc.mk
dll_imports_define:=

# executable file suffix
# WINDOWS - .exe
# UNIX    - no suffix
# note: may overridden by the selected toolchain
exe_suffix := $(if $(filter WIN% CYGWIN% MINGW%,$(CBLD_OS)),.exe)

# form target file name for the exe
# $1 - target name, e.g. my_exe, may be empty
# $2 - target variant: R,P,D,S... (one of variants supported by the selected toolchain, may be empty)
# note: use $(patsubst...) to return empty value if $1 is empty, as required by 'form_trg' macro from $(cb_dir)/library/variants.mk
exe_form_trg = $(1:%=$(bin_dir)/%$(call variant_suffix,exe,$2)$(exe_suffix))

# static library (archive) prefix/suffix
# WINDOWS: lib/mylib.a
# UNIX:    lib/libmylib.a
# note: may overridden by the selected toolchain
lib_prefix := $(if $(filter WIN%,$(CBLD_OS)),,lib)
lib_suffix := .a

# form target file name for the lib
# $1 - target name, e.g. my_lib, may be empty
# $2 - target variant: R,P,D,S... (one of variants supported by the selected toolchain, may be empty)
# note: use $(patsubst...) to return empty value if $1 is empty, as required by 'form_trg' macro from $(cb_dir)/library/variants.mk
lib_form_trg = $(1:%=$(lib_dir)/$(lib_prefix)%$(call variant_suffix,lib,$2)$(lib_suffix))

# dynamically loaded library (shared object) prefix/suffix
# for modver=1.2.3
# WINDOWS: bin/mylib-1.dll
# CYGWIN:  bin/cygmylib-1.dll
# MINGW:   bin/libmylib-1.dll
# UNIX:    lib/libmylib.so.1.2.3
# note: may overridden by the selected toolchain
dll_prefix := $(if $(filter WIN%,$(CBLD_OS)),,$(if $(filter CYGWIN%,$(CBLD_OS)),cyg,lib))
dll_suffix := $(if $(filter WIN% CYGWIN% MINGW%,$(CBLD_OS)),.dll,.so)

# for WINDOWS - put dlls to $(bin_dir), but dll import libraries - put to $(lib_dir)
# for UNIX - assume import library and dll - the one same file
# note: 'dll_dir' must be recursive because $(bin_dir)/$(lib_dir) have different values in tool-mode and non-tool mode
# note: may overridden by the selected toolchain
ifneq (,$(filter WIN% CYGWIN% MINGW%,$(CBLD_OS)))
dll_dir = $(bin_dir)
else
dll_dir = $(lib_dir)
endif

# form target file name for the dll
# $1 - target name, e.g. my_dll, may be empty
# $2 - target variant: R,P,D,S... (one of variants supported by the selected toolchain, may be empty)
# note: use $(patsubst...) to return empty value if $1 is empty, as required by 'form_trg' macro from $(cb_dir)/library/variants.mk
dll_form_trg = $(1:%=$(dll_dir)/$(dll_prefix)%$(call variant_suffix,dll,$2)$(dll_suffix))

# determine which variant of static library to link to exe or dll
# $1 - target type: exe,dll
# $2 - variant of target exe or dll: R,P, if empty, then assume R
# $3 - dependency name, e.g. mylib or mylib/flag1/flag2/...
# use the same variant (R or P) of static library as the target exe (for example for P-exe use P-lib)
# always use D-variant of static library for regular dll
# note: if returns empty value - then assume it's default variant R
# note: used by 'dep_library' macro from $(cb_dir)/types/c/c_base.mk
lib_dep_map = $(if $(findstring dll,$1),D,$2)

# determine which variant of dynamic library to link to exe or dll
# $1 - target type: exe,dll
# $2 - variant of target exe or dll: R,P, if empty, then assume R
# $3 - dependency name, e.g. mylib or mylib/flag1/flag2/...
# the same one default variant (R) of dll may be linked with any P- or R-exe or R-dll
# note: if returns empty value - then assume it's default variant R
# note: used by 'dep_library' macro from $(cb_dir)/types/c/c_base.mk
dll_dep_map:=

# prefix/suffix of import library of a dll
# for modver=1.2.3
# WINDOWS: lib/mylib-1.lib       - for bin/mylib-1.dll
# CYGWIN:  lib/libmylib.dll.a    - for bin/cygmylib-1.dll
# MINGW:   lib/libmylib.dll.a    - for bin/libmylib-1.dll
# UNIX:    lib/libmylib.so.1.2.3 - dll and import library of it - is the same one file
# note: may overridden by the selected toolchain
imp_prefix := $(if $(filter WIN%,$(CBLD_OS)),,$(if $(filter CYGWIN% MINGW%,$(CBLD_OS)),lib,$(dll_prefix)))
imp_suffix := $(if $(filter WIN%,$(CBLD_OS)),.lib,$(dll_suffix)$(if $(filter CYGWIN% MINGW%,$(CBLD_OS)),.a))

# make the names of the files of static libraries the target depends on
# $1 - target type: exe,dll
# $2 - variant of target exe or dll: R,P,S or empty
# note: 'libs' - either makefile defined or target-specific variable
# note: 'dep_library' - defined in $(cb_dir)/types/c/c_base.mk
dep_lib_names = $(foreach l,$(libs),$(call dep_library,$1,$2,$l,lib))
dep_libs = $(patsubst %,$(lib_dir)/$(lib_prefix)%$(lib_suffix),$(dep_lib_names))

# make the names of the files of implementation libraries of dynamic libraries the target depends on
# $1 - target type: exe,dll
# $2 - variant of target exe or dll: R,P,S or empty
# note: 'dlls' - either makefile defined or target-specific variable
# note: 'dep_library' - defined in $(cb_dir)/types/c/c_base.mk
dep_imp_names = $(foreach d,$(dlls),$(call dep_library,$1,$2,$d,dll))
# note: assume when building a dll, 'dll_ld' generates implementation library for the dll in $(lib_dir) (and dll itself in $(dll_dir))
dep_imps = $(patsubst %,$(lib_dir)/$(imp_prefix)%$(imp_suffix),$(dep_imp_names))

# template for building executables, used by 'c_rules_templ' macro defined in $(cb_dir)/types/c/c_base.mk
# $1 - target file: $(call form_trg,$t,$v)
# $2 - sources:     $(trg_src)
# $3 - sdeps:       $(trg_sdeps)
# $4 - objdir:      $(call form_obj_dir,$t,$v)
# $t - target type: exe or dll
# $v - non-empty variant: R,P,S,...
# note: define target-specific variable 'tm' with the current value of 'is_tool_mode'
# note: target-specific variables are inherited by the dependencies, so templates for dependent libs/dlls
#  _must_ set own values of 'compiler', 'include', 'defines', 'cflags' and other sensible variables
# note: 'syslibs' - used to specify external (system) libraries, e.g. -L/opt/lib -lext
# note: $(cb_dir)/compilers/msvc.mk redefines 'exe_template'
define exe_template
$(c_base_template)
$1:tm      := $(is_tool_mode)
$1:libs    := $(libs)
$1:dlls    := $(dlls)
$1:lib_dir := $(lib_dir)
$1:syslibs := $(syslibs)
$1:$(call dep_libs,$t,$v) $(call dep_imps,$t,$v)
	$$(call $t_ld,$$@,$$(filter %$(obj_suffix),$$^),$t,$v)
endef

# template for building dynamic (shared) libraries, used by 'c_rules_templ' macro defined in $(cb_dir)/types/c/c_base.mk
# note: $(cb_dir)/compilers/msvc.mk redefines 'dll_template'
$(eval define dll_template$(newline)$(value exe_template)$(newline)endef)

# template for building static libraries, used by 'c_rules_templ' macro defined in $(cb_dir)/types/c/c_base.mk
# $1 - target file: $(call form_trg,$t,$v)
# $2 - sources:     $(trg_src)
# $3 - sdeps:       $(trg_sdeps)
# $4 - objdir:      $(call form_obj_dir,$t,$v)
# $t - target type: lib
# $v - non-empty variant: R,P,D,S
# note: define target-specific variable 'tm' with the current value of 'is_tool_mode'
# note: $(cb_dir)/compilers/msvc.mk redefines 'lib_template'
define lib_template
$(c_base_template)
$1:tm := $(is_tool_mode)
$1:
	$$(call lib_ld,$$@,$$(filter %$(obj_suffix),$$^),$t,$v)
endef

# tools colors: C, C++ compilers, executable, shared and static library linkers
CBLD_CC_COLOR  ?= [1;31m
CBLD_CXX_COLOR ?= [1;36m
CBLD_EXE_COLOR ?= [1;37m
CBLD_DLL_COLOR ?= [1;33m
CBLD_LIB_COLOR ?= [1;32m

# colors for the "tool mode"
CBLD_TCC_COLOR  ?= [31m
CBLD_TCXX_COLOR ?= [36m
CBLD_TEXE_COLOR ?= [37m
CBLD_TDLL_COLOR ?= [33m
CBLD_TLIB_COLOR ?= [32m

# code to be called at beginning of target makefile
define c_prepare_app_vars
$(c_prepare_base_vars)
exe:=
lib:=
dll:=
endef

# optimization: try to expand 'c_prepare_base_vars' and redefine 'c_prepare_app_vars' as non-recursive variable
$(call try_make_simple,c_prepare_app_vars,c_prepare_base_vars)

# define rules for building application-level targets from C/C++ sources
# note: 'c_define_rules' - defined in $(cb_dir)/types/c/c_base.mk
c_define_app_rules = $(c_define_rules)

ifdef cb_checking
# check that 'libs' or 'dlls' variables are non-empty only when building exe or dll
c_check_app_rules = $(if \
  $(if $(exe)$(dll),,$(libs)),$(warning libs = $(libs) is used only when building exe or dll))$(if \
  $(if $(exe)$(dll),,$(dlls)),$(warning dlls = $(dlls) is used only when building exe or dll))
$(call define_prepend,c_define_app_rules,$$(c_check_app_rules))
endif

# optimization: expand 'c_define_rules' in 'c_define_app_rules'
ifndef cb_tracing
$(call expand_partially,c_define_app_rules,c_define_rules)
endif

# application-level C/C++ compiler to use for the build (gcc, clang, msvc, etc.)
CBLD_C_COMPILER ?= $(if \
  $(filter WIN%,$(CBLD_OS)),msvc,$(if \
  $(filter SUN%,$(CBLD_OS)),suncc,gcc))

# makefile with definition of the application-level C/C++ compiler
c_compiler_mk := $(cb_dir)/compilers/$(CBLD_C_COMPILER).mk

ifeq (,$(wildcard $(c_compiler_mk)))
$(error file '$(c_compiler_mk)' was not found, check $(if $(findstring file,$(origin \
  c_compiler_mk)),values of CBLD_OS=$(CBLD_OS) and CBLD_C_COMPILER=$(CBLD_C_COMPILER),value of overridden 'c_compiler_mk' variable))
endif

# add compiler-specific definitions
include $(c_compiler_mk)

# remember value of CBLD_C_COMPILER - it may be taken from the environment
$(call config_remember_vars,CBLD_C_COMPILER)

# makefile parsing first phase variables
cb_first_phase_vars += exe_cflags lib_cflags dll_cflags exe_cxxflags lib_cxxflags dll_cxxflags exe_ldflags lib_ldflags dll_ldflags \
  exe_asmflags lib_asmflags dll_asmflags exe_form_trg lib_form_trg dll_dir dll_form_trg dep_libs dep_imps exe_template dll_template \
  lib_template c_prepare_app_vars c_define_app_rules c_check_app_rules

# protect variables from modifications in target makefiles
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,CBLD_CC_COLOR CBLD_CXX_COLOR CBLD_EXE_COLOR CBLD_DLL_COLOR CBLD_LIB_COLOR \
  CBLD_TCC_COLOR CBLD_TCXX_COLOR CBLD_TEXE_COLOR CBLD_TDLL_COLOR CBLD_TLIB_COLOR CBLD_C_COMPILER cb_first_phase_vars)

# protect variables from modifications in target makefiles
# note: trace namespace: c
$(call set_global,c_app_targets c_target_types \
  exe_extra_variants lib_extra_variants dll_extra_variants \
  exe_variant_suffix lib_variant_suffix dll_variant_suffix \
  exe_cflags lib_cflags dll_cflags exe_cxxflags lib_cxxflags dll_cxxflags exe_ldflags lib_ldflags dll_ldflags \
  exe_asmflags lib_asmflags dll_asmflags dll_exports_define dll_imports_define exe_suffix exe_form_trg lib_prefix \
  lib_suffix lib_form_trg dll_prefix dll_suffix dll_dir dll_form_trg lib_dep_map dll_dep_map imp_prefix imp_suffix \
  dep_lib_names=libs dep_libs dep_imp_names=dlls dep_imps exe_template=t;v;exe;lib_dir;libs;dlls;syslibs \
  dll_template=t;v;dll;lib_dir;libs;dlls;syslibs lib_template=t;v;lib c_prepare_app_vars c_define_app_rules \
  c_check_app_rules c_compiler_mk,c)
