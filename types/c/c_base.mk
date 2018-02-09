#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# generic rules for compiling C/C++/Assembler source files

# included by:
#  $(cb_dir)/types/_c.mk
#  $(cb_dir)/types/_kc.mk

# include support for compiling objects from sources
ifeq (,$(filter-out undefined environment,$(origin obj_rules)))
include $(cb_dir)/library/obj_rules.mk
endif

# include support for target variants
ifeq (,$(filter-out undefined environment,$(origin get_variants)))
include $(cb_dir)/library/variants.mk
endif

# list of target types (exe,lib,...) that may be built from C/C++/Assembler sources
# note: appended in:
#  $(cb_dir)/types/_c.mk
#  $(cb_dir)/types/_kc.mk
c_target_types:=

# by default, use C/C++ precompiled headers only in release builds
# note: 'debug' - defined in $(cb_dir)/core/_defs.mk
CBLD_NO_PCH ?= $(debug)

# object file suffix
# note: may overridden by the selected C/C++ compiler - e.g. in included next $(c_compiler_mk)
obj_suffix := .o

# suffix of compiler-generated dependencies of the sources, empty if dependences generation is disabled
# note: CBLD_NO_DEPS - defined in $(cb_dir)/code/_defs.mk
c_dep_suffix := $(if $(CBLD_NO_DEPS),,.d)

# C/C++ sources masks
cc_mask  := %.c
cxx_mask := %.cpp

# code to be called at the beginning of the target makefile
# $(modver) - module version (for dll, exe or driver) in form major.minor.patch (for example 1.2.3)
# note: 'product_version' - defined in $(cb_dir)/core/_defs.mk, but generally redefined in project configuration makefile
# note: 'syslibs' - used to specify external (system) libraries, e.g. -L/opt/lib -lext
# note: may define 'src', 'include', 'defines', etc. as recursive variables and use $t (target type) and $v (variant), e.g.:
#  src = $(if $(filter exe,$t),exe_src.c) comn_src.c
define c_prepare_base_vars
modver:=$(product_version)
src:=
with_pch:=
sdeps:=
include:=
defines:=
cflags:=
cxxflags:=
ldflags:=
syslibs:=
libs:=
dlls:=
endef

# optimization: try to expand 'product_version' and redefine 'c_prepare_base_vars' as non-recursive variable
$(call try_make_simple,c_prepare_base_vars,product_version)

# form the name of dependent library for given variant of the target
# $1 - target type: exe,dll,...
# $2 - variant of the target exe,dll,...: R,P,S,... (if empty, assume R)
# $3 - dependency name, e.g. mylib or with flags: mylib/flag1/flag2/...
# $4 - dependency type: lib,dll,...
# note: this macro is used by dep_libs/dep_imps macros from $(cb_dir)/types/_c.mk
# example:
#  always use D-variant of static library if target is a dll,
#  else use the same variant (R or P) of static library as target (exe) (for example for P-exe use P-lib)
#  lib_dep_map = $(if $(filter dll,$1),D,$2)
dep_library = $(firstword $(subst /, ,$3))$(call variant_suffix,$4,$($4_dep_map))

# select compiler type to use for the target: cxx or cc?
# note: cxx compiler may compile C sources, but also links standard C++ libraries (like libstdc++)
# $1 - target file: $(call form_trg,$t,$v)
# $2 - sources: $(trg_src)
# $t - target type: exe,lib,dll,drv,klib,kdll,...
# $v - non-empty variant: R,P,D,S... (one of variants supported by the selected toolchain)
trg_compiler = $(if $(filter $(cxx_mask),$2),cxx,cc)

# make absolute paths to include directories - we need absolute paths to headers in generated .d dependency files
# $t - target type: exe,lib,dll,drv,klib,kdll,...
# $v - non-empty variant: R,P,D,S... (one of variants supported by the selected toolchain)
# note: assume 'include' paths do not contain spaces
trg_include = $(call fixpath,$(include))

