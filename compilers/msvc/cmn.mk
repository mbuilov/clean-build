#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# common msvc compiler definitions, included by $(cb_dir)/compilers/msvc.mk

# Microsoft Visual C++ (MSVC++) product versions
#---------------------------------------------------------------------------------
# MSVC++ _MSC_VER    product name      C++ compiler default installation path
#---------------------------------------------------------------------------------
#  6.0     1200   Visual Studio 6.0    Microsoft Visual Studio\VC98\Bin\cl.exe
#  7.0     1300   Visual Studio 2002   Microsoft Visual Studio .NET\VC7\bin\cl.exe
#  7.1     1310   Visual Studio 2003   Microsoft Visual Studio .NET 2003\VC7\bin\cl.exe
#  8.0     1400   Visual Studio 2005   Microsoft Visual Studio 8\VC\bin\cl.exe
#  9.0     1500   Visual Studio 2008   Microsoft Visual Studio 9.0\VC\bin\cl.exe
#  10.0    1600   Visual Studio 2010   Microsoft Visual Studio 10.0\VC\bin\cl.exe
#  11.0    1700   Visual Studio 2012   Microsoft Visual Studio 11.0\VC\bin\cl.exe
#  12.0    1800   Visual Studio 2013   Microsoft Visual Studio 12.0\VC\bin\cl.exe
#  14.0    1900   Visual Studio 2015   Microsoft Visual Studio 14.0\VC\bin\cl.exe
#  14.10   1910   Visual Studio 2017   Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.10.25017\bin\HostX86\x86\cl.exe
#  14.11   1911   Visual Studio 2017   Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX86\x86\cl.exe

# map Visual Studio abbreviated product name -> MSVC++ product version
vs2002 := 7
vs2003 := 7.1
vs2005 := 8
vs2008 := 9
vs2010 := 10
vs2012 := 11
vs2013 := 12
vs2015 := 14
vs2017 := 14.1

# map _MSC_VER (C++ compiler version) major number -> MSVC++ product version major number
msc_ver_12 := 6
msc_ver_13 := 7
msc_ver_14 := 8
msc_ver_15 := 9
msc_ver_16 := 10
msc_ver_17 := 11
msc_ver_18 := 12
msc_ver_19 := 14

# Creating a process on Windows costs more time than on Unix, so it takes more total time to call compiler for each source
#  individually over than compiling multiple sources at once - where compiler internally schedules the compilation by cloning
#  itself and working in service mode, also compiler internally may parallelize compilation depending on available CPUs.

# run via $(MAKE) S=1 to compile each source individually
ifeq (command line,$(origin S))
seq_build := $(S:0=)
else
# compile all sources of a module at once by default (with /MP option)
seq_build:=
endif

# Windows tools, such as rc.exe, mc.exe, cl.exe, link.exe, produce excessive output in stdout,
#  by default, try to filter this output out by wrapping calls to the tools. Also, wrapping is
#  required for source dependencies auto-generation.
# If not empty and not 0, then do not wrap tools
CBLD_NO_WRAP_MSVC_TOOLS ?=

# for use in ifdefs
no_wrap_msvc_tools := $(CBLD_NO_WRAP_MSVC_TOOLS:0=)

# include patterns for filtering excessive output of msvc++ tools
ifndef no_wrap_msvc_tools
ifneq (,$(filter /%,$(CURDIR)))
$(error TODO: wrapping of MSVC tools with Unix shell utilities is not implemented yet. \
  For now, please use cmd.exe shell utilities - start build with CBLD_UTILS=cmd or define CBLD_NO_WRAP_MSVC_TOOLS=1)
endif
ifeq (,$(filter-out undefined environment,$(origin linker_strip_strings_en)))
include $(dir $(lastword $(MAKEFILE_LIST)))patterns.mk
endif
endif

# code to define linker wrapper macro (for stripping outout of link.exe)
define msvc_wrap_linker_templ

# call linker and strip-off diagnostic message and message about generated .exp-file
# $1 - linker with options
# note: send output to stderr in verbose mode, this is needed for build script generation
ifdef verbose
<wrap_linker> = $1 >&2
else
<wrap_linker> = $1
endif

