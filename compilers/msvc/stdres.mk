#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# standard version resource file generation, included by $(CLEAN_BUILD_DIR)/compilers/msvc.mk

# reset additional user-modifiable variables at beginning of target makefile
# NO_STD_RES - if non-empty, then do not add standard resource to the target
C_PREPARE_MSVC_STDRES_VARS := $(newline)NO_STD_RES:=

# standard version resource template
# $1 - EXE,DLL,DRV,KDLL
# $2 - target file name
# $3 - R,S,D,...
# target-specific: WIN_RC_PRODUCT_DEFS_HEADER
define WIN_RC_VERSION_TEMPLATE
#include <winver.h>
$(WIN_RC_INCLUDE)
#define _VERSION_TO_STR(s) #s
#define VERSION_TO_STR(a,b,c,d) _VERSION_TO_STR(a.b.c.d)
VS_VERSION_INFO VERSIONINFO
PRODUCTVERSION $(WIN_RC_PRODUCT_VERSION_MAJOR),$(WIN_RC_PRODUCT_VERSION_MINOR),$(WIN_RC_PRODUCT_VERSION_PATCH),$(WIN_RC_PRODUCT_BUILD_NUM)
FILEVERSION    $(WIN_RC_FILE_VERSION_MAJOR),$(WIN_RC_FILE_VERSION_MINOR),$(WIN_RC_FILE_VERSION_PATCH),$(WIN_RC_PRODUCT_BUILD_NUM)
FILEFLAGSMASK  VS_FF_DEBUG | VS_FF_PRERELEASE | VS_FF_PRIVATEBUILD | VS_FF_SPECIALBUILD | VS_FF_PATCHED
FILEFLAGS      $(WIN_RC_FILEFLAGS)$(if \
  $(WIN_RC_PRIVATE_BUILD), | VS_FF_PRIVATEBUILD)$(if \
  $(WIN_RC_SPECIAL_BUILD), | VS_FF_SPECIALBUILD)$(if \
  $(WIN_RC_PATCHED), | VS_FF_PATCHED)
FILEOS         $(WIN_RC_FILEOS)
FILETYPE       $(WIN_RC_FILETYPE)
FILESUBTYPE    $(WIN_RC_FILESUBTYPE)
BEGIN
    BLOCK "StringFileInfo"
    BEGIN
        BLOCK "$(WIN_RC_LANG)$(WIN_RC_CHARSET)"
        BEGIN
            VALUE "CompanyName",     $(WIN_RC_COMPANY_NAME) "\0"
            VALUE "ProductName",     $(WIN_RC_PRODUCT_NAME) "\0"
            VALUE "ProductVersion",  $(WIN_RC_PRODUCT_VERSION_STR) "\0"
            VALUE "FileDescription", $(WIN_RC_FILE_DESCRIPTION) "\0"
            VALUE "FileVersion",     $(WIN_RC_FILE_VERSION_STR) "\0"
            VALUE "OriginalFilename",$(WIN_RC_ORIGINAL_FILE_NAME) "\0"
            VALUE "InternalName",    $(WIN_RC_INTERNAL_NAME) "\0"$(if \
$(WIN_RC_COMMENTS),$(newline)            VALUE "Comments"$(comma)        $(WIN_RC_COMMENTS) "\0")$(if \
$(WIN_RC_LEGAL_COPYRIGHT),$(newline)            VALUE "LegalCopyright"$(comma)  $(WIN_RC_LEGAL_COPYRIGHT) "\0")$(if \
$(WIN_RC_LEGAL_TRADEMARKS),$(newline)            VALUE "LegalTrademarks"$(comma) $(WIN_RC_LEGAL_TRADEMARKS) "\0")$(if \
$(WIN_RC_PRIVATE_BUILD),$(newline)            VALUE "PrivateBuild"$(comma)    $(WIN_RC_PRIVATE_BUILD) "\0")$(if \
$(WIN_RC_SPECIAL_BUILD),$(newline)            VALUE "SpecialBuild"$(comma)    $(WIN_RC_SPECIAL_BUILD) "\0")
        END
    END
    BLOCK "VarFileInfo"
    BEGIN
        VALUE "Translation", 0x$(WIN_RC_LANG), 0x$(WIN_RC_CHARSET)
    END
