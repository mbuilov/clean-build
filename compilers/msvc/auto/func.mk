#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# MSVC auto-configuration helper functions, included by $(CLEAN_BUILD_DIR)/compilers/msvc/auto/conf.mk

# tool path must use forward slashes, must be in double-quotes if contains spaces, e.g.:
# "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin\cl.exe"
CONF_NORMALIZE_TOOL = $(call ifaddq,$(subst ?, ,$(subst /,\,$(patsubst "%",%,$(subst $(space),?,$1)))))

# normalize directory path: replace spaces with ?, remove double-quotes, make all slashes backward, remove trailing back-slash, e.g.:
# "a\b\c d\e\" -> a/b/c?d/e
CONF_NORMALIZE_DIR = $(patsubst %/,%,$(subst \,/,$(patsubst "%",%,$(subst $(space),?,$1))))

# convert path to printable form
# a/b/c?d/e -> "a\b\c d\e"
CONF_PATH_PRINTABLE = $(call ifaddq,$(subst ?, ,$(subst /,\,$1)))

# get paths to "Program Files" and "Program Files (x86)" directories
# note: ProgramW6432 appear starting with Windows 7
# ------------------------------------------------------------------------
#       | ProgramFiles            ProgramFiles(x86)       ProgramW6432    
# ------|-----------------------------------------------------------------
# win64 | C:\Program Files        C:\Program Files (x86)  C:\Program Files
# wow64 | C:\Program Files (x86)  C:\Program Files (x86)  C:\Program Files
# win32 | C:\Program Files                                                
# ------------------------------------------------------------------------
# result on win64: C:/Program?Files C:/Program?Files?(x86)
# result on wow64: C:/Program?Files?(x86) C:/Program?Files
# result on win32: C:/Program?Files
GET_PROGRAM_FILES_DIRS = $(call uniq,$(foreach \
  v,ProgramFiles ProgramFiles$(open_brace)x86$(close_brace) ProgramW6432,$(if \
  $(filter-out undefined,$(origin $v)),$(subst $(space),?,$(subst \,/,$($v))))))

# variable ProgramFiles(x86) is defined only under 64-bit Windows
IS_WIN_64 := $(filter-out undefined,$(origin ProgramFiles$(open_brace)x86$(close_brace)))

# list of processor architectures of executables that may be run on build host
# note: 64-bit Windows can run x86 executables
TOOLCHAIN_CPUS := $(TCPU)$(if $(filter x86_64,$(TCPU)), x86)$(if $(IS_WIN_64),$(if $(filter x86,$(TCPU)), x86_64))

# check if file exist and if it is, return path to the parent directory of that file
# $1 - path to file, e.g.: C:/Program?Files?(x86)/Microsoft?Visual?Studio?9.0/VC/lib/amd64/msvcrt.lib
# returns: C:\Program?Files?(x86)\Microsoft?Visual?Studio?9.0\VC\lib\amd64
CONF_CHECK_FILE_PATH = $(subst /,\,$(patsubst %/,%,$(dir $(subst $(space),?,$(wildcard $(subst ?,\ ,$1))))))

# search file(s) in the paths by patterns, return the path where the file(s) were found
# $1 - file patterns, e.g.: VC/bin/cl.exe (possibly be a mask, like: VC/Tools/MSVC/*/bin/HostX86/x86/cl.exe, spaces replaced with ?)
# $2 - paths to look in, e.g. C:/Program?Files/Microsoft?Visual?Studio/2017/Community/ C:/Program?Files/Microsoft?Visual?Studio?14.0/
# result (may be a list): C:/Program?Files/Microsoft?Visual?Studio?14.0/ C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
# note: check first pattern in all paths, then second pattern in all paths and so on
CONF_SEARCH_FILE_W   = $(if $1,$(call CONF_SEARCH_FILE_W1,$1,$2,$(call CONF_SEARCH_FILE_W_1,$(firstword $1),$2)))
CONF_SEARCH_FILE_W_1 = $(if $2,$(call CONF_SEARCH_FILE_W_2,$1,$2,$(wildcard $(subst ?,\ ,$(firstword $2)$1))))
CONF_SEARCH_FILE_W_2 = $(if $3,$(firstword $2) $3,$(call CONF_SEARCH_FILE_W_1,$1,$(wordlist 2,999999,$2)))
CONF_SEARCH_FILE_W1  = $(if $3,$3,$(call CONF_SEARCH_FILE_W,$(wordlist 2,999999,$1),$2))

