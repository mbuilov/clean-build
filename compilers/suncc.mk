#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# suncc compiler toolchain (application-level), included by $(cb_dir)/types/_c.mk

# define 'rpath' and target-specific variables 'map' and 'modver' (for dlls only)
include $(dir $(lastword $(MAKEFILE_LIST)))unixcc.mk

# common suncc definitions
ifeq (,$(filter-out undefined environment,$(origin wrap_suncc)))
include $(cb_dir)/compilers/suncc/cmn.mk
endif

# target processor flags
# https://docs.oracle.com/cd/E18659_01/html/821-1384/bjapr.html#gewif
# "On Solaris, -m32 is the default. On Linux systems supporting 64-bit programs, -m64 -xarch=sse2 is the default."
# Solaris:
#  cpu=amd64,sparcv9 -> -m64
# Linux:
#  cpu=i386 bcpu=amd64 -> -m32
ifneq (,$(filter SUN%,$(CBLD_OS)))
CBLD_CPU_CFLAGS  ?= $(if $(CBLD_CPU:amd64=),$(if $(CBLD_CPU:sparcv9=),, -m64), -m64 -xarch=sse2)
CBLD_TCPU_CFLAGS ?= $(if $(CBLD_TCPU:amd64=),$(if $(CBLD_TCPU:sparcv9=),, -m64), -m64 -xarch=sse2)
else # Linux
CBLD_CPU_CFLAGS  ?= $(if $(CBLD_CPU:i386=),,$(if $(CBLD_BCPU:amd64=),, -m32))
CBLD_TCPU_CFLAGS ?= $(if $(CBLD_TCPU:i386=),,$(if $(CBLD_BCPU:amd64=),, -m32))
endif

# C/C++ compilers and linkers
# note: ignore Gnu Make defaults
ifeq (default,$(origin CC))
CC := cc$(CBLD_CPU_CFLAGS)
else
CC ?= cc$(CBLD_CPU_CFLAGS)
endif

ifeq (default,$(origin CXX))
CXX := CC$(CBLD_CPU_CFLAGS)
else
CXX ?= CC$(CBLD_CPU_CFLAGS)
endif

ifeq (default,$(origin AR))
AR := /usr/ccs/bin$(if $(CBLD_BCPU:amd64=),,/amd64)/ar
else
AR ?= /usr/ccs/bin$(if $(CBLD_BCPU:amd64=),,/amd64)/ar
endif

# default values of user-defined C/C++ compiler flags
# '-g'   - https://docs.oracle.com/cd/E19205-01/819-5267/6n7c46eko/index.html#indexterm-905
# '-xO4' - https://docs.oracle.com/cd/E19205-01/819-5267/6n7c46fee/index.html#indexterm-1091
CFLAGS   ?= $(if $(debug),-g,-xO4)
CXXFLAGS ?= $(CFLAGS)

# flags for the objects archiver 'ar'
# note: ignore Gnu Make defaults
ifdef (default,$(origin ARFLAGS))
ARFLAGS := -rc
else
ARFLAGS ?= -rc
endif

# create C++ static libraries using C++ compiler - this is needed for handling C++ templates
# (https://docs.oracle.com/cd/E19205-01/819-5267/6n7c46f2p/index.html#indexterm-1000)
CBLD_CXX_ARFLAGS ?= -xar -o

# default values of user-defined cc flags for linking executables and shared libraries
# '-xs' - allows debugging by dbx after deleting object (.o) files (https://docs.oracle.com/cd/E19205-01/819-5267/bkbhu/index.html)
LDFLAGS ?= $(if $(debug),-xs)

# default cc flags for compiling application-level C/C++ sources
# '-xldscope=hidden' - hide dll symbols by default (https://docs.oracle.com/cd/E19205-01/819-5267/6n7c46fao/index.html#indexterm-1058)
# '-xport64' - C++ option to enable warnings about porting to 64 bit (https://docs.oracle.com/cd/E19205-01/819-5267/bkbgj/index.html)
CBLD_CMN_CFLAGS   ?= -xldscope=hidden
CBLD_DEF_CFLAGS   ?= $(CBLD_CMN_CFLAGS)
CBLD_DEF_CXXFLAGS ?= $(if $(filter amd64 sparcv9,$(CBLD_CPU)),-xport64 )$(CBLD_CMN_CFLAGS)

