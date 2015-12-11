# this file included by $(MTOP)/WINXX/make_c.mk

# FILEOS in $(STD_VERSION_RC_TEMPLATE), $1 - EXE,DLL,DRV
RC_OS ?= VOS_NT

# FILETYPE in $(STD_VERSION_RC_TEMPLATE), $1 - EXE,DLL,DRV
RC_FT ?= $(if \
  $(filter EXE,$1),VFT_APP,$(if \
  $(filter DLL,$1),VFT_DLL,$(if \
  $(filter DRV,$1),VFT_DRV)))

# FILESUBTYPE in $(STD_VERSION_RC_TEMPLATE), $1 - EXE,DLL,DRV
RC_FST ?= $(if $(filter DRV,$1),VFT2_DRV_SYSTEM,0L)

# C-header file which defines constants for standard resource template
# note: $(PRODUCT_NAMES_H) may be recursive macro,
# so may produce dynamic results, for example based on value of $(CURRENT_MAKEFILE)
WIN_RC_PRODUCT_DEFS_HEADER ?= $(GEN_DIR)/$(PRODUCT_NAMES_H)

# names of constants in $(WIN_RC_PRODUCT_DEFS_HEADER) used in standard resource template
# may be already defined in $(TOP)/make/make_features.mk
WIN_RC_PRODUCT_VERSION_MAJOR ?= PRODUCT_VERSION_MAJOR
WIN_RC_PRODUCT_VERSION_MINOR ?= PRODUCT_VERSION_MINOR
WIN_RC_PRODUCT_BUILD_NUM     ?= PRODUCT_BUILD_NUM
WIN_RC_VENDOR_NAME           ?= VENDOR_NAME
WIN_RC_VENDOR_COPYRIGHT      ?= VENDOR_COPYRIGHT
WIN_RC_PRODUCT_NAME          ?= PRODUCT_NAME
WIN_RC_PRODUCT_VERSION       ?= PRODUCT_VERSION

# $1 - EXE,DLL,DRV
# $2 - $(GET_TARGET_NAME)
# $3 - $(WIN_RC_PRODUCT_DEFS_HEADER)
# $4 - $(WIN_RC_PRODUCT_VERSION_MAJOR)
# $5 - $(WIN_RC_PRODUCT_VERSION_MINOR)
# $6 - $(WIN_RC_PRODUCT_BUILD_NUM)
# $7 - $(WIN_RC_VENDOR_NAME)
# $8 - $(WIN_RC_VENDOR_COPYRIGHT)
# $9 - $(WIN_RC_PRODUCT_NAME)
# $(10) - $(WIN_RC_PRODUCT_VERSION)
# note: STD_VERSION_RC_TEMPLATE may be already defined in $(TOP)/make/make_features.mk
ifndef STD_VERSION_RC_TEMPLATE
define STD_VERSION_RC_TEMPLATE
#include <winver.h>
#include "$3"
VS_VERSION_INFO VERSIONINFO
FILEVERSION $4,$5,$6,0
PRODUCTVERSION $4,$5,$6,0
FILEFLAGSMASK VS_FF_DEBUG | VS_FF_PRERELEASE | VS_FF_PATCHED | VS_FF_PRIVATEBUILD | VS_FF_INFOINFERRED | VS_FF_SPECIALBUILD
#ifdef DEBUG
    FILEFLAGS VS_FF_DEBUG
#else
    FILEFLAGS 0x0L
#endif
FILEOS $(RC_OS)
FILETYPE $(RC_FT)
FILESUBTYPE $(RC_FST)
BEGIN
    BLOCK "StringFileInfo"
    BEGIN
        BLOCK "040904b0"
        BEGIN
            VALUE "CompanyName",     $7 "\0"
            VALUE "LegalCopyright",  $8 "\0"
            VALUE "ProductName",     $9 "\0"
            VALUE "ProductVersion",  $(10) "\0"
            VALUE "FileVersion",     $(10) "\0"
            VALUE "FileDescription", "$2\0"
            VALUE "InternalName",    "$2\0"
            VALUE "OriginalFilename","$2$($1_SUFFIX)\0"
        END
    END
    BLOCK "VarFileInfo"
    BEGIN
        VALUE "Translation", 0x409, 1200
    END