# $1 - linker with options
# target-specific: 'imp' (may be empty) - defined by mod_exports_template/no_exports_template from $(cb_dir)/compilers/msvc/exp.mk
# note: no diagnostic message is printed in debug build, so ignore <strip_expr>
# note: 'cmd_filter_output' - sends command output to stderr, defined in $(cb_dir)/utils/cmd.mk
ifndef no_wrap_msvc_tools
$(eval <wrap_linker> = $$(if $$(imp),$$(call \
  cmd_filter_output,$$1,|$(FIND) /V "$$(basename $$(notdir $$(imp))).exp"),$(value <wrap_linker>)))
ifndef debug
ifneq (,<strip_expr>)
<wrap_linker> = $(call cmd_filter_output,$1,<strip_expr>$(patsubst %, |$(FIND) /V "%.exp",$(basename $(notdir $(imp)))))
endif
endif
endif

endef

# define the linker wrapper (for stripping outout of link.exe)
# $1 - linker wrapper name, e.g. 'wrap_linker'
# $2 - strings to strip-off from link.exe output, e.g. $(linker_strip_strings_en)
msvc_define_linker_wrapper = $(eval $(subst <wrap_linker>,$1,$(subst \
  <strip_expr>,$(call qpath,$2,|$(FINDSTR) /VBRC:),$(value msvc_wrap_linker_templ))))

# $(SED) script used to auto-generate dependencies file from the output of cl.exe
# $1 - compiler with options (unused)
# $2 - path to the source, e.g. C:\project\src\src.c
# $3 - target object file, e.g. C:\build\obj\src.obj
# $4 - included header file search pattern, e.g. $(cl_including_file_pattern_en)
# $5 - prefixes of system includes to filter out, e.g. $(CBLD_DEPS_INCLUDE_FILTER)
#
# s/\x0d//;                                       - fix line endings - remove carriage-return (CR)
# /^$(notdir $2)$$/d;                             - delete compiled source file name printed by cl.exe, start new circle
# /^$4 /!{p;d;}                                   - print all lines not started with $4 pattern and a space, start new circle
# s/^$4 *//;                                      - strip-off leading $4 pattern with spaces
# $(subst ?, ,$(foreach x,$5,\@^$x.*@Id;))        - delete lines started with system include paths, start new circle
# s/ /\\ /g;                                      - escape spaces in included file path
# s@.*@&:\n$3: &@;w $(basename $3)$(c_dep_suffix) - make dependencies, then write to generated dep-file (e.g. C:\build\obj\src.d)
#
msvc_deps_script = \
-e "s/\x0d//;/^$(notdir $2)$$/d;/^$4 /!{p;d;}" \
-e "s/^$4 *//;$(subst ?, ,$(foreach x,$5,\@^$x.*@Id;))s/ /\\ /g;s@.*@&:\n$3: &@;w $(basename $3)$(c_dep_suffix)"

# code to define compiler wrapper macros (for calling cl.exe with and without dependencies auto-generation)
# note: 'cmd_filter_output' - defined in $(cb_dir)/utils/cmd.mk
# note: 'c_dep_suffix' - defined in $(cb_dir)/types/c/c_base.mk
define msvc_wrap_complier_templ

# just strip-off names of compiled sources
# $1 - compiler with options
# $2 - path(s) to the source(s) (non-empty)
# note: 'cmd_filter_output' sends command output to stderr
# note: send output to stderr in verbose mode, this is needed for build script generation
ifndef no_wrap_msvc_tools
<wrap_cc_nodep> = $(call cmd_filter_output,$1,$(addprefix |$(FINDSTR) /VXC:,$(notdir $2)))
else ifdef verbose
<wrap_cc_nodep> = $1 >&2
else
<wrap_cc_nodep> = $1
endif

# if 'no_wrap_msvc_tools' is set, do not auto-generate dependencies
$(eval <wrap_cc_dep> = $(value <wrap_cc_nodep>))

# call compiler and auto-generate dependencies
# $1 - compiler with options
# $2 - path to the source
# $3 - target object file
# note: send output to stderr in verbose mode, this is needed for build script generation
# note: may auto-generate dependencies only if building sources sequentially, because /showIncludes option conflicts with /MP
ifndef no_wrap_msvc_tools
ifdef c_dep_suffix
<wrap_cc_dep> = (($1 /showIncludes 2>&1 && set/p"=C">&2<NUL)|$(SED) -n $(call \
  msvc_deps_script,$1,$2,$3,<incl_pattern>,<deps_filter>) 2>&1 && set/p"=S">&2<NUL)3>&2 2>&1 1>&3|$(FINDSTR) /XC:CS>NUL