# default cc flags for linking an exe or dll
# tip: may use -filt=%none to not demangle C++ names (https://docs.oracle.com/cd/E19205-01/819-5267/6n7c46eha/index.html#indexterm-889)
# '-ztext' - no text relocations in a shared object (https://docs.oracle.com/cd/E19455-01/816-0559/6m71o2afc/index.html#chapter4-29405)
# '-G' - create shared object (https://docs.oracle.com/cd/E19455-01/816-0559/6m71o2af7/index.html#chapter4-ix381)
# '-zdefs' - require that all symbols are defined (https://docs.oracle.com/cd/E19455-01/816-0559/6m71o2agc/index.html#indexterm-442)
CBLD_CMN_LDFLAGS ?= -ztext
CBLD_EXE_LDFLAGS ?= $(CBLD_CMN_LDFLAGS)
CBLD_DLL_LDFLAGS ?= -G -zdefs $(CBLD_CMN_LDFLAGS)

# native compilers/linkers used to create build tools
CBLD_TCC  ?= $(if $(filter $(CBLD_CPU),$(CBLD_TCPU)),$(CC),cc$(CBLD_TCPU_CFLAGS))
CBLD_TCXX ?= $(if $(filter $(CBLD_CPU),$(CBLD_TCPU)),$(CC),CC$(CBLD_TCPU_CFLAGS))
CBLD_TAR  ?= $(AR)

# compiler/linker flags for the tool mode
CBLD_TCFLAGS       ?= $(if $(debug),-g,-xO4)
CBLD_TCXXFLAGS     ?= $(CBLD_TCFLAGS)
CBLD_TARFLAGS      ?= -rc
CBLD_TCXX_ARFLAGS  ?= -xar -o
CBLD_TLDFLAGS      ?= $(if $(debug),-xs)
CBLD_CMN_TCFLAGS   ?= -xldscope=hidden
CBLD_DEF_TCFLAGS   ?= $(CBLD_CMN_TCFLAGS)
CBLD_DEF_TCXXFLAGS ?= $(if $(filter amd64 sparcv9,$(CBLD_TCPU)),-xport64 )$(CBLD_CMN_TCFLAGS)
CBLD_CMN_TLDFLAGS  ?= -ztext
CBLD_EXE_TLDFLAGS  ?= $(CBLD_CMN_TLDFLAGS)
CBLD_DLL_TLDFLAGS  ?= -G -zdefs $(CBLD_CMN_TLDFLAGS)

# cc options to build position-independent executables/shared objects (dynamic libraries)
# '-Kpic' - generate position-independent code (https://docs.oracle.com/cd/E19205-01/819-5267/6n7c46en7/index.html#indexterm-924)
# '-ztype=pie' - link position-independent executable (https://docs.oracle.com/cd/E53394_01/html/E54813/chapter1-1-ld.html)
CBLD_PIC_COPTION ?= -Kpic
CBLD_PIE_LOPTION ?= -ztype=pie

# supported target variants:
# R - default variant: position-dependent code - for 'exe' or 'lib', position-independent code - for 'dll'
# P - position-independent code - for 'exe'
# D - position-independent code - for 'lib' (linked to dll or position-independent exe)
# note: override defaults from $(cb_dir)/types/_c.mk
exe_extra_variants := P
lib_extra_variants := D

# only one non-regular variant of an exe is supported: P - see $(exe_extra_variants) above
# $1 - P
# note: override defaults from $(cb_dir)/types/_c.mk
exe_variant_suffix := _pie

# only one non-regular variant of a lib is supported: D - see $(lib_extra_variants) above
# $1 - D
# note: override defaults from $(cb_dir)/types/_c.mk
lib_variant_suffix := _pic

# determine which variant of static library to link to exe or dll
# $1 - target type: exe,dll
# $2 - variant of target exe or dll: R,P, if empty, then assume R
# $3 - dependency name, e.g. mylib or mylib/flag1/flag2/...
# use D-variant of static library for pie-exe or regular dll
# note: if returns empty value - then assume it's default variant R
# note: used by 'dep_library' macro from $(cb_dir)/types/c/c_base.mk
# note: override default implementation of 'lib_dep_map' from $(cb_dir)/types/_c.mk
lib_dep_map = $(if $(findstring dll,$1)$(findstring P,$2),D)