END
endef

# C-header file which defines constants for standard version resource template
# note: PRODUCT_NAMES_H may be recursive macro, which value may depend on $(TARGET_MAKEFILE)
WIN_RC_PRODUCT_DEFS_HEADER = $(GEN_DIR)/$(PRODUCT_NAMES_H)

# assume $(PRODUCT_NAMES_H) contains next definitions:
#define VENDOR_NAME           "Acme corp"
#define PRODUCT_NAME          "Super app"
#define VENDOR_COPYRIGHT      "(c) Acme corp. All rights reserved"
#define PRODUCT_VERSION_MAJOR 4
#define PRODUCT_VERSION_MINOR 12
#define PRODUCT_VERSION_PATCH 0
#define PRODUCT_TARGET        "RELEASE"
#define PRODUCT_OS            "WINDOWS"
#define PRODUCT_CPU           "x86"
#define PRODUCT_KCPU          "x64"
#define PRODUCT_BUILD_NUM     12345
#define PRODUCT_BUILD_DATE    "01/01/2017:09.30"

# auxiliary text to add to generated version resource file
WIN_RC_INCLUDE = \#include "$(WIN_RC_PRODUCT_DEFS_HEADER)"

# product version numbers
# assume PRODUCT_VERSION_MAJOR, PRODUCT_VERSION_MINOR and PRODUCT_VERSION_PATCH
#  integer constants are defined in included $(WIN_RC_PRODUCT_DEFS_HEADER)
WIN_RC_PRODUCT_VERSION_MAJOR := PRODUCT_VERSION_MAJOR
WIN_RC_PRODUCT_VERSION_MINOR := PRODUCT_VERSION_MINOR
WIN_RC_PRODUCT_VERSION_PATCH := PRODUCT_VERSION_PATCH

# per-module version numbers
# target-specific: MODVER
WIN_RC_FILE_VERSION_MAJOR = $(call ver_major,$(MODVER))
WIN_RC_FILE_VERSION_MINOR = $(call ver_minor,$(MODVER))
WIN_RC_FILE_VERSION_PATCH = $(call ver_patch,$(MODVER))

# product build number
# assume PRODUCT_BUILD_NUM integer constant is defined in included $(WIN_RC_PRODUCT_DEFS_HEADER)
WIN_RC_PRODUCT_BUILD_NUM := PRODUCT_BUILD_NUM

# mark built module with VS_FF_DEBUG and VS_FF_PRERELEASE flags in DEBUG builds
WIN_RC_FILEFLAGS = $(if $(DEBUG),VS_FF_DEBUG | VS_FF_PRERELEASE,0x0L)

# module is built for WIN32/WIN64, not for WIN16/DOS
WIN_RC_FILEOS := VOS_NT_WINDOWS32

# type of built module
# $1 - EXE,DLL,DRV,KDLL
WIN_RC_FILETYPE = $(if \
  $(filter EXE,$1),VFT_APP,$(if \
  $(filter DLL,$1),VFT_DLL,$(if \
  $(filter DRV KDLL,$1),VFT_DRV)))

# what kind of driver is built
# possible values: VFT2_DRV_{COMM,PRINTER,KEYBOARD,LANGUAGE,DISPLAY,MOUSE,NETWORK,SYSTEM,INSTALLABLE,SOUND}
WIN_RC_DRV_TYPE := VFT2_DRV_SYSTEM

# sub-type of built module
# $1 - EXE,DLL,DRV,KDLL
WIN_RC_FILESUBTYPE := $(if $(filter DRV KDLL,$1),$(WIN_RC_DRV_TYPE),0x0L)

