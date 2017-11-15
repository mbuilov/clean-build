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

# check if file exist and if it is, return path to parent directory of that file
# $1 - path to file, e.g.: C:/Program?Files?(x86)/Microsoft?Visual?Studio?9.0/VC/lib/amd64/msvcrt.lib
# returns: C:\Program?Files?(x86)\Microsoft?Visual?Studio?9.0\VC\lib\amd64
CONF_CHECK_FILE_PATH = $(subst /,\,$(patsubst %/,%,$(dir $(subst $(space),?,$(wildcard $(subst ?,\ ,$1))))))

# find file(s) in the paths by pattern, return a path where file(s) were found
# $1 - file to find, e.g.: VC/bin/cl.exe (possibly be a mask, like: VC/Tools/MSVC/*/bin/HostX86/x86/cl.exe, may be with spaces)
# $2 - paths to look in, e.g. C:/Program?Files/Microsoft?Visual?Studio/2017/Community/ C:/Program?Files/Microsoft?Visual?Studio?14.0/
# result (may be a list): C:/Program?Files/Microsoft?Visual?Studio?14.0/ C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
CONF_FIND_FILE_WHERE  = $(if $2,$(call CONF_FIND_FILE_WHERE1,$1,$2,$(wildcard $(subst ?,\ ,$(firstword $2))$1)))
CONF_FIND_FILE_WHERE1 = $(if $3,$(firstword $2) $3,$(call CONF_FIND_FILE_WHERE,$1,$(wordlist 2,999999,$2)))

# find file(s) in the paths by pattern
# $1 - file to find, e.g.: VC/bin/cl.exe (possibly be a mask, like: VC/Tools/MSVC/*/bin/HostX86/x86/cl.exe, may be with spaces)
# $2 - paths to look in, e.g. C:/Program?Files/Microsoft?Visual?Studio/2017/Community/ C:/Program?Files/Microsoft?Visual?Studio?14.0/
# result (may be a list): C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
CONF_FIND_FILE  = $(if $2,$(call CONF_FIND_FILE1,$1,$2,$(wildcard $(subst ?,\ ,$(firstword $2))$1)))
CONF_FIND_FILE1 = $(if $3,$3,$(call CONF_FIND_FILE,$1,$(wordlist 2,999999,$2)))

# like CONF_FIND_FILE, but $1 - name of the macro that returns file to find (VCCL_2005_PATTERN_GEN_VC or VCCL_2005_PATTERN_GEN_VS)
# note: macro $1 may use $(firstword $2) - path where the search takes place
CONF_FIND_FILE_P  = $(if $2,$(call CONF_FIND_FILE_P1,$1,$2,$(wildcard $(subst ?,\ ,$(firstword $2))$($1))))
CONF_FIND_FILE_P1 = $(if $3,$3,$(call CONF_FIND_FILE_P,$1,$(wordlist 2,999999,$2)))

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

# find file(s) by pattern in the path found in registry
# $1 - file to find, e.g.: VC/bin/cl.exe (possibly be a mask, like: VC/Tools/MSVC/*/bin/HostX86/x86/cl.exe, may be with spaces)
# $2 - registry key sub path, e.g.: VisualStudio\SxS\VC7 or VisualStudio\SxS\VS7 or VisualStudio\6.0\Setup\Microsoft Visual C++
# $3 - registry key name, e.g.: 14.0 or ProductDir
# $4 - if not empty, then also check Wow6432Node (applicable only on Win64), tip: use $(IS_WIN_64)
# result (may be a list): C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/ C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
MS_REG_FIND_FILE_WHERE  = $(call MS_REG_FIND_FILE_WHERE1,$1,$(call MS_REG_QUERY_PATH,$2,$3),$2,$3,$4)
MS_REG_FIND_FILE_WHERE1 = $(call MS_REG_FIND_FILE_WHERE2,$1,$2,$(if $2,$(wildcard $(subst ?,\ ,$2)$1)),$3,$4,$5)
MS_REG_FIND_FILE_WHERE2 = $(if $3,$2 $3,$(if $6,$(call MS_REG_FIND_FILE_WHERE3,$1,$(call MS_REG_QUERY_PATH,$4,$5,\Wow6432Node))))
MS_REG_FIND_FILE_WHERE3 = $(if $2,$(call MS_REG_FIND_FILE_WHERE4,$2,$(wildcard $(subst ?,\ ,$2)$1)))
MS_REG_FIND_FILE_WHERE4 = $(if $2,$1 $2)

# same as MS_REG_FIND_FILE_WHERE, but do not return path where file was found
# result (may be a list): C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
MS_REG_FIND_FILE = $(wordlist 2,999999,$(MS_REG_FIND_FILE_WHERE))

