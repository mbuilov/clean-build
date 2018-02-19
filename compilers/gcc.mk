#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# gcc compiler toolchain (application-level), included by $(cb_dir)/types/_c.mk

# define 'rpath' and target-specific variables 'map' and 'modver' (for dlls only)
include $(dir $(lastword $(MAKEFILE_LIST)))unixcc.mk

# common gcc definitions
ifeq (,$(filter-out undefined environment,$(origin gcc_rsp_wrap)))
include $(cb_dir)/compilers/gcc/cmn.mk
endif

# command prefix for cross-compilation
CROSS_PREFIX ?=

# target processor flags
# assume by default, gcc will compile for CBLD_BCPU
#  cpu=x86_64 bcpu=i686   -> -m64
#  cpu=i686   bcpu=x86_64 -> -m32
CBLD_CPU_CFLAGS  ?= $(if $(CBLD_CPU:x86_64=),$(if $(CBLD_CPU:i686=),,$(if $(CBLD_BCPU:x86_64=),, -m32)),$(if $(CBLD_BCPU:i686=),, -m64))
CBLD_TCPU_CFLAGS ?= $(if $(CBLD_TCPU:x86_64=),$(if $(CBLD_TCPU:i686=),,$(if $(CBLD_BCPU:x86_64=),, -m32)),$(if $(CBLD_BCPU:i686=),, -m64))

# C/C++ compilers and linkers
# note: ignore Gnu Make defaults
ifeq (default,$(origin CC))
CC := $(CROSS_PREFIX)gcc$(CBLD_CPU_CFLAGS)
else
CC ?= $(CROSS_PREFIX)gcc$(CBLD_CPU_CFLAGS)
endif

ifeq (default,$(origin CXX))
CXX := $(CROSS_PREFIX)g++$(CBLD_CPU_CFLAGS)
else
CXX ?= $(CROSS_PREFIX)g++$(CBLD_CPU_CFLAGS)
endif

ifeq (default,$(origin AR))
AR := $(CROSS_PREFIX)ar
else
AR ?= $(CROSS_PREFIX)ar
endif

# default values of user-defined C/C++ compiler flags
CFLAGS   ?= $(if $(debug),-ggdb,-g -O2)
CXXFLAGS ?= $(CFLAGS)

# flags for the objects archiver 'ar'
# note: ignore Gnu Make defaults
ifdef (default,$(origin ARFLAGS))
ARFLAGS := -rcs
else
ARFLAGS ?= -rcs
endif

# default values of user-defined gcc flags for linking executables and shared libraries
LDFLAGS ?=

# default gcc flags for compiling application-level C/C++ sources
CBLD_CMN_CFLAGS   ?= -Wall -fvisibility=hidden
CBLD_DEF_CFLAGS   ?= -std=c99 -pedantic $(CBLD_CMN_CFLAGS)
CBLD_DEF_CXXFLAGS ?= $(CBLD_CMN_CFLAGS)

# default gcc flags for linking an exe or dll
CBLD_CMN_LDFLAGS ?= -Wl,--warn-common -Wl,--no-demangle
CBLD_EXE_LDFLAGS ?= $(CBLD_CMN_LDFLAGS)
CBLD_DLL_LDFLAGS ?= -shared -Wl,--no-undefined $(CBLD_CMN_LDFLAGS)

# native compilers/linkers used to create build tools
CBLD_TCC  ?= $(if $(filter $(CBLD_CPU),$(CBLD_TCPU)),$(CC),gcc$(CBLD_TCPU_CFLAGS))
CBLD_TCXX ?= $(if $(filter $(CBLD_CPU),$(CBLD_TCPU)),$(CC),g++$(CBLD_TCPU_CFLAGS))
CBLD_TAR  ?= $(if $(CROSS_PREFIX),ar,$(AR))

# compiler/linker flags for the tool mode
CBLD_TCFLAGS       ?= $(if $(debug),-ggdb,-g -O2)
CBLD_TCXXFLAGS     ?= $(CBLD_TCFLAGS)
CBLD_TARFLAGS      ?= -rcs
CBLD_TLDFLAGS      ?=
CBLD_CMN_TCFLAGS   ?= -Wall -fvisibility=hidden
CBLD_DEF_TCFLAGS   ?= -std=c99 -pedantic $(CBLD_CMN_TCFLAGS)
CBLD_DEF_TCXXFLAGS ?= $(CBLD_CMN_TCFLAGS)
CBLD_CMN_TLDFLAGS  ?= -Wl,--warn-common -Wl,--no-demangle
CBLD_EXE_TLDFLAGS  ?= $(CBLD_CMN_TLDFLAGS)
CBLD_DLL_TLDFLAGS  ?= -shared -Wl,--no-undefined $(CBLD_CMN_TLDFLAGS)