# same as CONF_SEARCH_FILE_W, but do not return the path to the found file(s)
# $1 - file patterns, e.g.: VC/bin/cl.exe (possibly be a mask, like: VC/Tools/MSVC/*/bin/HostX86/x86/cl.exe, spaces replaced with ?)
# $2 - paths to look in, e.g. C:/Program?Files/Microsoft?Visual?Studio/2017/Community/ C:/Program?Files/Microsoft?Visual?Studio?14.0/
# result (may be a list): C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
# note: check first pattern in all paths, then second pattern in all paths and so on
CONF_SEARCH_FILE   = $(if $1,$(call CONF_SEARCH_FILE1,$1,$2,$(call CONF_SEARCH_FILE_1,$(firstword $1),$2)))
CONF_SEARCH_FILE_1 = $(if $2,$(call CONF_SEARCH_FILE_2,$1,$2,$(wildcard $(subst ?,\ ,$(firstword $2)$1))))
CONF_SEARCH_FILE_2 = $(if $3,$3,$(call CONF_SEARCH_FILE_1,$1,$(wordlist 2,999999,$2)))
CONF_SEARCH_FILE1  = $(if $3,$3,$(call CONF_SEARCH_FILE,$(wordlist 2,999999,$1),$2))

# like CONF_SEARCH_FILE, but $1 - name of the macro that returns file patterns (VCCL_2005_PATTERN_GEN_VC or VCCL_2005_PATTERN_GEN_VS)
# $2 - paths to look in, e.g. C:/Program?Files/Microsoft?Visual?Studio/2017/Community/ C:/Program?Files/Microsoft?Visual?Studio?14.0/
# $3 - list of second parameters for the macro $1
# note: first parameter for the macro $1 will be the path where the search takes place, second parameter - one of $3
# result (may be a list): C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
# note: check first pattern in all paths, then second pattern in all paths and so on
CONF_SEARCH_FILE_P   = $(if $3,$(call CONF_SEARCH_FILE_P1,$1,$2,$3,$(call CONF_SEARCH_FILE_P_1,$1,$2,$(firstword $3))))
CONF_SEARCH_FILE_P_1 = $(if $2,$(call CONF_SEARCH_FILE_P_2,$1,$2,$3,$(wildcard $(subst ?,\ ,$(firstword $2)$(call $1,$(firstword $2),$3)))))
CONF_SEARCH_FILE_P_2 = $(if $4,$4,$(call CONF_SEARCH_FILE_P_1,$1,$(wordlist 2,999999,$2),$3))
CONF_SEARCH_FILE_P1  = $(if $4,$4,$(call CONF_SEARCH_FILE_P,$1,$2,$(wordlist 2,999999,$3)))

# query path value in the registry under "HKLM\SOFTWARE\Microsoft\" or "HKLM\SOFTWARE\Wow6432Node\Microsoft\"
# $1 - registry key sub path, e.g.: VisualStudio\SxS\VC7 or VisualStudio\SxS\VS7 or VisualStudio\6.0\Setup\Microsoft Visual C++
# $2 - registry key name, e.g.: 14.0 or ProductDir
# $3 - empty or \Wow6432Node
# result: for VC7 - C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/VC/
# result: for VS7 - C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/
# note: result will be with trailing backslash
# note: value of "VisualStudio\6.0\Setup\Microsoft Visual C++\ProductDir" key does not end with slash, e.g:
#  "C:\Program Files (x86)\Microsoft Visual Studio\VC98"
MS_REG_QUERY_PATH = $(addsuffix /,$(patsubst %/,%,$(subst \,/,$(subst ?$2?REG_SZ?,,$(word \
  2,$(subst HKEY_LOCAL_MACHINE\SOFTWARE$3\Microsoft\$1, ,xxx$(subst $(space),?,$(strip $(shell \
  reg query "HKLM\SOFTWARE$3\Microsoft\$1" /v "$2" 2>&1)))))))))