# C-defines for the target
# $t - target type: exe,lib,dll,drv,klib,kdll,...
# $v - non-empty variant: R,P,D,S... (one of variants supported by the selected toolchain)
# note: this macro may be overridden in the project configuration makefile, for example:
# trg_defines = $(if $(debug),,NDEBUG) TARGET_$(CBLD_TARGET:D=) $(foreach \
#   cpu,$(if $(filter drv klib kdll,$t),$(CBLD_KCPU),$(if $(is_tool_mode),$(CBLD_TCPU),$(CBLD_CPU))),$(if \
#   $(filter sparc% mips% ppc%,$(cpu)),B_ENDIAN,L_ENDIAN) $(if \
#   $(filter arm% sparc% mips% ppc%,$(cpu)),ADDRESS_NEEDALIGN)) $(defines)
trg_defines = $(defines)

# make list of sources for the target, used by 'trg_src' macro
c_get_sources = $(src) $(with_pch)

# make absolute paths to sources - we need absolute path to source in generated .d dependency file
trg_src = $(call fixpath,$(c_get_sources))

# make absolute paths to source dependencies
trg_sdeps = $(call fix_sdeps,$(sdeps))

# make compiler options string to specify search path of included headers
# note: assume there are no spaces in include paths
# note: 'mk_include_option' macro is overridden in $(cb_dir)/compilers/msvc/cmn.mk
mk_include_option = $(addprefix -I,$1)

# helper macro for passing C-define value containing special symbols (e.g. quoted string) to the C/C++ compiler
# result of this macro will be processed by 'c_define_escape_value' macro
# example: defines := MY_MESSAGE=$(call c_define_special,"my message")
c_define_special = $(unspaces)

# process result of 'c_define_special' to make shell-escaped value of C-define for passing it to the C/C++ compiler
# $1 - define_name     (the name of C-macro definition)
# $d - $1="1$(space)2" (for example)
# returns: define_name='"1 2"'
c_define_escape_value = $1=$(call shell_escape,$(call tospaces,$(patsubst $1=%,%,$d)))

# process result of 'c_define_special' to make shell-escaped values of C-defines for passing them to the C/C++ compiler
# $1 - list of defines in form name1=value1 name2=value2 ...
# example: -DA=1 -DB="b" -DC="1$(space)2"
# returns: -DA=1 -DB='"b"' -DC='"1 2"'
c_define_escape_values = $(foreach d,$1,$(call c_define_escape_value,$(firstword $(subst =, ,$d))))

# make compiler options string to pass C-macro definitions to the C/C++ compiler
# note: 'mk_defines_option1' macro is overridden in $(cb_dir)/compilers/msvc/cmn.mk
mk_defines_option1 = $(addprefix -D,$1)
mk_defines_option = $(call c_define_escape_values,$(mk_defines_option1))

# C/C++ compiler and linker flags for the target
# $t - target type: exe,lib,dll,drv,klib,kdll,...
# $v - non-empty variant: R,P,D,S... (one of variants supported by the selected toolchain)
# note: returned flags should include (at end) values of target makefile-defined 'cflags', 'cxxflags' and 'ldflags' variables
trg_cflags   = $(call $t_cflags,$v) $(cflags)
trg_cxxflags = $(call $t_cxxflags,$v) $(cxxflags)
trg_ldflags  = $(call $t_ldflags,$v) $(ldflags)

# base template for C/C++ targets
# $1 - target file: $(call form_trg,$t,$v)
# $2 - sources:     $(trg_src)
# $3 - sdeps:       $(trg_sdeps)
# $4 - objdir:      $(call form_obj_dir,$t,$v)
# $t - target type: exe,dll,lib...
# $v - non-empty variant: R,P,D,S... (one of variants supported by the selected toolchain)
# note: object compilers 'obj_cc' and 'obj_cxx' must be defined in the compiler-specific makefile (e.g. $(cb_dir)/compilers/gcc.mk)
# note: define target-specific variable 'trg' - an unique namespace name, for use by 'c_redefine' macro (see below)
# note: 'std_target_vars' also changes 'cb_needed_dirs', so do not remember its new value here
define c_base_template
$1:trg := $(notdir $4)
cb_needed_dirs+=$4
$(std_target_vars)
$1:$(call obj_rules,obj_cc,$(filter $(cc_mask),$2),$3,$4,$(obj_suffix),$t$(comma)$v,$(c_dep_suffix))
$1:$(call obj_rules,obj_cxx,$(filter $(cxx_mask),$2),$3,$4,$(obj_suffix),$t$(comma)$v,$(c_dep_suffix))
$1:compiler := $(trg_compiler)
$1:include  := $(call mk_include_option,$(trg_include))
$1:defines  := $(call mk_defines_option,$(trg_defines))
$1:cflags   := $(trg_cflags)
$1:cxxflags := $(trg_cxxflags)
$1:ldflags  := $(trg_ldflags)
endef