# like MS_REG_FIND_FILE, but $1 - name of macro that returns file to find (VCCL_2005_PATTERN_GEN_VC or VCCL_2005_PATTERN_GEN_VS)
# note: macro $1 may use $2 - path where the search takes place
MS_REG_FIND_FILE_P  = $(call MS_REG_FIND_FILE_P1,$1,$(call MS_REG_QUERY_PATH,$2,$3),$2,$3,$4)
MS_REG_FIND_FILE_P1 = $(call MS_REG_FIND_FILE_P2,$1,$(if $2,$(wildcard $(subst ?,\ ,$2)$($1))),$3,$4,$5)
MS_REG_FIND_FILE_P2 = $(if $2,$2,$(if $5,$(call MS_REG_FIND_FILE_P3,$1,$(call MS_REG_QUERY_PATH,$3,$4,\Wow6432Node))))
MS_REG_FIND_FILE_P3 = $(if $2,$(wildcard $(subst ?,\ ,$2)$($1)))

# find file(s) by pattern in the paths found in registry
# $1 - file to find, e.g.: VC/bin/cl.exe (possibly be a mask, like: VC/Tools/MSVC/*/bin/HostX86/x86/cl.exe, may be with spaces)
# $2 - registry key sub paths and corresponding key names, e.g. VisualStudio\14.0\Setup\VC?ProductDir VisualStudio\SxS\VC7?14.0
# $3 - macro to call: MS_REG_FIND_FILE_WHERE, MS_REG_FIND_FILE or MS_REG_FIND_FILE_P
MS_REG_SEARCH_X  = $(if $2,$(call MS_REG_SEARCH_X1,$1,$2,$3,$(subst ?, ,$(firstword $2))))
MS_REG_SEARCH_X1 = $(call MS_REG_SEARCH_X2,$1,$2,$3,$(call $3,$1,$(firstword $4),$(lastword $4),$(IS_WIN_64)))
MS_REG_SEARCH_X2 = $(if $4,$4,$(call MS_REG_SEARCH_X,$1,$(wordlist 2,999999,$2),$3))

# find file(s) by pattern in the paths found in registry
# $1 - file to find, e.g.: VC/bin/cl.exe (possibly be a mask, like: VC/Tools/MSVC/*/bin/HostX86/x86/cl.exe, may be with spaces)
# $2 - registry key sub paths and corresponding key names, e.g. VisualStudio\14.0\Setup\VC?ProductDir VisualStudio\SxS\VC7?14.0
# result (may be a list): C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/ C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
MS_REG_SEARCH_WHERE = $(call MS_REG_SEARCH_X,$1,$2,MS_REG_FIND_FILE_WHERE)

# same as MS_REG_SEARCH_WHERE, but do not return path where file was found
# result (may be a list): C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
MS_REG_SEARCH = $(call MS_REG_SEARCH_X,$1,$2,MS_REG_FIND_FILE)

# like MS_REG_SEARCH, but $1 - name of macro that returns file to find (VCCL_2005_PATTERN_GEN_VC or VCCL_2005_PATTERN_GEN_VS)
# note: macro $1 may use $2 - path where the search is done
MS_REG_SEARCH_P = $(call MS_REG_SEARCH_X,$1,$2,MS_REG_FIND_FILE_P)

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
$(call SET_GLOBAL,CONF_NORMALIZE_TOOL CONF_NORMALIZE_DIR CONF_PATH_PRINTABLE GET_PROGRAM_FILES_DIRS IS_WIN_64 CONF_CHECK_FILE_PATH \
  CONF_FIND_FILE_WHERE CONF_FIND_FILE_WHERE1 CONF_FIND_FILE CONF_FIND_FILE1 CONF_FIND_FILE_P CONF_FIND_FILE_P1 MS_REG_QUERY_PATH \
  MS_REG_FIND_FILE_WHERE MS_REG_FIND_FILE_WHERE1 MS_REG_FIND_FILE_WHERE2 MS_REG_FIND_FILE_WHERE3 MS_REG_FIND_FILE_WHERE4 \
  MS_REG_FIND_FILE MS_REG_FIND_FILE_P MS_REG_FIND_FILE_P1 MS_REG_FIND_FILE_P2 MS_REG_FIND_FILE_P3 \
  MS_REG_SEARCH_X MS_REG_SEARCH_X1 MS_REG_SEARCH_X2 MS_REG_SEARCH_WHERE MS_REG_SEARCH MS_REG_SEARCH_P \
  CONF_SELECT_LATEST1 CONF_SELECT_LATEST CL_QUERY_VER CL_QUERY_MSVC_VER CL_QUERY_MSVC_VER1)
