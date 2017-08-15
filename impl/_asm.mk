#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# add support for compiling assembler sources

# included by $(CLEAN_BUILD_DIR)/impl/_c.mk if ASM_COMPLER is defined

ifeq (,$(wildcard $(ASM_COMPILER)))
$(error file $(ASM_COMPILER) was not found, check value of ASM_COMPILER variable)
endif

# target assembler flags
# $t     - EXE,LIB,DLL,DRV,KLIB,KDLL,...
# $v     - non-empty variant: R,P,S,...
# $(TMD) - T in tool mode, empty otherwise
TRG_ASMFLAGS = $(ASMFLAGS)

# template for adding assembler support
# $1 - target file: $(call FORM_TRG,$t,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,$t,$v)
# $t - EXE,DLL,LIB...
# $v - non-empty variant: R,P,S,...
define ASM_TEMPLATE
$1:$(call OBJ_RULES,ASM,$(filter %.asm,$2),$3,$4)
$1:ASMFLAGS := $(TRG_ASMFLAGS)
endef

# patch C_BASE_TEMPLATE
$(call define_append,C_BASE_TEMPLATE,$(newline)$$(ASM_TEMPLATE))

# tools colors
ASM_COLOR := [37m

# reset ASMFLAGS at beginning of target makefile
$(call define_append,PREPARE_C_VARS,$(newline)ASMFLAGS:=)

# add assembler-specific definitions
include $(ASM_COMPILER)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,TRG_ASMFLAGS ASM_TEMPLATE ASM_COLOR)
