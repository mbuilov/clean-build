#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# Windows SDK auto-configuration (app-level), included by $(CLEAN_BUILD_DIR)/compilers/msvc.mk

# 6) SDK - Software Development Kit path (without quotes)
#   may be specified if autoconfiguration based on values of environment variables fails, e.g.:
#     SDK=C:\Program Files\Microsoft Visual Studio .NET 2003\Vc7\PlatformSDK
#     SDK=C:\Program Files\Microsoft Platform SDK for Windows Server 2003 R2
#     SDK=C:\Program Files\Microsoft SDKs\Windows\v7.1A
#     SDK=C:\Program Files\Windows Kits\8.1
#
#   Note: Visual Studio 6.0 contains SDK libraries (e.g. KERNEL32.LIB) and headers (e.g. WINBASE.H) as a part of its installation,
#     so SDK variable may be empty or not defined.
# 









# -------------------------- SDK -------------------------

# we need next SDK variables: UMLIBPATH and UMINCLUDE
# (they are may be defined either in project configuration makefile or in command line)
# note: UMLIBPATH or UMINCLUDE may be defined as <empty>, so do not reset them
ifneq (,$(filter undefined environment,$(foreach v,UMLIBPATH UMINCLUDE,$(origin $v))))

# reset variable, if it is not defined in project configuration makefile or in command line
SDK:=

ifndef SDK

  # WindowsSdkDir is normally set by the vcvars32.bat, e.g.:
  #  WindowsSdkDir=C:\Program Files (x86)\Windows Kits\10\
  # note: likely with trailing slash
  ifneq (undefined,$(origin WindowsSdkDir))
    SDK := $(WindowsSdkDir)

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