# $1 - $(call form_trg,$t,$v)
# $2 - $(trg_src)
# $3 - $(trg_sdeps)
# $4 - $(call form_obj_dir,$t,$v)
# $t - exe,dll,...
# $v - non-empty variant: R,P,D,S... (one of variants supported by the selected toolchain)
# note: $t_template includes $(c_base_template)
c_rules_templv = $($t_template)

# $1 - $(trg_src)
# $2 - $(trg_sdeps)
# $t - exe,dll,...
c_rules_templt = $(foreach v,$(call get_variants,$t),$(call \
  c_rules_templv,$(call form_trg,$t,$v),$1,$2,$(call form_obj_dir,$t,$v))$(newline))

# check if any supported C target type is defined: exe,dll,lib,...
# and expand target rules template $t_template, for example - see 'exe_template'
# $1 - $(trg_src)
# $2 - $(trg_sdeps)
c_rules_templ = $(foreach t,$(c_target_types),$(if $($t),$(c_rules_templt)))

# this code is normally evaluated at end of target makefile
c_define_rules = $(call c_rules_templ,$(trg_src),$(trg_sdeps))

# get value of 'trg' key variable defined by 'c_base_template' (expanded in current target makefile)
# $1 - exe,dll,...
# $2 - non-empty variant: R,P,D,S... (one of variants supported by the selected toolchain)
trg_key_current_value = $(notdir $(form_obj_dir))

# For the target type $1: redefine macro $2 with new value $3 as target-specific variable bound to namespace identified by
#  target-specific variable 'trg'.
# This is usable when it's needed to redefine some variable (e.g. 'def_cflags') as target-specific (e.g. for an exe) to allow
#  inheritance of that variable to dependent objects (of exe), but preventing its inheritance to dependent dlls and their objects.
# note: target-specific variable 'trg', those value is used as a namespace name, is defined by 'c_base_template' (see above)
# example: $(call c_redefine,exe,def_cflags,-Wall)
c_redefine = $(foreach v,$(get_variants),$(eval \
  $(call form_trg,$1,$v): $$(call keyed_redefine,$$2,trg,$(call trg_key_current_value,$1,$v),$$3)))

# do not support compiling assembler sources by default
# note: 'c_asm_supported' may be overridden in project configuration makefile, which must also define 
# note: if 'c_asm_supported' is defined, then must also be defined different assemblers, which are called from $(obj_rules_templ):
#  exe_R_asm, lib_R_asm, lib_D_asm, etc. - for all supported target variants
c_asm_supported:=

ifdef c_asm_supported
# note: this will patch 'c_base_template' - by adding support for compiling assembler sources
include $(cb_dir)/types/c/c_asm.mk
endif

# remember value of CBLD_NO_PCH - it may be taken from the environment
$(call config_remember_vars,CBLD_NO_PCH)

# makefile parsing first phase variables
cb_first_phase_vars += c_prepare_base_vars trg_compiler trg_include trg_defines c_get_sources trg_src trg_sdeps \
  trg_cflags trg_cxxflags trg_ldflags c_base_template c_rules_templv c_rules_templt c_rules_templ c_define_rules \
  trg_key_current_value c_redefine

# protect variables from modifications in target makefiles
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,CBLD_NO_PCH c_asm_supported cb_first_phase_vars)

# protect variables from modifications in target makefiles
# note: trace namespace: c_base
$(call set_global,c_target_types obj_suffix c_dep_suffix cc_mask cxx_mask c_prepare_base_vars dep_library \
  trg_compiler=t;v trg_include=t;v;include trg_defines=t;v;defines c_get_sources=src;with_pch trg_src trg_sdeps=sdeps \
  mk_include_option c_define_special c_define_escape_value c_define_escape_values mk_defines_option1 mk_defines_option \
  trg_cflags=t;v trg_cxxflags=t;v trg_ldflags=t;v c_base_template=t;v;$$t \
  c_rules_templv=t;v c_rules_templt=t c_rules_templ c_define_rules trg_key_current_value c_redefine,c_base)

# KCC_COLOR  := [31m
# KCXX_COLOR := [36m
# KAR_COLOR  := [32m
# KLD_COLOR  := [33m
# KXLD_COLOR := [37m