# gcc options to build position-independent executables/shared objects (dynamic libraries)
CBLD_PIC_COPTION ?= -fpic
CBLD_PIE_COPTION ?= -fpie
CBLD_PIE_LOPTION ?= -pie

# supported target variants:
# R - default variant: position-dependent code - for 'exe' or 'lib', position-independent code - for 'dll'
# P - position-independent code - for 'exe' or 'lib' (linked to position-independent exe)
# D - position-independent code - for 'lib' (linked to dll)
# note: override defaults from $(cb_dir)/types/_c.mk
exe_extra_variants := P
lib_extra_variants := P D

# only one non-regular variant of an exe is supported: P - see $(exe_extra_variants) above
# $1 - P
# note: override defaults from $(cb_dir)/types/_c.mk
exe_variant_suffix := _pie

# two non-regular variants of a lib are supported: P and D - see $(lib_extra_variants) above
# $1 - P or D
# note: override defaults from $(cb_dir)/types/_c.mk
lib_variant_suffix = $(if $(findstring P,$1),_pie,_pic)

# get default C/C++ compiler flags
# $(is_tool_mode) - non-empty in tool mode, empty otherwise
def_cflags   = $(if $(is_tool_mode),$(CBLD_DEF_TCFLAGS),$(CBLD_DEF_CFLAGS))
def_cxxflags = $(if $(is_tool_mode),$(CBLD_DEF_TCXXFLAGS),$(CBLD_DEF_CXXFLAGS))

# only one non-regular variant of an exe is supported: P - see $(exe_extra_variants) above
# $1 - R or P
# $(is_tool_mode) - non-empty in tool mode, empty otherwise
# note: override defaults from $(cb_dir)/types/_c.mk
# note: called by trg_cflags/trg_cxxflags/trg_ldflags from $(cb_dir)/types/c/c_base.mk
exe_cflags   = $(if $(findstring P,$1),$(CBLD_PIE_COPTION)) $(def_cflags)
exe_cxxflags = $(if $(findstring P,$1),$(CBLD_PIE_COPTION)) $(def_cxxflags)
exe_ldflags  = $(if $(findstring P,$1),$(CBLD_PIE_LOPTION)) $(if $(is_tool_mode),$(CBLD_EXE_TLDFLAGS),$(CBLD_EXE_LDFLAGS))

# no non-regular variants of a dll are supported
# $1 - R
# $(is_tool_mode) - non-empty in tool mode, empty otherwise
# note: override defaults from $(cb_dir)/types/_c.mk
# note: called by trg_cflags/trg_cxxflags/trg_ldflags from $(cb_dir)/types/c/c_base.mk
dll_cflags   = $(def_cflags)
dll_cxxflags = $(def_cxxflags)
dll_ldflags  = $(if $(is_tool_mode),$(CBLD_DLL_TLDFLAGS),$(CBLD_DLL_LDFLAGS))

# two non-regular variants of a lib are supported: P and D - see $(lib_extra_variants) above
# $1 - R, P or D
# note: override defaults from $(cb_dir)/types/_c.mk
# note: called by trg_cflags/trg_cxxflags/trg_ldflags from $(cb_dir)/types/c/c_base.mk
lib_cflags   = $(if $(findstring P,$1),$(CBLD_PIE_COPTION),$(if $(findstring D,$1),$(CBLD_PIC_COPTION))) $(def_cflags)
lib_cxxflags = $(if $(findstring P,$1),$(CBLD_PIE_COPTION),$(if $(findstring D,$1),$(CBLD_PIC_COPTION))) $(def_cxxflags)

