#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# support for compiling assembler sources for the C/C++ targets

# Assembler sources mask
ASM_MASK := %.asm

# user-defined assembler flags,
#  normally taken from the environment (in project configuration makefile)
# note: assume assembler is not used in tool mode
ASMFLAGS:=

# assembler flags for the target
# $t - target type: EXE,DLL,LIB...
# $v - non-empty variant: R,P,D,S... (one of variants supported by selected toolchain)
# note: these flags should contain value of ASMFLAGS - standard user-defined assembler flags,
#  that are normally taken from the environment (in project configuration makefile),
#  their default values should be set in assembler-specific makefile, e.g.: $(CLEAN_BUILD_DIR)/compilers/nasm.mk.
TRG_ASMFLAGS = $($t_ASMFLAGS)

# template for adding assembler support
# $1 - target file: $(call FORM_TRG,$t,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,$t,$v)
# $t - target type: EXE,DLL,LIB...
# $v - non-empty variant: R,P,D,S... (one of variants supported by selected toolchain)
define ASM_TEMPLATE
$1:$(call OBJ_RULES,ASM,$(filter $(ASM_MASK),$2),$3,$4,$(OBJ_SUFFIX))
$1:VASMFLAGS := $(TRG_ASMFLAGS)
endef

# tool color
ASM_COLOR := [37m

# patch C_BASE_TEMPLATE so all $(C_TARGETS) will be able to compile assembler sources
$(call define_append,C_BASE_TEMPLATE,$(newline)$(value ASM_TEMPLATE))

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,ASM_MASK ASMFLAGS TRG_ASMFLAGS=t;v ASM_TEMPLATE ASM_COLOR)