# search file(s) by the patterns in the paths found in registry, return the path where the file(s) were found
# $1 - file patterns, e.g.: VC/bin/cl.exe (possibly be a mask, like: VC/Tools/MSVC/*/bin/HostX86/x86/cl.exe, spaces replaced with ?)
# $2 - registry key sub path, e.g.: VisualStudio\SxS\VC7 or VisualStudio\SxS\VS7 or VisualStudio\6.0\Setup\Microsoft Visual C++
# $3 - registry key name, e.g.: 14.0 or ProductDir
# $4 - if not empty, then also check Wow6432Node (applicable only on Win64), tip: use $(IS_WIN_64)
# result (may be a list): C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/ C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
MSR_SEARCH_FILE_W  = $(if $1,$(call MSR_SEARCH_FILE_W1,$1,$2,$3,$4,$(call MS_REG_QUERY_PATH,$2,$3)))
MSR_SEARCH_FILE_W1 = $(call MSR_SEARCH_FILE_W2,$1,$2,$3,$4,$5,$(if $5,$(wildcard $(subst ?,\ ,$5$(firstword $1)))))
MSR_SEARCH_FILE_W2 = $(if $6,$5 $6,$(call MSR_SEARCH_FILE_W3,$1,$5,$(if $4,$(call MS_REG_QUERY_PATH,$2,$3,\Wow6432Node))))
MSR_SEARCH_FILE_W3 = $(call MSR_SEARCH_FILEW4,$1,$2,$3,$(if $3,$(wildcard $(subst ?,\ ,$3$(firstword $1)))))
MSR_SEARCH_FILEW4 = $(if $4,$3 $4,$(call MSR_SEARCH_FILEW5,$(wordlist 2,999999,$1),$2,$3))
MSR_SEARCH_FILEW5 = $(if $1,$(call MSR_SEARCH_FILEW6,$1,$2,$3,$(if $2,$(wildcard $(subst ?,\ ,$2$(firstword $1))))))
MSR_SEARCH_FILEW6 = $(if $4,$2 $4,$(call MSR_SEARCH_FILEW4,$1,$2,$3,$(if $3,$(wildcard $(subst ?,\ ,$3$(firstword $1))))))

# same as MSR_SEARCH_FILE_W, but do not return the path to the found file(s)
# result (may be a list): C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
MSR_SEARCH_FILE = $(wordlist 2,999999,$(MSR_SEARCH_FILE_W))