endif
endif

endef

# define compiler wrappers (for calling cl.exe with and without dependencies auto-generation)
# $1 - no-dep compiler wrapper name, e.g. 'wrap_ccn'
# $2 - dep compiler no-dep wrapper name, e.g. 'wrap_ccd'
# $3 - regular expression used to match paths to included headers, e.g. $(cl_including_file_pattern_en)
# $4 - prefixes of system include paths to filter-out, e.g. $(CBLD_DEPS_INCLUDE_FILTER)
msvc_define_compiler_wrappers = $(eval $(subst <wrap_cc_nodep>,$1,$(subst <wrap_cc_dep>,$2,$(subst \
  <incl_pattern>,$3,$(subst <deps_filter>,$4,$(value msvc_wrap_complier_templ))))))

# make version string for the link.exe: major.minor.patch -> major.minor, e.g.:
#  1.2.3 -> 1.2
#  1.2   -> 1.2
#  1     -> 1.0
#        -> 0.0
# target-specific: 'modver' - defined by 'exe_dll_aux_template' from $(cb_dir)/compilers/msvc.mk
modver_major_minor = $(subst $(space),.,$(wordlist 1,2,$(subst ., ,$(modver)) 0 0))

# make linker option that sets module version, for exe,dll,drv,kdll...
mk_version_option = /VERSION:$(modver_major_minor)

# make compiler options string to specify search path of included headers
# note: assume there are no spaces in include paths
# note: override default implementation from $(cb_dir)/types/c/c_base.mk
mk_include_option = $(addprefix /I,$(ospath))

# make compiler options string to pass C-macro definitions to the C/C++ compiler
# note: override default implementation from $(cb_dir)/types/c/c_base.mk
mk_defines_option1 = $(addprefix /D,$1)

# for the multi-source build, when all sources of a module are compiled at once - a target exe,dll,lib... will depend on sources instead
#  of objects, so add source-file dependencies for the target, together with the dependencies of the sources (result of 'all_sdeps'),
#  define target-specific variables: 'src', 'sdeps'
# parameters are the same as for 'c_base_template' from $(cb_dir)/types/c/c_base.mk:
# $1 - target file: $(call form_trg,$t,$v)
# $2 - sources:     $(trg_src)
# $3 - sdeps:       $(trg_sdeps)
# $4 - objdir:      $(call form_obj_dir,$t,$v)
# $t - target type: exe,dll,lib...
# $v - non-empty variant: R,P,D,S... (one of variants supported by the selected toolchain)
# note: 'all_sdeps' - defined in $(cb_dir)/library/sdeps.mk
# note: intermediate objects are will be created in objdir $4, so create it before the target creation
define mp_target_src_deps
$1: src := $2
$1: sdeps := $3
$1: $2 $(sort $(call all_sdeps,$3)) | $4
endef

# define 'c_base_template_mp' - it will have the same value as 'c_base_template', but without calls to 'obj_rules' for C/C++ sources,
#  and with $(mp_target_src_deps) at last line
# note: 'obj_rules' - macro defined in $(cb_dir)/library/obj_rules.mk, defines rules for building objects from individual sources
# note: 'c_base_template' - defined in $(cb_dir)/types/c/c_base.mk
$(eval define c_base_template_mp$(newline)$(call tospaces,$(subst $(space),$$(newline),$(strip $(foreach l,$(subst $(newline), ,$(call \
  unspaces,$(value c_base_template))),$(if $(findstring obj_rules,$l),,$l)))))$(newline)$$(mp_target_src_deps)$(newline)endef)

# get list of sources newer than the target (exe,dll,lib...)
# target-specific: 'src', 'sdeps' - defined by 'mp_target_src_deps' template
# note: assume called in context of a rule creating target exe,dll,lib... (by the linker command, such as exe_ld,dll_ld,lib_ld...)
# note: assume 'c_base_template_mp' was used for the target exe,dll,lib.., so target-specific variables 'src' and 'sdeps' are defined
# note: 'r_filter_sdeps' - defined in $(cb_dir)/library/sdeps.mk
newer_sources = $(sort $(filter $(src),$? $(call r_filter_sdeps,$?,$(sdeps))))

