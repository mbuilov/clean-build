#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# Windows SDK auto-configuration (app-level), included by $(CLEAN_BUILD_DIR)/compilers/msvc.mk

# try to autoconfigure:
#  paths to system libraries and headers
#  - only if they are not defined in project configuration makefile or in command line
#
# UMLIBPATH - paths to user-mode libraries (spaces must be replaced with ?)
# UMINCLUDE - paths to user-mode headers   (spaces must be replaced with ?)
#
# example:
#
# UMLIBPATH := C:\Program?Files?(x86)\Windows?Kits\8.1\Lib\winv6.3\um\x86
# UMINCLUDE := C:\Program?Files?(x86)\Windows?Kits\8.1\Include\um

#################################################################################################################
# input for autoconfiguration:
#
# 1) SDK - Software Development Kit path (without quotes)
#   may be specified if autoconfiguration based on values of environment variables fails, e.g.:
#     SDK=C:\Program Files\Microsoft Visual Studio .NET 2003\Vc7\PlatformSDK
#     SDK=C:\Program Files\Microsoft Platform SDK for Windows Server 2003 R2
#     SDK=C:\Program Files\Microsoft SDKs\Windows\v7.1A
#     SDK=C:\Program Files\Windows Kits\8.1
#     SDK=C:\Program Files\Windows Kits\10
#
#   Note: Visual Studio 6.0 contains SDK libraries (e.g. KERNEL32.LIB) and headers (e.g. WINBASE.H) as a part of its installation,
#     so SDK variable may be empty or not defined.
#
# 2) SDK_VER - target operating system version, e.g.: win8 winv6.3 10.0.10240.0 10.0.10586.0 10.0.14393.0 10.0.15063.0 10.0.16299.0
#   may be specified explicitly if it's not possible to deduce SDK_VER automatically
#
#################################################################################################################

# we need next SDK variables: UMLIBPATH and UMINCLUDE
# (they are may be defined either in project configuration makefile or in command line)
# note: UMLIBPATH or UMINCLUDE may be defined as <empty>, so do not reset them
ifneq (,$(filter undefined environment,$(foreach v,UMLIBPATH UMINCLUDE,$(origin $v))))

# reset variables, if they are not defined in project configuration makefile or in command line
SDK:=
SDK_VER:=

# SDK may be defined as:
# --------------------------------------------------------------------------
# C:\Program Files\Microsoft Visual Studio .NET 2003\Vc7\PlatformSDK
# C:\Program Files\Microsoft SDK
# C:\Program Files\Microsoft Platform SDK for Windows XP SP2
# C:\Program Files\Microsoft Platform SDK for Windows Server 2003 R2
# C:\Program Files\Microsoft Visual Studio 8\VC\PlatformSDK
# C:\Program Files\Microsoft SDKs\Windows\v6.0
# C:\Program Files\Microsoft SDKs\Windows\v6.0A
# C:\Program Files\Microsoft SDKs\Windows\v6.1
# C:\Program Files\Microsoft SDKs\Windows\v7.0
# C:\Program Files\Microsoft SDKs\Windows\v7.0a
# C:\Program Files\Microsoft SDKs\Windows\v7.1
# C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A\
# C:\Program Files (x86)\Windows Kits\8.0
# C:\Program Files (x86)\Windows Kits\8.0a
# C:\Program Files (x86)\Windows Kits\8.1
# C:\Program Files (x86)\Windows Kits\8.1a
# C:\Program Files (x86)\Windows Kits\10

ifndef SDK

  # WindowsSdkDir is normally set by the vcvars32.bat (for Visual Studio 2015, e.g.:
  #  WindowsSdkDir=C:\Program Files (x86)\Windows Kits\10\
  #  WindowsSdkDir=C:\Program Files (x86)\Windows Kits\8.1\
  # note: likely with trailing slash
  ifneq (undefined,$(origin WindowsSdkDir))
    SDK := $(WindowsSdkDir)

  endif
endif

