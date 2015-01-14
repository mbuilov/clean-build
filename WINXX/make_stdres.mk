# this file included by $(MTOP)/WINXX/make_header.mk

EXE_RC_OS := VOS_NT
DLL_RC_OS := VOS_NT
DRV_RC_OS := VOS_NT

EXE_RC_FT := VFT_APP
DLL_RC_FT := VFT_DLL
DRV_RC_FT := VFT_DRV

EXE_RC_FST := 0L
DLL_RC_FST := 0L
DRV_RC_FST := VFT2_DRV_SYSTEM

# C-header file which defines constants for standard resource template
WIN_RC_PRODUCT_DEFS_HEADER   ?= $(BLDINC_DIR)/$(PRODUCT_NAMES_H)

# names of constants in $(WIN_RC_PRODUCT_DEFS_HEADER) used in standard resource template
WIN_RC_PRODUCT_VERSION_MAJOR ?= PRODUCT_VERSION_MAJOR
WIN_RC_PRODUCT_VERSION_MINOR ?= PRODUCT_VERSION_MINOR
WIN_RC_PRODUCT_BUILD_NUM     ?= PRODUCT_BUILD_NUM
WIN_RC_VENDOR_NAME           ?= VENDOR_NAME
WIN_RC_VENDOR_COPYRIGHT      ?= VENDOR_COPYRIGHT
WIN_RC_PRODUCT_NAME          ?= PRODUCT_NAME
WIN_RC_PRODUCT_VERSION       ?= PRODUCT_VERSION

# $1 - EXE,DLL,DRV
# $2 - $(call GET_TARGET_NAME,$1)
# $3 - $(WIN_RC_PRODUCT_DEFS_HEADER)
# $4 - $(WIN_RC_PRODUCT_VERSION_MAJOR)
# $5 - $(WIN_RC_PRODUCT_VERSION_MINOR)
# $6 - $(WIN_RC_PRODUCT_BUILD_NUM)
# $7 - $(WIN_RC_VENDOR_NAME)
# $8 - $(WIN_RC_VENDOR_COPYRIGHT)
# $9 - $(WIN_RC_PRODUCT_NAME)
# $(10) - $(WIN_RC_PRODUCT_VERSION)
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
FILEOS $($1_RC_OS)
FILETYPE $($1_RC_FT)
FILESUBTYPE $($1_RC_FST)
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
endef # STD_VERSION_RC_TEMPLATE

# $1 - EXE,DLL,DRV $2 - $(call GET_TARGET_NAME,$1), $3 - $(call FORM_OBJ_DIR,$1)
define STD_RES_TEMPLATE1
TRG_RC := $(BLDSRC_DIR)/$1_$2.rc
$$(TRG_RC): $(WIN_RC_PRODUCT_DEFS_HEADER) | $(BLDSRC_DIR)
	$$(call SUPRESS,GEN    $$@)$$(call ECHO,$$(call STD_VERSION_RC_TEMPLATE,$1,$2,$$<,$(WIN_RC_PRODUCT_VERSION_MAJOR),$(WIN_RC_PRODUCT_VERSION_MINOR),$(WIN_RC_PRODUCT_BUILD_NUM),$(WIN_RC_VENDOR_NAME),$(WIN_RC_VENDOR_COPYRIGHT),$(WIN_RC_PRODUCT_NAME),$(WIN_RC_PRODUCT_VERSION))) > $$@
TRG_RES := $(call FORM_OBJ_DIR,$1)/$1_$2.res
$$(TRG_RES): $$(TRG_RC) | $3
	$$(call RC,$$@,$$<)
NEEDED_DIRS += $3
CLEAN += $$(TRG_RC)
$1_RES += $$(TRG_RES)
endef

# $1 - EXE,DLL,DRV $2 - $(call FORM_TRG,$1,$v)
# STD_RES_TEMPLATE1 will add resource to $1_RES, so postpone expansion of $($1_RES) here
define ADD_STD_RES_TEMPLATE1
$(empty)
$2: $(RES) $$($1_RES)
$2: RES := $(RES) $$($1_RES)
endef

define STD_RES_TEMPLATE
$(if $(TOOL_MODE),,$(if $(NO_TARGET_RES),,$(call STD_RES_TEMPLATE1,$1,$(call GET_TARGET_NAME,$1),$(call FORM_OBJ_DIR,$1))))
$(foreach v,$(call GET_VARIANTS,$1,VARIANTS_FILTER),$(call ADD_STD_RES_TEMPLATE1,$1,$(call FORM_TRG,$1,$v)))
endef