# get default C/C++ compiler flags
# $(is_tool_mode) - non-empty in tool mode, empty otherwise
def_cflags   = $(if $(is_tool_mode),$(CBLD_DEF_TCFLAGS),$(CBLD_DEF_CFLAGS))
def_cxxflags = $(if $(is_tool_mode),$(CBLD_DEF_TCXXFLAGS),$(CBLD_DEF_CXXFLAGS))

# only one non-regular variant of an exe is supported: P - see $(exe_extra_variants) above
# $1 - R or P
# $(is_tool_mode) - non-empty in tool mode, empty otherwise
# note: override defaults from $(cb_dir)/types/_c.mk
# note: called by trg_cflags/trg_cxxflags/trg_ldflags from $(cb_dir)/types/c/c_base.mk
exe_cflags   = $(if $(findstring P,$1),$(CBLD_PIC_COPTION)) $(def_cflags)
exe_cxxflags = $(if $(findstring P,$1),$(CBLD_PIC_COPTION)) $(def_cxxflags)
exe_ldflags  = $(if $(findstring P,$1),$(CBLD_PIE_LOPTION)) $(if $(is_tool_mode),$(CBLD_EXE_TLDFLAGS),$(CBLD_EXE_LDFLAGS))

# no non-regular variants of a dll are supported
# $1 - R
# $(is_tool_mode) - non-empty in tool mode, empty otherwise
# note: override defaults from $(cb_dir)/types/_c.mk
# note: called by trg_cflags/trg_cxxflags/trg_ldflags from $(cb_dir)/types/c/c_base.mk
dll_cflags   = $(def_cflags)
dll_cxxflags = $(def_cxxflags)
dll_ldflags  = $(if $(is_tool_mode),$(CBLD_DLL_TLDFLAGS),$(CBLD_DLL_LDFLAGS))

# only one non-regular variant of a lib is supported: D - see $(lib_extra_variants) above
# $1 - R or D
# note: override defaults from $(cb_dir)/types/_c.mk
# note: called by trg_cflags/trg_cxxflags/trg_ldflags from $(cb_dir)/types/c/c_base.mk
lib_cflags   = $(if $(findstring D,$1),$(CBLD_PIC_COPTION)) $(def_cflags)
lib_cxxflags = $(if $(findstring D,$1),$(CBLD_PIC_COPTION)) $(def_cxxflags)

# make linker command for linking an exe, dll or C++ lib
# target-specific: 'tm' - defined in exe_template/dll_template/lib_template macros from $(cb_dir)/types/_c.mk
# target-specific: 'compiler', 'cflags', 'cxxflags' - defined by 'c_base_template' in $(cb_dir)/types/c/c_base.mk
# note: user-defined CFLAGS/CXXFLAGS must be added after $(cflags)/$(cxxflags) be able to override them
# note: use C++ compiler instead of ld to create shared libraries - for calling C++ constructors of static objects when loading
#  the libraries, see https://docs.oracle.com/cd/E19205-01/819-5267/bkamq/index.html
# note: use C++ compiler instead of ar to create C++ static library archives - for adding necessary C++ templates to the archives,
#  see https://docs.oracle.com/cd/E19205-01/819-5267/bkamp/index.html
get_linker = $(if $(compiler:cxx=),$(if \
  $(tm),$(CBLD_TCC) $(cflags) $(CBLD_TCFLAGS),$(CC) $(cflags) $(CFLAGS)),$(if \
  $(tm),$(CBLD_TCXX) $(cxxflags) $(CBLD_TCXXFLAGS),$(CXX) $(cxxflags) $(CXXFLAGS)))

# option for specifying dynamic linker runtime search path for an exe or dll
# possibly (if defined via 'c_redefine') target-specific: 'rpath' - defined in $(cb_dir)/compilers/unixcc.mk
mk_rpath_option = $(addprefix -R,$(rpath))

# cc options to begin the list of static/dynamic libraries to link to the target
bstatic_option  := -Bstatic
bdynamic_option := -Bdynamic