# It is possible to exceed maximum command string length if compiling too many sources at once, to prevent this, split
#  all sources of a module to groups, then compile groups sequentially - one after each other.
# Maximum number of sources in a group compiled at once, by default set to $(CBLD_MAX_PATH_ARGS) from $(cb_dir)/utils/cmd.mk
CBLD_MCL_MAX_PATH_ARGS ?= $(CBLD_MAX_PATH_ARGS)

# form commands to compile multiple sources at once
# $1 - target type: exe,dll,lib...
# $2 - non-empty variant: R,S,RU,SU...
# $3 - C compiler macro, e.g. 'obj_mcc'
# $4 - C++ compiler macro, e.g. 'obj_mcxx'
# note: compiler macros are called with parameters:
#  $1 - sources (non-empty list)
#  $2 - target type: exe,dll,lib...
#  $3 - non-empty variant: R,S,RU,SU...
cmn_mcl = $(call cmn_mcl1,$1,$2,$3,$4,$(newer_sources))

# form commands to compile multiple sources at once
# $1 - target type: exe,dll,lib...
# $2 - non-empty variant: R,S,RU,SU...
# $3 - C compiler macro, e.g. 'obj_mcc'
# $4 - C++ compiler macro, e.g. 'obj_mcxx'
# $5 - sources (result of $(newer_sources)), list may be empty
# note: 'cc_mask' and 'cxx_mask' - defined in $(cb_dir)/types/c/c_base.mk
# note: this macro is also used by 'cmn_pmcl2' macro from $(cb_dir)/compilers/msvc/pch.mk
cmn_mcl1 = $(call cmn_mcl2,$1,$2,$3,$4,$(filter $(cc_mask),$5),$(filter $(cxx_mask),$5))

# form commands to compile multiple sources at once
# $1 - target type: exe,dll,lib...
# $2 - non-empty variant: R,S,RU,SU...
# $3 - C compiler macro, e.g. 'obj_mcc' or 'obj_pmcc'
# $4 - C++ compiler macro, e.g. 'obj_mcxx' or 'obj_pmcxx'
# $5 - C sources (list may be empty)
# $6 - C++ sources (list may be empty)
# note: this macro is also used by 'cmn_pmcl2' macro from $(cb_dir)/compilers/msvc/pch.mk
cmn_mcl2 = $(if \
  $5,$(call xcmd,$3,$5,$(CBLD_MCL_MAX_PATH_ARGS),$1,$2)$(newline))$(if \
  $6,$(call xcmd,$4,$6,$(CBLD_MCL_MAX_PATH_ARGS),$1,$2)$(newline))

# remember values of variables possibly taken from the environment
$(call config_remember_vars,CBLD_NO_WRAP_MSVC_TOOLS CBLD_MCL_MAX_PATH_ARGS)

# makefile parsing first phase variables
cb_first_phase_vars += msvc_wrap_linker_templ msvc_define_linker_wrapper msvc_deps_script msvc_wrap_complier_templ \
  msvc_define_compiler_wrappers mp_target_src_deps c_base_template_mp

# protect variables from modifications in target makefiles
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,seq_build CBLD_NO_WRAP_MSVC_TOOLS no_wrap_msvc_tools CBLD_MCL_MAX_PATH_ARGS cb_first_phase_vars)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: msvc
$(call set_global,vs2002 vs2003 vs2005 vs2008 vs2010 vs2012 vs2013 vs2015 vs2017 \
  msc_ver_12 msc_ver_13 msc_ver_14 msc_ver_15 msc_ver_16 msc_ver_17 msc_ver_18 msc_ver_19 \
  msvc_wrap_linker_templ msvc_define_linker_wrapper msvc_deps_script msvc_wrap_complier_templ msvc_define_compiler_wrappers \
  modver_major_minor mk_version_option mk_include_option mk_defines_option1 mp_target_src_deps c_base_template_mp \
  newer_sources cmn_mcl cmn_mcl1 cmn_mcl2,msvc)
