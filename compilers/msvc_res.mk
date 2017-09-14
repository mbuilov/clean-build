#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# standard resource template, included by $(CLEAN_BUILD_DIR)/compilers/msvc.mk

https://msdn.microsoft.com/ru-ru/library/windows/desktop/aa381058(v=vs.85).aspx
https://msdn.microsoft.com/ru-ru/library/windows/desktop/ms646997(v=vs.85).aspx
https://www.cs.helsinki.fi/group/boi2016/doc/freepascal/fclres/versionconsts/index.html

# $1    - target file name the resource is bundled into, e.g. $(notdir $(call FORM_TRG,EXE,R))
# $2    - $(WIN_RC_INCLUDE)                 auxiliary text to add to generated resource file
# $3    - $(WIN_RC_PRODUCT_VERSION_MAJOR)   product major version number
# $4    - $(WIN_RC_PRODUCT_VERSION_MINOR)   product minor version number
# $5    - $(WIN_RC_PRODUCT_VERSION_PATCH)   product patch number
# $6    - $(WIN_RC_MODULE_VERSION_MAJOR)    module file major version number
# $7    - $(WIN_RC_MODULE_VERSION_MINOR)    module file minor version number
# $8    - $(WIN_RC_MODULE_VERSION_PATCH)    module file patch number
# $9    - $(WIN_RC_PRODUCT_BUILD_NUM)       product build number
# $(10) - $(WIN_RC_FILEOS)
# $(11) - $(WIN_RC_FILETYPE)
# $(12) - $(WIN_RC_FILESUBTYPE)
# $(13) - $(WIN_RC_LANG)
# $(14) - $(WIN_RC_CHARSET)
# $(15) - $(WIN_RC_COMPANY_NAME)
# $(16) - $(WIN_RC_PRODUCT_NAME)
# $(17) - $(WIN_RC_FILE_DESCRIPTION)
# $(18) - $(WIN_RC_INTERNAL_NAME)
# $(19) - $(WIN_RC_COMMENTS)
# $(20) - $(WIN_RC_LEGAL_COPYRIGHT)
# $(21) - $(WIN_RC_LEGAL_TRADEMARKS)
# $(22) - $(WIN_RC_PRIVATE_BUILD)
# $(23) - $(WIN_RC_SPECIAL_BUILD)
define WIN_RC_VERSION_TEMPLATE
#include <winver.h>
$2
#define _VERSION_TO_STR(s) #s
#define VERSION_TO_STR(a,b,c,d) _VERSION_TO_STR(a.b.c.d)
VS_VERSION_INFO VERSIONINFO
PRODUCTVERSION $3,$4,$5,$9
FILEVERSION    $6,$7,$8,$9
FILEFLAGSMASK VS_FF_DEBUG | VS_FF_PATCHED | VS_FF_PRERELEASE | VS_FF_PRIVATEBUILD | VS_FF_SPECIALBUILD
#ifdef DEBUG
    FILEFLAGS VS_FF_DEBUG | VS_FF_PRERELEASE$(if $(24), | VS_FF_PATCHED)$(if $(21), | VS_FF_PRIVATEBUILD)$(if $(23), | VS_FF_SPECIALBUILD)
#else
    FILEFLAGS 0x0L$(if $(24), | VS_FF_PATCHED)$(if $(21), | VS_FF_PRIVATEBUILD)$(if $(23), | VS_FF_SPECIALBUILD)
#endif
FILEOS      $(10)
FILETYPE    $(11)
FILESUBTYPE $(12)
BEGIN
    BLOCK "StringFileInfo"
    BEGIN
        BLOCK "$(13)$(14)"
        BEGIN
            VALUE "CompanyName",     $(15) "\0"
            VALUE "ProductName",     $(16) "\0"
            VALUE "ProductVersion",  VERSION_TO_STR($3,$4,$5,$9) "\0"
            VALUE "FileDescription", $(17) "\0"
            VALUE "FileVersion",     VERSION_TO_STR($6,$7,$8,$9) "\0"
            VALUE "OriginalFilename","$1\0"
            VALUE "InternalName",    $(18) "\0"$(if \
$(19),$(newline)            VALUE "Comments"$(comma)        $(19) "\0")$(if \
$(20),$(newline)            VALUE "LegalCopyright"$(comma)  $(20) "\0")$(if \
$(21),$(newline)            VALUE "LegalTrademarks"$(comma) $(21) "\0")$(if \
$(22),$(newline)            VALUE "PrivateBuild"$(comma)    $(22) "\0")$(if \
$(23),$(newline)            VALUE "SpecialBuild"$(comma)    $(23) "\0")
        END
    END
    BLOCK "VarFileInfo"
    BEGIN
        VALUE "Translation", 0x$(13), 0x$(14)
    END
END
endef

# C-header file which defines constants for standard resource template
# note: PRODUCT_NAMES_H may be recursive macro, which value may depend on $(TARGET_MAKEFILE)
WIN_RC_PRODUCT_DEFS_HEADER = $(GEN_DIR)/$(PRODUCT_NAMES_H)