# common linker options for exe or dll
# $1 - path to target exe or dll
# $2 - objects
# $3 - target type: exe or dll
# $4 - non-empty variant: R,P,D
# target-specific: 'tm', 'libs', 'dlls', 'lib_dir '- defined by exe_template/dll_template/lib_template in $(cb_dir)/types/_c.mk 
# target-specific: ldflagss/syslibs - defined by 'c_base_template' in $(cb_dir)/types/c/c_base.mk
# note: user-defined LDFLAGS must be added after $(ldflags) to be able to override them
# note: dep_lib_names/dep_imp_names - defined in $(cb_dir)/types/_c.mk
cmn_libs = $(mk_rpath_option) $(ldflags) $(if \
  $(tm),$(CBLD_TLDFLAGS),$(LDFLAGS)) -o $1 $2 $(if $(firstword \
  $(libs)$(dlls)),-L$(lib_dir) $(addprefix -l,$(call dep_imp_names,$3,$4)) $(if \
  $(libs),$(bstatic_option) $(addprefix -l,$(call dep_lib_names,$3,$4)) $(bdynamic_option))) $(syslibs)

# specify what symbols to export from a dll/exe
# target-specific: 'map' - defined by exe_aux_templv/dll_aux_templv macros in $(cb_dir)/compilers/unixcc.mk
mk_map_option = $(addprefix -M,$(map))

# append "soname" option if target shared library have a version info (e.g. some number after .so)
# $1 - full path to the target shared library, for ex. /aa/bb/cc/libmy_lib.so, if modver=1.2.3 then "soname" will be libmy_lib.so.1
# target-specific: 'modver' - defined by 'dll_aux_templv' macro in $(cb_dir)/compilers/unixcc.mk
mk_soname_option = $(addprefix -h $(notdir $1).,$(firstword $(subst ., ,$(modver))))

# linkers for each variant of exe,dll,lib
# $1 - path to the target exe,dll,lib
# $2 - objects for linking to the target
# $3 - target type: exe,dll,lib
# $4 - non-empty variant: R,P,D
# target-specific: 'tm' - defined in exe_template/dll_template/lib_template in $(cb_dir)/types/_c.mk
# target-specific: 'compiler' - defined in exe_template/dll_template/lib_template in $(cb_dir)/types/c/c_base.mk
# note: used by exe_template/dll_template/lib_template macros from $(cb_dir)/types/_c.mk
exe_ld = $(call suppress,$(tm)EXE,$1)$(get_linker) $(mk_map_option) $(cmn_libs)
dll_ld = $(call suppress,$(tm)DLL,$1)$(get_linker) $(mk_map_option) $(mk_soname_option) $(cmn_libs)
lib_ld = $(call suppress,$(tm)LIB,$1)$(if $(compiler:cxx=),$(if \
  $(tm),$(CBLD_TAR) $(CBLD_TARFLAGS),$(AR) $(ARFLAGS)),$(get_linker) $(if \
  $(tm),$(CBLD_TCXX_ARFLAGS),$(CBLD_CXX_ARFLAGS))) $1 $2

# parameters of application-level C and C++ compilers
# $1 - target object file
# $2 - source
# $3 - target type: exe,dll,lib
# $4 - non-empty variant: R,P,D
# target-specific: 'tm' - defined in exe_template/dll_template/lib_template in $(cb_dir)/types/_c.mk
# target-specific: 'defines', 'include', 'cflags', 'cxxflags' - defined by 'c_base_template' in $(cb_dir)/types/c/c_base.mk
# note: user-defined CFLAGS/CXXFLAGS must be added after cflags/cxxflags to be able to override them
cc_params  = $(defines) $(include) $(cflags) $(if $(tm),$(CBLD_TCFLAGS),$(CFLAGS)) -c -o $1 $2
cxx_params = $(defines) $(include) $(cxxflags) $(if $(tm),$(CBLD_TCXXFLAGS),$(CXXFLAGS)) -c -o $1 $2

# prefix of system headers to filter-out while dependencies generation
# note: used as $(SED) expression to match included system headers - see 'suncc_deps_script' macro in $(cb_dir)/compilers/suncc/cmn.mk
CBLD_UDEPS_FILTER := /usr/include/