# like MSR_SEARCH_FILE, but $1 - name of the macro that returns file patterns (VCCL_2005_PATTERN_GEN_VC or VCCL_2005_PATTERN_GEN_VS)
# $2 - registry key sub path, e.g.: VisualStudio\SxS\VC7 or VisualStudio\SxS\VS7 or VisualStudio\6.0\Setup\Microsoft Visual C++
# $3 - registry key name, e.g.: 14.0 or ProductDir
# $4 - if not empty, then also check Wow6432Node (applicable only on Win64), tip: use $(IS_WIN_64)
# $5 - list of second parameters for the macro $1
# note: first parameter for the macro $1 will be the path where the search takes place, second parameter - one of $5
# result (may be a list): C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
MSR_SEARCH_FILE_P  = $(if $5,$(call MSR_SEARCH_FILE_P1,$1,$2,$3,$4,$5,$(call MS_REG_QUERY_PATH,$2,$3)))
MSR_SEARCH_FILE_P1 = $(call MSR_SEARCH_FILE_P2,$1,$2,$3,$4,$5,$6,$(if $6,$(wildcard $(subst ?,\ ,$6$(call $1,$6,$(firstword $5))))))
MSR_SEARCH_FILE_P2 = $(if $7,$7,$(call MSR_SEARCH_FILE_P3,$1,$5,$6,$(if $4,$(call MS_REG_QUERY_PATH,$2,$3,\Wow6432Node))))
MSR_SEARCH_FILE_P3 = $(call MSR_SEARCH_FILEP4,$1,$2,$3,$4,$(if $4,$(wildcard $(subst ?,\ ,$4$(call $1,$4,$(firstword $2))))))
MSR_SEARCH_FILEP4 = $(if $5,$5,$(call MSR_SEARCH_FILEP5,$1,$(wordlist 2,999999,$2),$3,$4))
MSR_SEARCH_FILEP5 = $(if $2,$(call MSR_SEARCH_FILEP6,$1,$2,$3,$4,$(if $3,$(wildcard $(subst ?,\ ,$3$(call $1,$3,$(firstword $2)))))))
MSR_SEARCH_FILEP6 = $(if $5,$5,$(call MSR_SEARCH_FILEP4,$1,$2,$3,$4,$(if $4,$(wildcard $(subst ?,\ ,$4$(call $1,$4,$(firstword $2)))))))

# search file(s) by the patterns in the paths found in registry, may return the path where the file(s) were found (depends on macro $3)
# $1 - file patterns, e.g.: VC/bin/cl.exe (possibly be a mask, like: VC/Tools/MSVC/*/bin/HostX86/x86/cl.exe, spaces replaced with ?)
# $2 - registry key sub paths and corresponding key names, e.g. VisualStudio\14.0\Setup\VC?ProductDir VisualStudio\SxS\VC7?14.0
# $3 - macro to call: MSR_SEARCH_FILE_W, MSR_SEARCH_FILE or MSR_SEARCH_FILE_P
# $4 - if $1 - is a macro, then $4 - list of second parameters for that macro
MSR_SEARCH_FILEX  = $(if $2,$(call MSR_SEARCH_FILEX1,$1,$2,$3,$4,$(subst ?, ,$(firstword $2))))
MSR_SEARCH_FILEX1 = $(call MSR_SEARCH_FILEX2,$1,$2,$3,$4,$(call $3,$1,$(firstword $5),$(lastword $5),$(IS_WIN_64),$4))
MSR_SEARCH_FILEX2 = $(if $5,$5,$(call MSR_SEARCH_FILEX,$1,$(wordlist 2,999999,$2),$3,$4))

# search file(s) by the patterns in the paths found in registry, return the path where the file(s) were found
# $1 - file patterns, e.g.: VC/bin/cl.exe (possibly be a mask, like: VC/Tools/MSVC/*/bin/HostX86/x86/cl.exe, spaces replaced with ?)
# $2 - registry key sub paths and corresponding key names, e.g. VisualStudio\14.0\Setup\VC?ProductDir VisualStudio\SxS\VC7?14.0
# result (may be a list): C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/ C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
MSR_SEARCH_FILE_IN_W = $(call MSR_SEARCH_FILEX,$1,$2,MSR_SEARCH_FILE_W)

# same as MSR_SEARCH_FILE_INW, but do not return the path to the found file(s)
# result (may be a list): C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
MSR_SEARCH_FILE_IN = $(call MSR_SEARCH_FILEX,$1,$2,MSR_SEARCH_FILE)

# like MSR_SEARCH_FILE_IN, but $1 - name of the macro that returns file to find (VCCL_2005_PATTERN_GEN_VC or VCCL_2005_PATTERN_GEN_VS)
# $2 - registry key sub paths and corresponding key names, e.g. VisualStudio\14.0\Setup\VC?ProductDir VisualStudio\SxS\VC7?14.0
# $3 - list of second parameters for the macro $1
# note: first parameter for the macro $1 will be the path where the search takes place, second parameter - one of $3
# result (may be a list): C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
MSR_SEARCH_FILE_IN_P = $(call MSR_SEARCH_FILEX,$1,$2,MSR_SEARCH_FILE_P,$3)