# auxiliary text to add to generated resource file
WIN_RC_INCLUDE = \#include "$(WIN_RC_PRODUCT_DEFS_HEADER)"

# assume PRODUCT_VERSION_MAJOR, PRODUCT_VERSION_MINOR and PRODUCT_VERSION_PATCH
#  constants are defined in $(WIN_RC_PRODUCT_DEFS_HEADER)
WIN_RC_PRODUCT_VERSION_MAJOR := PRODUCT_VERSION_MAJOR
WIN_RC_PRODUCT_VERSION_MINOR := PRODUCT_VERSION_MINOR
WIN_RC_PRODUCT_VERSION_PATCH := PRODUCT_VERSION_PATCH

# per-module version
WIN_RC_MODULE_VERSION_MAJOR = $(call ver_major,$(MODVER))
WIN_RC_MODULE_VERSION_MINOR = $(call ver_minor,$(MODVER))
WIN_RC_MODULE_VERSION_PATCH = $(call ver_patch,$(MODVER))

# assume PRODUCT_BUILD_NUM constant is defined in $(WIN_RC_PRODUCT_DEFS_HEADER)
WIN_RC_PRODUCT_BUILD_NUM := PRODUCT_BUILD_NUM

WIN_RC_FILEOS := VOS_NT_WINDOWS32
# $(11) - $(WIN_RC_FILETYPE)
# $(12) - $(WIN_RC_FILESUBTYPE)

# FILEOS value in $(STD_VERSION_RC_TEMPLATE)
# $1 - EXE,DLL,DRV,KDLL
STD_RC_FILEOS := VOS_NT_WINDOWS32

# FILETYPE value in $(STD_VERSION_RC_TEMPLATE)
# $1 - EXE,DLL,DRV,KDLL
STD_RC_FILETYPE = $(if \
  $(filter EXE,$1),VFT_APP,$(if \
  $(filter DLL,$1),VFT_DLL,$(if \
  $(filter DRV KDLL,$1),VFT_DRV)))

# FILESUBTYPE value in $(STD_VERSION_RC_TEMPLATE)
# $1 - EXE,DLL,DRV,KDLL
STD_RC_FILESUBTYPE = $(if $(filter DRV KDLL,$1),VFT2_DRV_SYSTEM,0L)


# define standard resource values - use definitions from C-header file $(WIN_RC_PRODUCT_DEFS_HEADER),
# which should contain (example):
#
#define VENDOR_NAME           "Acme corp"
#define PRODUCT_NAME          "Super app"
#define VENDOR_COPYRIGHT      "(c) Acme corp. All rights reserved"
#define PRODUCT_VERSION_MAJOR 4
#define PRODUCT_VERSION_MINOR 12
#define PRODUCT_VERSION_PATCH 0 /* optional */
#define PRODUCT_OS            "WINDOWS"
#define PRODUCT_CPU           "x86"
#define PRODUCT_KCPU          "x64"
#define PRODUCT_TARGET        "RELEASE"
#define PRODUCT_BUILD_NUM     12345
#define PRODUCT_BUILD_DATE    "01/01/2017:09.30"

#include "$2"$3
#define _VERSION_TO_STR(s) #s
#define VERSION_TO_STR(a,b,c,d) _VERSION_TO_STR(a.b.c.d)

# define parameters for .rc-file generation
# $1 - target EXE,DLL,DRV,KDLL
# target-specific variables: MODVER
# note: some of WIN_RC_... variables may be overridden in project configuration makefile before including this file
WIN_RC_PRODUCT_BUILD_NUM     := PRODUCT_BUILD_NUM
WIN_RC_COMMENTS               = PRODUCT_TARGET "/" PRODUCT_OS "/" $(if \
                                $(filter DRV KDLL,$1),PRODUCT_KCPU,PRODUCT_CPU) "/" PRODUCT_BUILD_DATE
WIN_RC_COMPANY_NAME          := VENDOR_NAME
WIN_RC_FILE_DESCRIPTION       = "$(GET_TARGET_NAME)"
WIN_RC_FILE_VERSION           = VERSION_TO_STR($(if \
                               ,)$(WIN_RC_MODULE_VERSION_MAJOR),$(if \
                               ,)$(WIN_RC_MODULE_VERSION_MINOR),$(if \
                               ,)$(WIN_RC_MODULE_VERSION_PATCH),$(if \
                               ,)$(WIN_RC_PRODUCT_BUILD_NUM))
WIN_RC_INTERNAL_NAME          = "$(GET_TARGET_NAME)"
WIN_RC_LEGAL_COPYRIGHT       := VENDOR_COPYRIGHT
WIN_RC_LEGAL_TRADEMARKS      :=
WIN_RC_PRIVATE_BUILD         :=
WIN_RC_PRODUCT_NAME          := PRODUCT_NAME
WIN_RC_PRODUCT_VERSION       := VERSION_TO_STR($(if \
                               ,)$(WIN_RC_PRODUCT_VERSION_MAJOR),$(if \
                               ,)$(WIN_RC_PRODUCT_VERSION_MINOR),$(if \
                               ,)$(WIN_RC_PRODUCT_VERSION_PATCH),$(if \
                               ,)$(WIN_RC_PRODUCT_BUILD_NUM))
