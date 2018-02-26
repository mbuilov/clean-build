#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# support for compiling assembler sources for the C/C++ targets

# assembler sources mask
asm_mask := %.asm

# assembler flags for the target
# $t - target type: exe,dll,lib...
# $v - non-empty variant: R,P,D,S... (one of variants supported by the selected toolchain)
# note: returned flags should include (at end) value of target makefile-defined 'asmflags' variable
trg_asmflags = $(call $t_asmflags,$v) $(asmflags)

# template for adding assembler support
# $1 - target file: $(call form_trg,$t,$v)
# $2 - sources:     $(trg_src)
# $3 - sdeps:       $(trg_sdeps)
# $4 - objdir:      $(call form_obj_dir,$t,$v)
# $t - target type: exe,dll,lib...
# $v - non-empty variant: R,P,D,S... (one of variants supported by the selected toolchain)
# note: no support for auto-dependencies generation for assembler sources
# note: object compiler 'obj_asm' must be defined in the assembler-specific makefile
define asm_template
$1:$(call obj_rules,obj_asm,$(filter $(asm_mask),$2),$3,$4,$(obj_suffix),$t$(comma)$v)
$1:asmflags := $(trg_asmflags)
endef

# assembler color
CBLD_ASM_COLOR ?= [37m

# patch 'c_base_template' so all $(c_target_types) will be able to compile assembler sources
$(call define_append,c_base_template,$(newline)$(value asm_template))

# makefile parsing first phase variables
cb_first_phase_vars += trg_asmflags asm_template

# protect variables from modifications in target makefiles
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,CBLD_ASM_COLOR)

# protect variables from modifications in target makefiles
# note: trace namespace: c_asm
$(call set_global,asm_mask trg_asmflags=t;v asm_template,c_asm)