# language code
# 0409 - U.S. English
# 0419 - Russian
WIN_RC_LANG := 0409

# character set
# 04b0 - Unicode
WIN_RC_CHARSET := 04b0

# company and product names
# assume VENDOR_NAME and PRODUCT_NAME string constants are defined in included $(WIN_RC_PRODUCT_DEFS_HEADER)
WIN_RC_COMPANY_NAME := VENDOR_NAME
WIN_RC_PRODUCT_NAME := PRODUCT_NAME

# make product version string using C-macro VERSION_TO_STR defined in resource template
WIN_RC_PRODUCT_VERSION_STR = VERSION_TO_STR(\
  $(WIN_RC_PRODUCT_VERSION_MAJOR),\
  $(WIN_RC_PRODUCT_VERSION_MINOR),\
  $(WIN_RC_PRODUCT_VERSION_PATCH),\
  $(WIN_RC_PRODUCT_BUILD_NUM))

# module description - for now, just original name of the module file
WIN_RC_FILE_DESCRIPTION = $(WIN_RC_ORIGINAL_FILE_NAME)

# make module version string using C-macro VERSION_TO_STR defined in resource template
WIN_RC_FILE_VERSION_STR = VERSION_TO_STR(\
  $(WIN_RC_FILE_VERSION_MAJOR),\
  $(WIN_RC_FILE_VERSION_MINOR),\
  $(WIN_RC_FILE_VERSION_PATCH),\
  $(WIN_RC_PRODUCT_BUILD_NUM))

# original module file name
# $1 - EXE,DLL,DRV,KDLL
# $2 - target file name
# $3 - R,S,D,...
WIN_RC_ORIGINAL_FILE_NAME = "$2"

# module internal name - for now, just original name of the module file
WIN_RC_INTERNAL_NAME = $(WIN_RC_ORIGINAL_FILE_NAME)

# module commentaries
# assume PRODUCT_TARGET, PRODUCT_OS, PRODUCT_CPU or PRODUCT_KCPU and PRODUCT_BUILD_DATE
#  string constants are defined in included $(WIN_RC_PRODUCT_DEFS_HEADER)
# $1 - EXE,DLL,DRV,KDLL
WIN_RC_COMMENTS = PRODUCT_TARGET "/" PRODUCT_OS "/" $(if \
  $(filter DRV KDLL,$1),PRODUCT_KCPU,PRODUCT_CPU) "/" PRODUCT_BUILD_DATE

# module copyright notices
# assume VENDOR_COPYRIGHT string constant is defined in included $(WIN_RC_PRODUCT_DEFS_HEADER)
WIN_RC_LEGAL_COPYRIGHT := VENDOR_COPYRIGHT

# module trademarks
# note: may be defined in project configuration makefile
WIN_RC_LEGAL_TRADEMARKS :=

# information about a private/special version of the module, whenever built module is a patched one
WIN_RC_PRIVATE_BUILD:=
WIN_RC_SPECIAL_BUILD:=
WIN_RC_PATCHED:=

# write result of $(WIN_RC_VERSION_TEMPLATE) by fixed number of lines at a time
# note: command line length is limited (by 8191 chars on Windows),
#  so must not write more than that number of chars (lines * max_chars_in_line) at a time.
WIN_RC_WRITE_BY_LINES := 40

# name of generated standard version info resource file
WIN_RC_STDRES_NAME := std_ver_info