# make linker command for linking an exe or dll
# target-specific: 'tm' - defined in exe_template/dll_template/lib_template macros from $(cb_dir)/types/_c.mk
# target-specific: 'compiler', 'cflags', 'cxxflags' - defined by 'c_base_template' in $(cb_dir)/types/c/c_base.mk
# note: user-defined CFLAGS/CXXFLAGS must be added after $(cflags)/$(cxxflags) be able to override them
# note: 'pipe_option' - defined in $(cb_dir)/compilers/gcc/cmn.mk
get_linker = $(if $(compiler:cxx=),$(if \
  $(tm),$(CBLD_TCC) $(pipe_option) $(cflags) $(CBLD_TCFLAGS),$(CC) $(pipe_option) $(cflags) $(CFLAGS)),$(if \
  $(tm),$(CBLD_TCXX) $(pipe_option) $(cxxflags) $(CBLD_TCXXFLAGS),$(CXX) $(pipe_option) $(cxxflags) $(CXXFLAGS)))

# option for specifying dynamic linker runtime search path for an exe or dll
# possibly (if defined via 'c_redefine') target-specific: 'rpath' - defined in $(cb_dir)/compilers/unixcc.mk
# note: 'wlprefix' - defined in $(cb_dir)/compilers/gcc/cmn.mk
mk_rpath_option = $(addprefix $(wlprefix)-rpath=,$(rpath))

# link-time path used to search for shared libraries
# note: assume if needed, it may be redefined as target-specific variable in the target makefile
#  (via 'c_redefine' macro - see $(cb_dir)/types/c/c_base.mk, like with 'rpath' variable)
rpath_link:=

# option for specifying link-time search path for linking an exe or dll
# possibly (if defined via 'c_redefine') target-specific: 'rpath_link' - defined above
# note: 'wlprefix' - defined in $(cb_dir)/compilers/gcc/cmn.mk
mk_rpath_link_option = $(addprefix $(wlprefix)-rpath-link=,$(rpath_link))

# gcc options to begin the list of static/dynamic libraries to link to the target
bstatic_option  := -Wl,-Bstatic
bdynamic_option := -Wl,-Bdynamic

# common linker options for exe or dll
# $1 - path to target exe or dll
# $2 - objects
# $3 - target type: exe or dll
# $4 - non-empty variant: R,P,D
# target-specific: 'tm', 'libs', 'dlls', 'lib_dir '- defined by exe_template/dll_template/lib_template in $(cb_dir)/types/_c.mk 
# target-specific: ldflagss/syslibs - defined by 'c_base_template' in $(cb_dir)/types/c/c_base.mk
# note: user-defined LDFLAGS must be added after $(ldflags) to be able to override them
# note: dep_lib_names/dep_imp_names - defined in $(cb_dir)/types/_c.mk
cmn_libs = $(mk_rpath_option) $(mk_rpath_link_option) $(ldflags) $(if \
  $(tm),$(CBLD_TLDFLAGS),$(LDFLAGS)) -o $(call gcc_path,$1 $2) $(if $(firstword \
  $(libs)$(dlls)),-L$(call gcc_path,$(lib_dir)) $(addprefix -l,$(call dep_imp_names,$3,$4)) $(if \
  $(libs),$(bstatic_option) $(addprefix -l,$(call dep_lib_names,$3,$4)) $(bdynamic_option))) $(syslibs)

# specify what symbols to export from a dll/exe
# target-specific: 'map' - defined by exe_aux_templv/dll_aux_templv macros in $(cb_dir)/compilers/unixcc.mk
# note: 'wlprefix' - defined in $(cb_dir)/compilers/gcc/cmn.mk
mk_map_option = $(addprefix $(wlprefix)--version-script=,$(map))

# append "soname" option if target shared library have a version info (e.g. some number after .so)
# $1 - full path to the target shared library, for ex. /aa/bb/cc/libmy_lib.so, if modver=1.2.3 then "soname" will be libmy_lib.so.1
# target-specific: 'modver' - defined by 'dll_aux_templv' macro in $(cb_dir)/compilers/unixcc.mk
# note: 'wlprefix' - defined in $(cb_dir)/compilers/gcc/cmn.mk
mk_soname_option = $(addprefix $(wlprefix)-soname=$(notdir $1).,$(firstword $(subst ., ,$(modver))))