WIN_RC_SPECIAL_BUILD         :=
WIN_RC_LANG                  := 0409
WIN_RC_CHARSET               := 04b0

# $1 - EXE,DLL,DRV,KDLL
# $2 - $(GET_TARGET_NAME)
# $3 - $(FORM_OBJ_DIR)
# note: don't use $(STD_TARGET_VARS) - inherit MF,MCONT,TMD from target EXE,DLL,DRV,KDLL
# note: $$(TRG_RES) file will be cleaned up together with $(RES)
define STD_RES_TEMPLATE1
TRG_RC := $(GEN_DIR)/stdres/$2_$1.rc
$$(TRG_RC): | $(GEN_DIR)/stdres
	$$(call SUP,GEN,$$@)$$(call ECHO,$$(call STD_VERSION_RC_TEMPLATE,$1,$2,$(if \
,)$(WIN_RC_PRODUCT_DEFS_HEADER),$(if \
,)$(WIN_RC_PRODUCT_VERSION_MAJOR),$(if \
,)$(WIN_RC_PRODUCT_VERSION_MINOR),$(if \
,)$(WIN_RC_PRODUCT_VERSION_PATCH),$(if \
,)$(WIN_RC_MODULE_VERSION_MAJOR),$(if \
,)$(WIN_RC_MODULE_VERSION_MINOR),$(if \
,)$(WIN_RC_MODULE_VERSION_PATCH),$(if \
,)$(WIN_RC_PRODUCT_BUILD_NUM),$(if \
,)$(WIN_RC_COMMENTS),$(if \
,)$(WIN_RC_COMPANY_NAME),$(if \
,)$(WIN_RC_FILE_DESCRIPTION),$(if \
,)$(WIN_RC_FILE_VERSION),$(if \
,)$(WIN_RC_INTERNAL_NAME),$(if \
,)$(WIN_RC_LEGAL_COPYRIGHT),$(if \
,)$(WIN_RC_LEGAL_TRADEMARKS),$(if \
,)$(WIN_RC_PRIVATE_BUILD),$(if \
,)$(WIN_RC_PRODUCT_NAME),$(if \
,)$(WIN_RC_PRODUCT_VERSION),$(if \
,)$(WIN_RC_SPECIAL_BUILD),$(if \
,)$(WIN_RC_LANG),$(if \
,)$(WIN_RC_CHARSET))) > $$@
TRG_RES := $3/$2_$1.res
$$(TRG_RES): $$(TRG_RC) $(WIN_RC_PRODUCT_DEFS_HEADER) | $3
	$$(call RC,$$@,$$<,)
NEEDED_DIRS += $(GEN_DIR)/stdres $3
RES += $$(TRG_RES)
endef

ifdef TOCLEAN
$(call define_append,STD_RES_TEMPLATE1,$(newline)$$$$(call TOCLEAN,$$$$(TRG_RC)))
endif

# $1 - $(call FORM_TRG,$1,$v)
# note: after evaluating of STD_RES_TEMPLATE1, standard resource will be appended to RES, so postpone expansion of $$(RES) here
define ADD_RES_TEMPLATE
$(empty)
$1: $$(RES)
$1: RES := $$(RES)
endef

# $1 - EXE,DLL,DRV,KDLL
# 1) generate invariant rule to make standard resource
# 2) for each target variant add standard resource to the target
# note: don't add standard resource to the tool or if adding such resource is explicitly disabled in makefile via NO_STD_RES variable
define STD_RES_TEMPLATE
$(if $(TMD),,$(if $(NO_STD_RES),,$(call STD_RES_TEMPLATE1,$1,$(GET_TARGET_NAME),$(FORM_OBJ_DIR))))
$(foreach v,$(call GET_VARIANTS,$1),$(call ADD_RES_TEMPLATE,$(call FORM_TRG,$1,$v)))
endef

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS, \
  RC_OS RC_FT RC_FST \
  WIN_RC_PRODUCT_DEFS_HEADER \
  WIN_RC_PRODUCT_VERSION_MAJOR WIN_RC_PRODUCT_VERSION_MINOR WIN_RC_PRODUCT_VERSION_PATCH \
  WIN_RC_MODULE_VERSION_MAJOR WIN_RC_MODULE_VERSION_MINOR WIN_RC_MODULE_VERSION_PATCH WIN_RC_PRODUCT_BUILD_NUM \
  WIN_RC_COMMENTS WIN_RC_COMPANY_NAME WIN_RC_FILE_DESCRIPTION WIN_RC_FILE_VERSION WIN_RC_INTERNAL_NAME \
  WIN_RC_LEGAL_COPYRIGHT WIN_RC_LEGAL_TRADEMARKS WIN_RC_PRIVATE_BUILD \
  WIN_RC_PRODUCT_NAME WIN_RC_PRODUCT_VERSION WIN_RC_SPECIAL_BUILD WIN_RC_LANG WIN_RC_CHARSET \
  STD_VERSION_RC_TEMPLATE STD_RES_TEMPLATE1 ADD_RES_TEMPLATE STD_RES_TEMPLATE)