# C/C++ compilers for each variant of exe,dll,lib
# $1 - target object file
# $2 - source
# $3 - target type: exe,dll,lib
# $4 - non-empty variant: R,P,D
# target-specific: 'tm' - defined in exe_template/dll_template/lib_template in $(cb_dir)/types/_c.mk
# note: called by 'obj_rules_templ' macro from $(cb_dir)/library/obj_rules.mk
# note: 'wrap_suncc' - defined in $(cb_dir)/compilers/suncc/cmn.mk
obj_cc  = $(call suppress,$(tm)CC,$2)$(call wrap_suncc,$(if $(tm),$(CBLD_TCC),$(CC)) $(cc_params),$1,$(CBLD_UDEPS_FILTER))
obj_cxx = $(call suppress,$(tm)CXX,$2)$(call wrap_suncc,$(if $(tm),$(CBLD_TCXX),$(CXX)) $(cxx_params),$1,$(CBLD_UDEPS_FILTER))

ifeq (,$(CBLD_NO_PCH))

# add support for precompiled headers

ifeq (,$(filter-out undefined environment,$(origin suncc_pch_templatet)))
include $(cb_dir)/compilers/suncc/pch.mk
endif

# define C/C++ compilers for compiling without using a precompiled header
$(eval obj_ncc  = $(value obj_cc))
$(eval obj_ncxx = $(value obj_cxx))

# define C/C++ compilers for compiling sources with a precompiled header
# $1 - target object file
# $2 - source
# $3 - target type: exe,dll,lib
# $4 - non-empty variant: R,P,D
# target-specific: 'tm' - defined in exe_template/dll_template/lib_template in $(cb_dir)/types/_c.mk
# target-specific: 'pch' - defined by 'pch_vars_templ' macro from $(cb_dir)/types/c/pch.mk
# target-specific: 'pch_gen_dir' - defined by 'suncc_pch_rule_templ' macro from $(cb_dir)/compilers/suncc/pch.mk
# note: sources like $(pch_gen_dir)$(notdir $2).cc are generated by 'suncc_pch_src_gen' macro from $(cb_dir)/compilers/suncc/pch.mk
obj_pcc  = $(call suppress,$(tm)PCC,$2)$(call wrap_suncc,$(if $(tm),$(CBLD_TCC),$(CC)) -xpch=use:$(dir $1)$(basename $(notdir \
  $(pch)))_c $(call cc_params,$1,$(pch_gen_dir)$(notdir $2).c,$3,$4),$1,$(CBLD_UDEPS_FILTER))
obj_pcxx = $(call suppress,$(tm)PCXX,$2)$(call wrap_suncc,$(if $(tm),$(CBLD_TCXX),$(CXX)) -xpch=use:$(dir $1)$(basename $(notdir \
  $(pch)))_cc $(call cc_params,$1,$(pch_gen_dir)$(notdir $2).cc,$3,$4),$1,$(CBLD_UDEPS_FILTER))

# override C/C++ compilers to support compiling sources with precompiled header
# $1 - target object file
# $2 - source
# $3 - target type: exe,dll,lib
# $4 - non-empty variant: R,P,D
# target-specific: 'cc_with_pch', 'cxx_with_pch' - defined by 'pch_vars_templ' macro from $(cb_dir)/types/c/pch.mk
obj_cc  = $(if $(filter $2,$(cc_with_pch)),$(obj_pcc),$(obj_ncc))
obj_cxx = $(if $(filter $2,$(cxx_with_pch)),$(obj_pcxx),$(obj_ncxx))

# compilers of C/C++ precompiled header
# $1 - target object of generated source $3:
#  /build/obj/xxx_pch_c.o or
#  /build/obj/xxx_pch_cc.o
# $2 - source pch header (full path, e.g. /src/include/xxx.h)
# $3 - generated source for precompiling header $2 (see 'suncc_pch_gen_templ' from $(cb_dir)/compilers/suncc/pch.mk):
#  $(pch_gen_dir)$(basename $(notdir $2))_pch.c or
#  $(pch_gen_dir)$(basename $(notdir $2))_pch.cc
# $4 - target type: exe,dll,lib
# $5 - non-empty variant: R,P,D
# target-specific: 'tm' - defined in exe_template/dll_template/lib_template in $(cb_dir)/types/_c.mk
# note: used by 'suncc_pch_rule_templ' macro from $(cb_dir)/compilers/suncc/pch.mk
pch_cc  = $(call suppress,$(tm)PCHCC,$2)$(call wrap_suncc,$(if $(tm),$(CBLD_TCC),$(CC)) -xpch=collect:$(dir $1)$(basename \
  $(notdir $2))_c $(call cc_params,$1,$3,$4,$5),$1,$(CBLD_UDEPS_FILTER))