ifndef SDK_VER

  # WindowsSDKVersion is normally set by the vcvars32.bat (for Visual Studio 2015 and later), e.g.:
  #  WindowsSDKVersion=10.0.16299.0\
  # note: likely with trailing slash
  ifneq (undefined,$(origin WindowsSDKVersion))
    SDK_VER := $(WindowsSDKVersion:\=)

  endif
endif

ifndef SDK

  # at last, check "Program Files" and "Program Files (x86)" directories and define UMLIBPATH/UMINCLUDE



  # get list of Windows Kits versions
  # $1 - C:/Program?Files
  # result: 10 8.0 8.1
  KITS_FIND_VERSIONS = $(patsubst %/.,%,$(subst \
    ?$1/Windows?Kits/, ,?$(subst $(space),?,$(wildcard $(subst ?,\ ,$1)/Windows\ Kits/*/.))))

  # get list of Microsoft SDKs versions
  # $1 - C:/Program?Files
  # result: 5.0 6.0a 7.1a
  SDKS_FIND_VERSIONS = $(patsubst %/.,%,$(subst \
    ?$1/Microsoft?SDKs/Windows/v, ,?$(subst $(space),?,$(wildcard $(subst ?,\ ,$1)/Microsoft\ SDKs/Windows/v*/.))))

  # filter and sort versions of Visual Studio 2005-2015
  # $1 - .NET .NET?2003 8 9.0 10.0 11.0 12.0 14.0
  # result: 14.0 12.0 11.0 10.0 9.0 8
  KITS_SORT_VERSIONS_2012 = $(addsuffix .0,$(call reverse,$(call sort_numbers,$(subst \
    .0,,$(filter 14.0 12.0 11.0 10.0 9.0,$1))))) $(filter 8,$1)


# SDK:=C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A
# SDK:=C:\Program Files (x86)\Windows Kits\8.1




WindowsSdkBinPath=C:\Program Files (x86)\Windows Kits\10\bin\
WindowsSdkDir=C:\Program Files (x86)\Windows Kits\10\
WindowsSDKLibVersion=10.0.15063.0\
WindowsSdkVerBinPath=C:\Program Files (x86)\Windows Kits\10\bin\10.0.15063.0\
WindowsSDKVersion=10.0.15063.0\

# 7) SDK_VER - Windows SDK version, e.g: 6.0 6.0a 6.1 7.0 7.0a 7.1 7.1a 8.0 8.0a 8.1 8.1a 10
#   may be specified explicitly if it's not possible to deduce SDK_VER automatically
"/Microsoft SDKs/Windows/v6.0"
"/Microsoft SDKs/Windows/v6.0a"
"/Microsoft SDKs/Windows/v6.1"
"/Microsoft SDKs/Windows/v7.0"
"/Microsoft SDKs/Windows/v7.0a"
"/Microsoft SDKs/Windows/v7.1"
"/Microsoft SDKs/Windows/v7.1a"
"/Windows Kits/8.0/Lib/win8/um/x86/kernel32.Lib"
"/Windows Kits/8.1/Lib/winv6.3/um/x86/kernel32.Lib"


#
# $ reg query "HKCU\SOFTWARE\Microsoft\Microsoft SDKs\Windows" /v "CurrentInstallFolder"
# HKEY_CURRENT_USER\SOFTWARE\Microsoft\Microsoft SDKs\Windows
# CurrentInstallFolder    REG_SZ    C:\Program Files\Microsoft SDKs\Windows\v6.1\

# $ reg query "HKLM\SOFTWARE\Microsoft\Microsoft SDKs\Windows" /v "CurrentInstallFolder"
# HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SDKs\Windows
# CurrentInstallFolder    REG_SZ    C:\Program Files\Microsoft SDKs\Windows\v7.0\


C:\Program Files (x86)\Windows Kits\10\Include\10.0.10240.0\um
C:\Program Files (x86)\Windows Kits\10\Lib\10.0.10240.0\um\x86