# $1 - EXE,DLL,DRV,KDLL
# $2 - $(WIN_RC_PRODUCT_DEFS_HEADER)
# $3 - $(call FORM_TRG,$1,$v)
# $4 - $(call FORM_OBJ_DIR,$1,$v)
# $5 - $(WIN_RC_STDRES_NAME)
# $v - R,S,D,...
# note: optimization: don't use $(STD_TARGET_VARS) - inherit MF,MCONT,TMD,MODVER from target EXE,DLL,DRV,KDLL
# note: target-specific MODVER is inherited from target EXE,DLL,DRV,KDLL
# note: object directory $4 added to CB_NEEDED_DIRS by C_BASE_TEMPLATE from $(CLEAN_BUILD_DIR)/types/c/c_base.mk
# note: last line must be empty
define STD_RES_TEMPLATE2
$4/$5.rc: WIN_RC_PRODUCT_DEFS_HEADER := $2
$4/$5.rc:| $4
	$$(call SUP,GEN,$$@)$$(call WRITE_TEXT,$$(call WIN_RC_VERSION_TEMPLATE,$1,$(notdir $3),$v),$$@,$(WIN_RC_WRITE_BY_LINES))
$4/$5.res: $4/$5.rc $2 | $4
	$$(call RC_COMPILER,$$@,$$<,$$(call qpath,$$(RC_STDINCLUDES),/I))
$3: $4/$5.res

endef

# $1 - EXE,DLL,DRV,KDLL
# $2 - $(WIN_RC_PRODUCT_DEFS_HEADER)
STD_RES_TEMPLATE1 = $(foreach v,$(GET_VARIANTS),$(call \
  STD_RES_TEMPLATE2,$1,$2,$(call FORM_TRG,$1,$v),$(call FORM_OBJ_DIR,$1,$v),$(WIN_RC_STDRES_NAME)))

ifndef TOCLEAN

# add standard resource to the target
# $1 - EXE,DLL,DRV,KDLL
# note: don't add standard resource to the tool or if NO_STD_RES variable is set in target makefile
STD_RES_TEMPLATE = $(if $(TMD),,$(if $(NO_STD_RES),,$(call STD_RES_TEMPLATE1,$1,$(WIN_RC_PRODUCT_DEFS_HEADER))))

else # clean

# cleanup standard resources (e.g. /build/obj/std_ver_info.rc and /build/obj/std_ver_info.res)
# $1 - EXE,DLL,DRV,KDLL
# note: don't cleanup standard resource in tool mode or if NO_STD_RES variable is set in target makefile
STD_RES_TEMPLATE = $(if $(TMD),,$(if $(NO_STD_RES),,$(call TOCLEAN,$(foreach \
  v,$(GET_VARIANTS),$(addprefix $(call FORM_OBJ_DIR,$1,$v)/$(WIN_RC_STDRES_NAME).,rc res)))))

endif # clean

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,C_PREPARE_MSVC_STDRES_VARS \
  WIN_RC_VERSION_TEMPLATE WIN_RC_PRODUCT_DEFS_HEADER WIN_RC_INCLUDE \
  WIN_RC_PRODUCT_VERSION_MAJOR WIN_RC_PRODUCT_VERSION_MINOR WIN_RC_PRODUCT_VERSION_PATCH \
  WIN_RC_FILE_VERSION_MAJOR WIN_RC_FILE_VERSION_MINOR WIN_RC_FILE_VERSION_PATCH \
  WIN_RC_PRODUCT_BUILD_NUM WIN_RC_FILEFLAGS WIN_RC_FILEOS WIN_RC_FILETYPE WIN_RC_DRV_TYPE WIN_RC_FILESUBTYPE \
  WIN_RC_LANG WIN_RC_CHARSET WIN_RC_COMPANY_NAME WIN_RC_PRODUCT_NAME WIN_RC_PRODUCT_VERSION_STR \
  WIN_RC_FILE_DESCRIPTION WIN_RC_FILE_VERSION_STR WIN_RC_ORIGINAL_FILE_NAME WIN_RC_INTERNAL_NAME \
  WIN_RC_COMMENTS WIN_RC_LEGAL_COPYRIGHT WIN_RC_LEGAL_TRADEMARKS WIN_RC_PRIVATE_BUILD WIN_RC_SPECIAL_BUILD \
  WIN_RC_PATCHED WIN_RC_WRITE_BY_LINES WIN_RC_STDRES_NAME STD_RES_TEMPLATE2 STD_RES_TEMPLATE1 STD_RES_TEMPLATE)