# there may be more than one file found - take the newer one, e.g.:
#  $1=bin/HostX86/x64/cl.exe
#  $2=C:/Program?Files/Microsoft?Visual?Studio/2017/Community/ \
#     C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.10.25017/bin/HostX86/x64/cl.exe \
#     C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x64/cl.exe
# result: C:/Program?Files/Microsoft?Visual?Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x64/cl.exe
CONF_SELECT_LATEST1 = $(patsubst %,$2%$1,$(lastword $(sort $(subst $1?$2, ,$(patsubst %,$1?%?$2,$(subst $(space),?,$3))))))
CONF_SELECT_LATEST  = $(call CONF_SELECT_LATEST1,$1,$(firstword $2),$(wordlist 2,999999,$2))

# query version of cl.exe
# Оптимизирующий 32-разрядный компилятор Microsoft (R) C/C++ версии 15.00.30729.01 для 80x86 -> 15 00 30729 01
# $1 - "C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe"
CL_QUERY_VER = $(subst ., ,$(lastword $(foreach v,$(filter 0% 1% 2% 3% 4% 5% 6% 7% 8% 9%,$(shell \
  $(subst \,/,$1) 2>&1)),$(if $(word 3,$(subst ., ,$v)),$v))))

# query version of cl.exe and map it to MSVC++ version, e.g.: 15 00 30729 01 -> 9.00
# $1 - "C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe"
# note: use MSC_VER_... constants defined in $(CLEAN_BUILD_DIR)/compilers/msvc/cmn.mk
CL_QUERY_MSVC_VER  = $(call CL_QUERY_MSVC_VER1,$1,$(CL_QUERY_VER))
CL_QUERY_MSVC_VER1 = $(if $2,$(if $(filter undefined environment,$(origin MSC_VER_$(firstword $2))),$(error \
  unknown major version number $(firstword $2) of $1),$(MSC_VER_$(firstword $2)).$(word 2,$2)),$(error \
  unable to determine version of $1))

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,CONF_NORMALIZE_TOOL CONF_NORMALIZE_DIR CONF_PATH_PRINTABLE GET_PROGRAM_FILES_DIRS \
  IS_WIN_64 TOOLCHAIN_CPUS CONF_CHECK_FILE_PATH \
  CONF_SEARCH_FILE_W CONF_SEARCH_FILE_W_1 CONF_SEARCH_FILE_W_2 CONF_SEARCH_FILE_W1 \
  CONF_SEARCH_FILE CONF_SEARCH_FILE_1 CONF_SEARCH_FILE_2 CONF_SEARCH_FILE1 \
  CONF_SEARCH_FILE_P CONF_SEARCH_FILE_P_1 CONF_SEARCH_FILE_P_2 CONF_SEARCH_FILE_P1 MS_REG_QUERY_PATH \
  MSR_SEARCH_FILE_W MSR_SEARCH_FILE_W1 MSR_SEARCH_FILE_W2 MSR_SEARCH_FILE_W3 \
  MSR_SEARCH_FILEW4 MSR_SEARCH_FILEW5 MSR_SEARCH_FILEW6 MSR_SEARCH_FILE \
  MSR_SEARCH_FILE_P MSR_SEARCH_FILE_P1 MSR_SEARCH_FILE_P2 MSR_SEARCH_FILE_P3 \
  MSR_SEARCH_FILEP4 MSR_SEARCH_FILEP5 MSR_SEARCH_FILEP6 \
  MSR_SEARCH_FILEX MSR_SEARCH_FILEX1 MSR_SEARCH_FILEX2 MSR_SEARCH_FILE_IN_W MSR_SEARCH_FILE_IN MSR_SEARCH_FILE_IN_P \
  CONF_SELECT_LATEST1 CONF_SELECT_LATEST CL_QUERY_VER CL_QUERY_MSVC_VER CL_QUERY_MSVC_VER1)
