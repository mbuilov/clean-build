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
# UMLIBPATH - paths to user-mode libraries (without quotes, spaces must be replaced with ?)
# UMINCLUDE - paths to user-mode headers   (without quotes, spaces must be replaced with ?)
#
# example:
#
# UMLIBPATH := C:\Program?Files?(x86)\Windows?Kits\8.1\Lib\winv6.3\um\x86
# UMINCLUDE := C:\Program?Files?(x86)\Windows?Kits\8.1\Include\um
#
# note: UMLIBPATH or UMINCLUDE may be defined with empty values in project configuration makefile or in command line

#################################################################################################################
# input for autoconfiguration:
#
# 1) SDK - Software Development Kit path (without quotes)
#   may be specified if autoconfiguration based on values of environment variables fails, e.g.:
#     SDK=C:\Program Files\Microsoft Visual Studio .NET 2003\Vc7\PlatformSDK
#     SDK=C:\Program Files\Microsoft SDK
#     SDK=C:\Program Files\Microsoft Platform SDK for Windows XP SP2
#     SDK=C:\Program Files\Microsoft Platform SDK for Windows Server 2003 R2
#     SDK=C:\Program Files\Microsoft Visual Studio 8\VC\PlatformSDK
#     SDK=C:\Program Files\Microsoft SDKs\Windows\v6.0
#     SDK=C:\Program Files\Microsoft SDKs\Windows\v6.0a
#     SDK=C:\Program Files\Microsoft SDKs\Windows\v6.1
#     SDK=C:\Program Files\Microsoft SDKs\Windows\v7.0
#     SDK=C:\Program Files\Microsoft SDKs\Windows\v7.0a
#     SDK=C:\Program Files\Microsoft SDKs\Windows\v7.1
#     SDK=C:\Program Files\Microsoft SDKs\Windows\v7.1a
#     SDK=C:\Program Files\Windows Kits\8.0
#     SDK=C:\Program Files\Windows Kits\8.1
#     SDK=C:\Program Files\Windows Kits\10
#
#   Note: Visual Studio 6.0 ships with SDK libraries (e.g. KERNEL32.LIB) and headers (e.g. WINBASE.H) as a part of its installation,
#     so SDK variable may be empty or not defined, UMLIBPATH and UMINCLUDE may be defined as empty.
#
# 2) SDK_LIB - path (without quotes) to directory of user-mode libraries, such as kernel32.lib
#   may be specified instead of SDK variable (it is ignored then), e.g.:
#     SDK_LIB=C:\Program Files\Microsoft Visual Studio\VC98\Lib
#     SDK_LIB=C:\Program Files\Microsoft Visual Studio .NET 2003\Vc7\PlatformSDK\Lib
#     SDK_LIB=C:\Program Files\Microsoft SDK\Lib
#     SDK_LIB=C:\Program Files\Microsoft Platform SDK for Windows XP SP2\Lib
#     SDK_LIB=C:\Program Files\Microsoft Platform SDK for Windows Server 2003 R2\Lib
#     SDK_LIB=C:\Program Files\Microsoft Visual Studio 8\VC\PlatformSDK\Lib
#     SDK_LIB=C:\Program Files\Microsoft SDKs\Windows\v6.0\Lib
#     SDK_LIB=C:\Program Files\Microsoft SDKs\Windows\v6.0a\Lib
#     SDK_LIB=C:\Program Files\Microsoft SDKs\Windows\v6.1\Lib
#     SDK_LIB=C:\Program Files\Microsoft SDKs\Windows\v7.0\Lib
#     SDK_LIB=C:\Program Files\Microsoft SDKs\Windows\v7.0a\Lib
#     SDK_LIB=C:\Program Files\Microsoft SDKs\Windows\v7.1\Lib
#     SDK_LIB=C:\Program Files\Microsoft SDKs\Windows\v7.1a\Lib
#     SDK_LIB=C:\Program Files\Windows Kits\8.0\Lib\win8
#     SDK_LIB=C:\Program Files\Windows Kits\8.1\Lib\winv6.3
#     SDK_LIB=C:\Program Files\Windows Kits\10\Lib\10.0.10240.0
#
# 3) SDK_VER - SDK version, e.g.: win8 winv6.3 10.0.10240.0 10.0.10586.0 10.0.14393.0 10.0.15063.0 10.0.16299.0
#   may be specified explicitly to override one deduced automatically
#
#################################################################################################################