# linkers for each variant of exe,dll,lib
# $1 - path to the target exe,dll,lib
# $2 - objects for linking to the target
# $3 - target type: exe,dll,lib
# $4 - non-empty variant: R,P,D
# target-specific: 'tm' - defined in exe_template/dll_template/lib_template in $(cb_dir)/types/_c.mk
# note: used by exe_template/dll_template/lib_template macros from $(cb_dir)/types/_c.mk
# note: 'gcc_rsp_wrap' and CBLD_LINK_ARGS_LIMIT - defined in $(cb_dir)/compilers/gcc/cmn.mk
# note: 'unix_ar_wrap' - defined in $(cb_dir)/compilers/unixcc.mk
exe_ld = $(call gcc_rsp_wrap,$(tm)EXE,$1,$(get_linker),$(mk_map_option) $(cmn_libs))
dll_ld = $(call gcc_rsp_wrap,$(tm)DLL,$1,$(get_linker),$(mk_map_option) $(mk_soname_option) $(cmn_libs))
lib_ld = $(call suppress,$(tm)LIB,$1)$(call unix_ar_wrap,$(gcc_path),$(if \
  $(tm),$(CBLD_TAR) $(CBLD_TARFLAGS),$(AR) $(ARFLAGS)),$(call gcc_path,$2),$(CBLD_LINK_ARGS_LIMIT))

# parameters of application-level C and C++ compilers
# $1 - target object file
# $2 - source
# $3 - target type: exe,dll,lib
# $4 - non-empty variant: R,P,D
# target-specific: 'tm' - defined in exe_template/dll_template/lib_template in $(cb_dir)/types/_c.mk
# target-specific: 'defines', 'include', 'cflags', 'cxxflags' - defined by 'c_base_template' in $(cb_dir)/types/c/c_base.mk
# note: user-defined CFLAGS/CXXFLAGS must be added after cflags/cxxflags to be able to override them
# note: 'pipe_option', 'auto_deps_flags' - are defined in $(cb_dir)/compilers/gcc/cmn.mk
cc_params  = $(pipe_option) $(auto_deps_flags) $(defines) $(include) $(cflags) $(if $(tm),$(CBLD_TCFLAGS),$(CFLAGS)) -c -o $1 $2
cxx_params = $(pipe_option) $(auto_deps_flags) $(defines) $(include) $(cxxflags) $(if $(tm),$(CBLD_TCXXFLAGS),$(CXXFLAGS)) -c -o $1 $2

# C/C++ compilers for each variant of exe,dll,lib
# $1 - target object file
# $2 - source
# $3 - target type: exe,dll,lib
# $4 - non-empty variant: R,P,D
# target-specific: 'tm' - defined in exe_template/dll_template/lib_template in $(cb_dir)/types/_c.mk
# note: called by 'obj_rules_templ' macro from $(cb_dir)/library/obj_rules.mk
obj_cc  = $(call suppress,$(tm)CC,$2)$(if $(tm),$(CBLD_TCC),$(CC)) $(cc_params)
obj_cxx = $(call suppress,$(tm)CXX,$2)$(if $(tm),$(CBLD_TCXX),$(CXX)) $(cxx_params)

ifeq (,$(CBLD_NO_PCH))

# add support for precompiled headers

ifeq (,$(filter-out undefined environment,$(origin gcc_pch_templatet)))
include $(cb_dir)/compilers/gcc/pch.mk
endif

# override C/C++ compilers to support compiling sources with precompiled header
# $1 - target object file
# $2 - source
# $3 - target type: exe,dll,lib
# $4 - non-empty variant: R,P,D
# note: $(basename $(notdir $(pch)))_pch_cxx.h and $(basename $(notdir $(pch)))_pch_c.h files are virtual (i.e. do not exist)
# target-specific: 'tm' - defined in exe_template/dll_template/lib_template in $(cb_dir)/types/_c.mk
# target-specific: 'pch', 'cc_with_pch', 'cxx_with_pch' - defined by 'pch_vars_templ' macro from $(cb_dir)/types/c/pch.mk
obj_cc  = $(if $(filter $2,$(cc_with_pch)),$(call \
  suppress,$(tm)PCC,$2)$(if $(tm),$(CBLD_TCC),$(CC)) -I$(dir $1) -include $(basename $(notdir $(pch)))_pch_c.h,$(call \
  suppress,$(tm)CC,$2)$(if $(tm),$(CBLD_TCC),$(CC))) $(cc_params)
obj_cxx = $(if $(filter $2,$(cxx_with_pch)),$(call \
  suppress,$(tm)PCXX,$2)$(if $(tm),$(CBLD_TCXX),$(CXX)) -I$(dir $1) -include $(basename $(notdir $(pch)))_pch_cxx.h,$(call \
  suppress,$(tm)CXX,$2)$(if $(tm),$(CBLD_TCXX),$(CXX))) $(cxx_params)