pch_cxx = $(call suppress,$(tm)PCHCXX,$2)$(call wrap_suncc,$(if $(tm),$(CBLD_TCXX),$(CXX)) -xpch=collect:$(dir $1)$(basename \
  $(notdir $2))_cc $(call cxx_params,$1,$3,$4,$5),$1,$(CBLD_UDEPS_FILTER))

# reset additional makefile variables
# note: 'c_prepare_pch_vars' - defined in $(cb_dir)/types/c/pch.mk
$(call define_append,c_prepare_app_vars,$$(c_prepare_pch_vars))

# optimization: try to expand 'c_prepare_pch_vars' and redefine 'c_prepare_app_vars' as non-recursive variable
$(call try_make_simple,c_prepare_app_vars,c_prepare_pch_vars)

# for all application-level targets: add support for precompiled headers
# note: patch 'c_define_app_rules' macro - defined in $(cb_dir)/types/_c.mk
# note: 'c_app_targets' - defined in $(cb_dir)/types/_c.mk
$(call define_prepend,c_define_app_rules,$$(eval $$(foreach t,$(c_app_targets),$$(if $$($$t),$$(suncc_pch_templatet)))))

endif # !CBLD_NO_PCH

# remember values the variables possibly defined in the environment
$(call config_remember_vars,CBLD_CPU_CFLAGS CBLD_TCPU_CFLAGS CC CXX AR CFLAGS CXXFLAGS ARFLAGS CBLD_CXX_ARFLAGS LDFLAGS \
  CBLD_CMN_CFLAGS CBLD_DEF_CFLAGS CBLD_DEF_CXXFLAGS CBLD_CMN_LDFLAGS CBLD_EXE_LDFLAGS CBLD_DLL_LDFLAGS CBLD_TCC CBLD_TCXX CBLD_TAR \
  CBLD_TCFLAGS CBLD_TCXXFLAGS CBLD_TARFLAGS CBLD_TCXX_ARFLAGS CBLD_TLDFLAGS CBLD_CMN_TCFLAGS CBLD_DEF_TCFLAGS CBLD_DEF_TCXXFLAGS \
  CBLD_CMN_TLDFLAGS CBLD_EXE_TLDFLAGS CBLD_DLL_TLDFLAGS CBLD_PIC_COPTION CBLD_PIE_LOPTION CBLD_UDEPS_FILTER)

# makefile parsing first phase variables
cb_first_phase_vars += def_cflags def_cxxflags

# protect variables from modifications in target makefiles
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,CBLD_CPU_CFLAGS CBLD_TCPU_CFLAGS CC CXX AR CFLAGS CXXFLAGS ARFLAGS CBLD_CXX_ARFLAGS LDFLAGS \
  CBLD_CMN_CFLAGS CBLD_DEF_CFLAGS CBLD_DEF_CXXFLAGS CBLD_CMN_LDFLAGS CBLD_EXE_LDFLAGS CBLD_DLL_LDFLAGS CBLD_TCC CBLD_TCXX CBLD_TAR \
  CBLD_TCFLAGS CBLD_TCXXFLAGS CBLD_TARFLAGS CBLD_TCXX_ARFLAGS CBLD_TLDFLAGS CBLD_CMN_TCFLAGS CBLD_DEF_TCFLAGS CBLD_DEF_TCXXFLAGS \
  CBLD_CMN_TLDFLAGS CBLD_EXE_TLDFLAGS CBLD_DLL_TLDFLAGS CBLD_PIC_COPTION CBLD_PIE_LOPTION CBLD_UDEPS_FILTER cb_first_phase_vars)

# protect variables from modifications in target makefiles
# note: trace namespace: suncc
$(call set_global,def_cflags def_cxxflags get_linker mk_rpath_option bstatic_option bdynamic_option cmn_libs mk_map_option \
  mk_soname_option exe_ld dll_ld lib_ld cc_params cxx_params obj_cc obj_cxx obj_ncc obj_ncxx obj_pcc obj_pcxx pch_cc pch_cxx,suncc)