END
endef
endif # STD_VERSION_RC_TEMPLATE

# $1 - EXE,DLL,DRV
# $2 - $(GET_TARGET_NAME)
# $3 - $(FORM_OBJ_DIR)
# note: $$(TRG_RES) will be cleaned up together with $1_RES
# note: don't use $(STD_TARGET_VARS) - inherit MF,MCONT,TMD from target EXE,DLL,DRV
define STD_RES_TEMPLATE1
TRG_RC := $(GEN_DIR)/stdres/$2_$1.rc
$$(TRG_RC): | $(GEN_DIR)/stdres
	$$(call SUP,GEN,$$@)$$(call ECHO,$$(call STD_VERSION_RC_TEMPLATE,$1,$2,$(strip \
$(WIN_RC_PRODUCT_DEFS_HEADER)),$(strip \
$(WIN_RC_PRODUCT_VERSION_MAJOR)),$(strip \
$(WIN_RC_PRODUCT_VERSION_MINOR)),$(strip \
$(WIN_RC_PRODUCT_BUILD_NUM)),$(strip \
$(WIN_RC_VENDOR_NAME)),$(strip \
$(WIN_RC_VENDOR_COPYRIGHT)),$(strip \
$(WIN_RC_PRODUCT_NAME)),$(strip \
$(WIN_RC_PRODUCT_VERSION)))) > $$@
TRG_RES := $3/$2_$1.res
$$(TRG_RES): $$(TRG_RC) $(WIN_RC_PRODUCT_DEFS_HEADER) | $3
	$$(call RC,$$@,$$<)
NEEDED_DIRS += $(GEN_DIR)/stdres $3
CLEAN += $$(TRG_RC)
$1_RES += $$(TRG_RES)
endef

# $1 - EXE,DLL,DRV
# $2 - $(call FORM_TRG,$1,$v)
# note: after evaluating of STD_RES_TEMPLATE1, standard resource will be added to $1_RES, so postpone expansion of $$($1_RES) here
define ADD_RES_TEMPLATE
$(empty)
$2: $(RES) $$($1_RES)
$2: RES := $(RES) $$($1_RES)
endef

# $1 - EXE,DLL,DRV
# 1) generate invariant rule to make standard resource
# 2) for each target variant add standard resource to the target
# note: don't add standard resource to the tool or if adding such resource is explicitly disabled in makefile via NO_STD_RES variable
define STD_RES_TEMPLATE
$(if $(CB_TOOL_MODE),,$(if $(NO_STD_RES),,$(call STD_RES_TEMPLATE1,$1,$(GET_TARGET_NAME),$(FORM_OBJ_DIR))))
$(foreach v,$(call GET_VARIANTS,$1,VARIANTS_FILTER),$(call ADD_RES_TEMPLATE,$1,$(call FORM_TRG,$1,$v)))
endef

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_APPEND_PROTECTED_VARS, \
  RC_OS RC_FT RC_FST \
  WIN_RC_PRODUCT_DEFS_HEADER \
  WIN_RC_PRODUCT_VERSION_MAJOR WIN_RC_PRODUCT_VERSION_MINOR WIN_RC_PRODUCT_BUILD_NUM \
  WIN_RC_VENDOR_NAME WIN_RC_VENDOR_COPYRIGHT WIN_RC_PRODUCT_NAME WIN_RC_PRODUCT_VERSION \
  STD_VERSION_RC_TEMPLATE STD_RES_TEMPLATE1 ADD_RES_TEMPLATE STD_RES_TEMPLATE)