# compilers of C/C++ precompiled header
# $1 - target .gch (e.g. /build/obj/xxx_pch_c.h.gch or /build/obj/xxx_pch_cxx.h.gch)
# $2 - source pch header (full path, e.g. /src/include/xxx.h)
# $3 - target type: exe,dll,lib
# $4 - non-empty variant: R,P,D
# target-specific: 'tm' - defined in exe_template/dll_template/lib_template in $(cb_dir)/types/_c.mk
# note: used by 'gcc_pch_rule_templ' macro from $(cb_dir)/compilers/gcc/pch.mk
pch_cc  = $(call suppress,$(tm)PCHCC,$2)$(if $(tm),$(CBLD_TCC),$(CC)) $(cc_params)
pch_cxx = $(call suppress,$(tm)PCHCXX,$2)$(if $(tm),$(CBLD_TCXX),$(CXX)) $(cxx_params)

# reset additional makefile variables
# note: 'c_prepare_pch_vars' - defined in $(cb_dir)/types/c/pch.mk
$(call define_append,c_prepare_app_vars,$$(c_prepare_pch_vars))

# optimization: try to expand 'c_prepare_pch_vars' and redefine 'c_prepare_app_vars' as non-recursive variable
$(call try_make_simple,c_prepare_app_vars,c_prepare_pch_vars)

# for all application-level targets: add support for precompiled headers
# note: patch 'c_define_app_rules' macro - defined in $(cb_dir)/types/_c.mk
# note: 'c_app_targets' - defined in $(cb_dir)/types/_c.mk
$(call define_prepend,c_define_app_rules,$$(eval $$(foreach t,$(c_app_targets),$$(if $$($$t),$$(gcc_pch_templatet)))))

endif # !CBLD_NO_PCH

# remember values the variables possibly defined in the environment
$(call config_remember_vars,CROSS_PREFIX CBLD_CPU_CFLAGS CBLD_TCPU_CFLAGS CC CXX AR CFLAGS CXXFLAGS ARFLAGS LDFLAGS \
  CBLD_CMN_CFLAGS CBLD_DEF_CFLAGS CBLD_DEF_CXXFLAGS CBLD_CMN_LDFLAGS CBLD_EXE_LDFLAGS CBLD_DLL_LDFLAGS CBLD_TCC CBLD_TCXX CBLD_TAR \
  CBLD_TCFLAGS CBLD_TCXXFLAGS CBLD_TARFLAGS CBLD_TLDFLAGS CBLD_CMN_TCFLAGS CBLD_DEF_TCFLAGS CBLD_DEF_TCXXFLAGS CBLD_CMN_TLDFLAGS \
  CBLD_EXE_TLDFLAGS CBLD_DLL_TLDFLAGS CBLD_PIC_COPTION CBLD_PIE_COPTION CBLD_PIE_LOPTION)

# makefile parsing first phase variables
cb_first_phase_vars += def_cflags def_cxxflags

# protect variables from modifications in target makefiles
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,CROSS_PREFIX CBLD_CPU_CFLAGS CBLD_TCPU_CFLAGS CC CXX AR CFLAGS CXXFLAGS ARFLAGS LDFLAGS \
  CBLD_CMN_CFLAGS CBLD_DEF_CFLAGS CBLD_DEF_CXXFLAGS CBLD_CMN_LDFLAGS CBLD_EXE_LDFLAGS CBLD_DLL_LDFLAGS CBLD_TCC CBLD_TCXX CBLD_TAR \
  CBLD_TCFLAGS CBLD_TCXXFLAGS CBLD_TARFLAGS CBLD_TLDFLAGS CBLD_CMN_TCFLAGS CBLD_DEF_TCFLAGS CBLD_DEF_TCXXFLAGS CBLD_CMN_TLDFLAGS \
  CBLD_EXE_TLDFLAGS CBLD_DLL_TLDFLAGS CBLD_PIC_COPTION CBLD_PIE_COPTION CBLD_PIE_LOPTION cb_first_phase_vars)

# protect variables from modifications in target makefiles
# note: trace namespace: gcc
$(call set_global,def_cflags def_cxxflags get_linker mk_rpath_option rpath_link mk_rpath_link_option \
  bstatic_option bdynamic_option cmn_libs mk_map_option mk_soname_option exe_ld dll_ld lib_ld \
  cc_params cxx_params obj_cc obj_cxx pch_cc pch_cxx,gcc)