# we need next variables to be defined: UMLIBPATH and UMINCLUDE
# (they are may be defined either in project configuration makefile or in command line)
# note: UMLIBPATH or UMINCLUDE may be defined as <empty>, so do not reset them
ifneq (,$(filter undefined environment,$(foreach v,UMLIBPATH UMINCLUDE,$(origin $v))))

# reset variables, if they are not defined in project configuration makefile or in command line
# note: SDK variable was reset in $(CLEAN_BUILD_DIR)/compilers/msvc_conf.mk
SDK_LIB:=
SDK_VER:=

ifndef SDK_LIB
  ifndef SDK

    # WindowsSdkDir is normally set by the vcvars32.bat (for Visual Studio 2015 and later), e.g.:
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
endif # !SDK_LIB

ifndef SDK_LIB
ifndef SDK

  # at last, check registry and standard places in Program Files - to define SDK_LIB

  # select SDK based on value of WINVARIANT variable
  WINVARIANT_VER := $(_WIN32_WINNT_$(WINVARIANT))

  ifeq (,$(call is_less,$(WINVARIANT_VER),$(_WIN32_WINNT_WINTHRESHOLD)))
    # need Windows 10 SDK

    # select appropriate kernel32.lib for the $(CPU)
    KERNEL32LIB_SDK_PREFIXED := um/$(CPU:x86_64=x64)/kernel32.Lib

    # look for C:/Program Files/Windows Kits/10/Lib/10.0.16299.0/um/x86/kernel32.Lib
    SDK_LIB := $(call VS_2017_SELECT_LATEST_ENTRY,$(KERNEL32LIB_SDK_PREFIXED),$(call \
      VS_REG_FIND_FILE_WHERE,Lib/$(SDK_VER)*/$(KERNEL32LIB_SDK_PREFIXED),Microsoft SDKs\Windows\v10.0,InstallationFolder,$(IS_WIN_64)))

    ifndef SDK_LIB
      # check standard places
      # e.g.: C:/Program?Files/ C:/Program?Files?(x86)/
      PROGRAM_FILES_PLACES := $(addsuffix /,$(GET_PROGRAM_FILES_DIRS))

      # look for C:/Program Files/Windows Kits/10/Lib/10.0.16299.0/um/x86/kernel32.Lib
      SDK_LIB := $(call VS_2017_SELECT_LATEST_ENTRY,$(KERNEL32LIB_SDK_PREFIXED),$(call \
        VS_FIND_FILE_WHERE,Windows Kits/10/Lib/$(SDK_VER)*/$(KERNEL32LIB_SDK_PREFIXED),$(PROGRAM_FILES_PLACES)))
    endif

  else ifeq (,$(call is_less,$(WINVARIANT_VER),$(_WIN32_WINNT_WINBLUE)))
    # need Win8.1 SDK

    # select appropriate kernel32.lib for the $(CPU)
    KERNEL32LIB_SDK_PREFIXED := um/$(CPU:x86_64=x64)/kernel32.Lib

    # look for C:/Program Files/Windows Kits/8.1/Lib/winv6.3/um/x86/kernel32.lib
    SDK_LIB := $(call VS_2017_SELECT_LATEST_ENTRY,$(KERNEL32LIB_SDK_PREFIXED),$(call \
      VS_REG_FIND_FILE_WHERE,Lib/$(SDK_VER)*/$(KERNEL32LIB_SDK_PREFIXED),Microsoft SDKs\Windows\v8.1,InstallationFolder,$(IS_WIN_64)))

    ifndef SDK_LIB
      # check standard places
      # e.g.: C:/Program?Files/ C:/Program?Files?(x86)/
      PROGRAM_FILES_PLACES := $(addsuffix /,$(GET_PROGRAM_FILES_DIRS))

      # look for C:/Program Files/Windows Kits/8.1/Lib/winv6.3/um/x86/kernel32.lib
      SDK_LIB := $(call VS_2017_SELECT_LATEST_ENTRY,$(KERNEL32LIB_SDK_PREFIXED),$(call \
        VS_FIND_FILE_WHERE,Windows Kits/8.1/Lib/$(SDK_VER)*/$(KERNEL32LIB_SDK_PREFIXED),$(PROGRAM_FILES_PLACES)))
    endif

  else ifeq (,$(call is_less,$(WINVARIANT_VER),$(_WIN32_WINNT_WIN8)))
    # need Win8 SDK

    # select appropriate kernel32.lib for the $(CPU)
    KERNEL32LIB_SDK_PREFIXED := um/$(CPU:x86_64=x64)/kernel32.Lib

    # look for C:/Program Files/Windows Kits/8.0/Lib/win8/um/x86/kernel32.lib
    SDK_LIB := $(call VS_2017_SELECT_LATEST_ENTRY,$(KERNEL32LIB_SDK_PREFIXED),$(call \
      VS_REG_FIND_FILE_WHERE,Lib/$(SDK_VER)*/$(KERNEL32LIB_SDK_PREFIXED),Microsoft SDKs\Windows\v8.0,InstallationFolder,$(IS_WIN_64)))

    ifndef SDK_LIB
      # check standard places
      # e.g.: C:/Program?Files/ C:/Program?Files?(x86)/
      PROGRAM_FILES_PLACES := $(addsuffix /,$(GET_PROGRAM_FILES_DIRS))

      # look for C:/Program Files/Windows Kits/8.0/Lib/win8/um/x86/kernel32.lib
      SDK_LIB := $(call VS_2017_SELECT_LATEST_ENTRY,$(KERNEL32LIB_SDK_PREFIXED),$(call \
        VS_FIND_FILE_WHERE,Windows Kits/8.0/Lib/$(SDK_VER)*/$(KERNEL32LIB_SDK_PREFIXED),$(PROGRAM_FILES_PLACES)))
    endif





    ifdef SDK
      SDK := $(notdir $(SDK:/$(KERNEL32LIB_SDK10_PREFIXED)=))
      ifndef SDK_VER
        SDK_VER := $(notdir $(SDK:/$(KERNEL32LIB_SDK10_PREFIXED)=))
      endif






	    VCCL := $(call VS_2017_SELECT_LATEST_ENTRY,$(VCCL_2017_PREFIXED),$(call \
		    VS_REG_SEARCH,Tools/MSVC/*/$(VCCL_2017_PREFIXED),$(call VCCL_REG_KEYS_VC,15.0)))


	HKLM\SOFTWARE\Wow6432Node\Microsoft\Microsoft SDKs\Windows\v10.0  InstallationFolder C:\Program Files (x86)\Windows Kits\10\
	/cygdrive/c/Program Files (x86)/Windows Kits/10/Lib/10.0.16299.0/um/x86/kernel32.Lib

    SDK := $(call VS_REG_FIND_FILE,Lib/*/um/x86/kernel32.Lib,Microsoft SDKs\Windows\v10.0,InstallationFolder)

# find file by pattern in the path found in registry
# $1 - file to find, e.g.: VC/bin/cl.exe (possibly be a mask, like: VC/Tools/MSVC/*/bin/HostX86/x86/cl.exe)
# $2 - registry key sub path, e.g.: VisualStudio\SxS\VC7 or VisualStudio\SxS\VS7 or VisualStudio\6.0\Setup\Microsoft Visual C++
# $3 - registry key name, e.g.: 14.0 or ProductDir
# $4 - if not empty, then check Wow6432Node (only on Win64)
# result (may be a list): C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
VS_REG_FIND_FILE  = $(call VS_REG_FIND_FILE1,$1,$(call VS_REG_QUERY,$2,$3),$2,$3,$4)


	/cygdrive/c/Program\ Files\ \(x86\)/Microsoft\ SDKs/Windows/v7.1A/Lib/x64/Kernel32.Lib

7.1a              HKLM\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v7.1A  InstallationFolder C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A\  good
7.1a  HKLM\SOFTWARE\Wow6432Node\Microsoft\Microsoft SDKs\Windows\v7.1A  InstallationFolder C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A\  good




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

#     SDK_LIB=C:\Program Files\Microsoft Visual Studio\VC98\Lib
#     SDK_LIB=C:\Program Files\Microsoft Visual Studio .NET 2003\Vc7\PlatformSDK\Lib
#     SDK_LIB=C:\Program Files\Microsoft SDK\Lib
#     SDK_LIB=C:\Program Files\Microsoft SDK\Lib\IA64
#     SDK_LIB=C:\Program Files\Microsoft Platform SDK for Windows XP SP2\Lib
#     SDK_LIB=C:\Program Files\Microsoft Platform SDK for Windows Server 2003 R2\Lib
#     SDK_LIB=C:\Program Files\Microsoft Platform SDK for Windows Server 2003 R2\Lib\AMD64
#     SDK_LIB=C:\Program Files\Microsoft Platform SDK for Windows Server 2003 R2\Lib\IA64
#     SDK_LIB=C:\Program Files (x86)\Microsoft Visual Studio 8\VC\PlatformSDK\Lib
#     SDK_LIB=C:\Program Files (x86)\Microsoft Visual Studio 8\VC\PlatformSDK\Lib\AMD64
#     SDK_LIB=C:\Program Files (x86)\Microsoft Visual Studio 8\VC\PlatformSDK\Lib\IA64
#     SDK_LIB=C:\Program Files\Microsoft SDKs\Windows\v6.0\Lib
#     SDK_LIB=C:\Program Files\Microsoft SDKs\Windows\v6.0\Lib\x64
#     SDK_LIB=C:\Program Files\Microsoft SDKs\Windows\v6.0A\Lib
#     SDK_LIB=C:\Program Files\Microsoft SDKs\Windows\v6.0A\Lib\x64
#     SDK_LIB=C:\Program Files\Microsoft SDKs\Windows\v6.1\Lib
#     SDK_LIB=C:\Program Files\Microsoft SDKs\Windows\v6.1\Lib\x64
#     SDK_LIB=C:\Program Files\Microsoft SDKs\Windows\v7.0\Lib
#     SDK_LIB=C:\Program Files\Microsoft SDKs\Windows\v7.0\Lib\x64
#     SDK_LIB=C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\Lib
#     SDK_LIB=C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\Lib\x64
#     SDK_LIB=C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\Lib\IA64
#     SDK_LIB=C:\Program Files\Microsoft SDKs\Windows\v7.1\Lib
#     SDK_LIB=C:\Program Files\Microsoft SDKs\Windows\v7.1\Lib\x64
#     SDK_LIB=C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A\Lib
#     SDK_LIB=C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A\Lib\x64
#     SDK_LIB=C:\Program Files (x86)\Windows Kits\8.0\Lib\win8\um\x86
#     SDK_LIB=C:\Program Files (x86)\Windows Kits\8.0\Lib\win8\um\x64
#     SDK_LIB=C:\Program Files (x86)\Windows Kits\8.0\Lib\win8\um\arm
#     SDK_LIB=C:\Program Files (x86)\Windows Kits\8.1\Lib\winv6.3\um\x86
#     SDK_LIB=C:\Program Files (x86)\Windows Kits\8.1\Lib\winv6.3\um\x64
#     SDK_LIB=C:\Program Files (x86)\Windows Kits\8.1\Lib\winv6.3\um\arm
#     SDK_LIB=C:\Program Files (x86)\Windows Kits\10\Lib\10.0.10240.0\um\x86
#     SDK_LIB=C:\Program Files (x86)\Windows Kits\10\Lib\10.0.10240.0\um\x64
#     SDK_LIB=C:\Program Files (x86)\Windows Kits\10\Lib\10.0.10240.0\um\arm
#     SDK_LIB=C:\Program Files (x86)\Windows Kits\10\Lib\10.0.10240.0\um\arm64
#
