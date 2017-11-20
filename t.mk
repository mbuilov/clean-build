space:=
space := $(space) $(space)
WWW = $(info wildcard: $1)C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/12.32.12/bin/HostX64/x86/cl.exe C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/13.32.12/bin/HostX64/x86/cl.exe

# replace [0-9] characters with .
repl09 = $(subst 0,.,$(subst 1,.,$(subst 2,.,$(subst 3,.,$(subst 4,.,$(subst \
  5,.,$(subst 6,.,$(subst 7,.,$(subst 8,.,$(subst 9,.,$1))))))))))

# 1) check number of digits: if $4 > $3 -> $2 > $1
# 2) else if number of digits are equal, check number values
is_less1 = $(if $(filter-out $3,$(lastword $(sort $3 $4))),1,$(if $(filter $3,$4),$(filter-out $1,$(lastword $(sort $1 $2)))))

# compare numbers: check if $1 < $2
# note: assume there are no leading zeros in $1 or $2
is_less = $(call is_less1,$1,$2,$(repl09),$(call repl09,$2))

# replace [0-9] characters with ' 0'
repl090 = $(subst 9, 0,$(subst 8, 0,$(subst 7, 0,$(subst 6, 0,$(subst 5, 0,$(subst \
  4, 0,$(subst 3, 0,$(subst 2, 0,$(subst 1, 0,$(subst 0, 0,$1))))))))))

# compare floating point numbers: check if $1 < $2, e.g. 1.21 < 2.4
# 1) compare integer parts (that must be present)
# 2) if they are equal, compare fractional parts (may be optional)
# note: assume there are no leading zeros in integer parts of $1 or $2
is_less_float6 = $(filter-out $1,$(lastword $(sort $1 $2)))
is_less_float5 = $(subst $(space),,$(wordlist $(words .$1),999999,$2))
is_less_float4 = $(call is_less_float6,$1$(call is_less_float5,$3,$4),$2$(call is_less_float5,$4,$3))
is_less_float3 = $(call is_less_float4,$1,$2,$(repl090),$(call repl090,$2))
is_less_float2 = $(if $(is_less),1,$(if $(filter $1,$2),$(call is_less_float3,$(word 2,$3 0),$(word 2,$4 0))))
is_less_float1 = $(call is_less_float2,$(firstword $1),$(firstword $2),$1,$2)
is_less_float  = $(call is_less_float1,$(subst ., ,$1),$(subst ., ,$2))

TOOLCHAIN_CPUS := x86_64 x86
CPU := x86
VS_CPU := x86
IS_WIN_64:=1

# for Visual Studio 2005-2015
# determine MSVC tools prefix for given TOOLCHAIN_CPU/CPU/VS_CPU combination
#
# TOOLCHAIN_CPU\CPU   x86        x86_64      arm
# ------------------|---------------------------------
#       x86         | <none>     x86_amd64/ x86_arm/
#       x86_64      | amd64_x86/ amd64/     amd64_arm/
#
# $1 - $(TOOLCHAIN_CPU)
# $2 - $(CPU)
# $3 - $(VS_CPU)
VC_TOOL_PREFIX_2005 = $(addsuffix /,$(filter-out $3,$(1:x86_64=amd64)$(addprefix _,$(subst x86_64,amd64,$(filter-out $1,$2)))))

# for use with CONF_FIND_FILE_P or MS_REG_SEARCH_P
# $1 - C:/Program?Files/Microsoft?Visual?Studio?14.0/VC/ C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/VC/
# $2 - $(TOOLCHAIN_CPU)
# result: bin/x86_arm/cl.exe (possible with spaces in result)
VCCL_2005_PATTERN_GEN_VC = $(info VCCL_2005_PATTERN_GEN_VC: $$2=$2)bin/$(call VC_TOOL_PREFIX_2005,$2,$(CPU),$(VS_CPU))cl.exe

# for use with CONF_FIND_FILE_P or MS_REG_SEARCH_P
# $1 - C:/Program?Files/Microsoft?Visual?Studio?14.0/ C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/
# $2 - $(TOOLCHAIN_CPU)
# result: VC/bin/x86_arm/cl.exe (possible with spaces in result)
VCCL_2005_PATTERN_GEN_VS = VC/$(VCCL_2005_PATTERN_GEN_VC)

# for Visual Studio 2017
# determine MSVC tools prefix for given TOOLCHAIN_CPU/CPU combination
#
# TOOLCHAIN_CPU\CPU    x86          x86_64        arm
# ------------------|---------------------------------------
#       x86         | HostX86/x86/ HostX86/x64/ HostX86/arm/
#       x86_64      | HostX64/x86/ HostX64/x64/ HostX64/arm/
#
# $1 - $(TOOLCHAIN_CPUS)
# $2 - $(CPU)
# result: HostX64/x86/ HostX86/x86/
VC_TOOL_PREFIXES_2017 = $(addsuffix /$(2:x86_64=x64)/,$(addprefix Host,$(subst x,X,$(1:x86_64=x64))))

# select appropriate compiler for the $(CPU)
# e.g.: HostX64/x86/ HostX86/x86/
VCCL_2017_PREFIXES := $(call VC_TOOL_PREFIXES_2017,$(TOOLCHAIN_CPUS),$(CPU))

# there may be more than one file found - take the newer one, e.g.:
#  $1=bin/HostX86/x64/cl.exe
#  $2=C:/Program?Files/Microsoft?Visual?Studio/2017/Community/ \
#     C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.10.25017/bin/HostX86/x64/cl.exe \
#     C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x64/cl.exe
# result: C:/Program?Files/Microsoft?Visual?Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x64/cl.exe
CONF_SELECT_LATEST1 = $(patsubst %,$2%$1,$(lastword $(sort $(subst $1?$2, ,$(patsubst %,$1?%?$2,$(subst $(space),?,$3))))))
CONF_SELECT_LATEST  = $(call CONF_SELECT_LATEST1,$1,$(firstword $2),$(wordlist 2,999999,$2))

# take the newest cl.exe among found ones, e.g.:
#  $1=bin/HostX86/x64/cl.exe
#  $2=C:/Program?Files/Microsoft?Visual?Studio/2017/Community/ \
#     C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.10.25017/bin/HostX86/x64/cl.exe \
#     C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x64/cl.exe
# result: C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x64/cl.exe
VS_2017_SELECT_LATEST_CL = $(subst ?, ,$(CONF_SELECT_LATEST))

# find files in the paths by patterns, return a path where the files were found
# $1 - files to find, e.g.: VC/bin/cl.exe (possibly be a mask, like: VC/Tools/MSVC/*/bin/HostX86/x86/cl.exe, spaces replaced with ?)
# $2 - paths to look in, e.g. C:/Program?Files/Microsoft?Visual?Studio/2017/Community/ C:/Program?Files/Microsoft?Visual?Studio?14.0/
# result (may be a list): C:/Program?Files/Microsoft?Visual?Studio?14.0/ C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
CONF_FIND_FILES_W   = $(if $1,$(call CONF_FIND_FILES_W1,$1,$2,$(call CONF_FIND_FILES_W_1,$(firstword $1),$2)))
CONF_FIND_FILES_W_1 = $(if $2,$(call CONF_FIND_FILES_W_2,$1,$2,$(call WWW,$(subst ?,\ ,$(firstword $2)$1))))
CONF_FIND_FILES_W_2 = $(if $3,$(firstword $2) $3,$(call CONF_FIND_FILES_W_1,$1,$(wordlist 2,999999,$2)))
CONF_FIND_FILES_W1  = $(if $3,$3,$(call CONF_FIND_FILES_W,$(wordlist 2,999999,$1),$2))

# like CONF_FIND_FILES, but $1 - name of the macro that returns file patterns (VCCL_2005_PATTERN_GEN_VC or VCCL_2005_PATTERN_GEN_VS)
# $2 - paths to look in, e.g. C:/Program?Files/Microsoft?Visual?Studio/2017/Community/ C:/Program?Files/Microsoft?Visual?Studio?14.0/
# $3 - list of second parameters for the macro $1
# note: first parameter for the macro $1 will be the path where the search takes place, second parameter - one of $3
# result (may be a list): C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
CONF_FIND_FILES_P   = $(if $3,$(call CONF_FIND_FILES_P1,$1,$2,$3,$(call CONF_FIND_FILES_P_1,$1,$2,$(firstword $3))))
CONF_FIND_FILES_P_1 = $(if $2,$(call CONF_FIND_FILES_P_2,$1,$2,$3,$(call WWW,$(subst ?,\ ,$(firstword $2)$(call $1,$(firstword $2),$3)))))
CONF_FIND_FILES_P_2 = $(if $4,$4,$(call CONF_FIND_FILES_P_1,$1,$(wordlist 2,999999,$2),$3))
CONF_FIND_FILES_P1  = $(if $4,$4,$(call CONF_FIND_FILES_P,$1,$2,$(wordlist 2,999999,$3)))

# query path value in the registry under "HKLM\SOFTWARE\Microsoft\" or "HKLM\SOFTWARE\Wow6432Node\Microsoft\"
# $1 - registry key sub path, e.g.: VisualStudio\SxS\VC7 or VisualStudio\SxS\VS7 or VisualStudio\6.0\Setup\Microsoft Visual C++
# $2 - registry key name, e.g.: 14.0 or ProductDir
# $3 - empty or \Wow6432Node
# result: for VC7 - C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/VC/
# result: for VS7 - C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/
# note: result will be with trailing backslash
# note: value of "VisualStudio\6.0\Setup\Microsoft Visual C++\ProductDir" key does not end with slash, e.g:
#  "C:\Program Files (x86)\Microsoft Visual Studio\VC98"
MS_REG_QUERY_PATH = $(info MS_REG_QUERY_PATH: 1=$1)$(info MS_REG_QUERY_PATH: 2=$2)$(info MS_REG_QUERY_PATH: 3=$3)C:/Program?Files/Microsoft?Visual?Studio/2017/Community/VC/$3#$(addsuffix /,$(patsubst %/,%,$(subst \,/,$(subst ?$2?REG_SZ?,,$(word \
  2,$(subst HKEY_LOCAL_MACHINE\SOFTWARE$3\Microsoft\$1, ,xxx$(subst $(space),?,$(strip $(shell \
  reg query "HKLM\SOFTWARE$3\Microsoft\$1" /v "$2" 2>&1)))))))))

# find files by patterns in the paths found in registry
# $1 - files to find, e.g.: VC/bin/cl.exe (possibly be a mask, like: VC/Tools/MSVC/*/bin/HostX86/x86/cl.exe, spaces replaced with ?)
# $2 - registry key sub path, e.g.: VisualStudio\SxS\VC7 or VisualStudio\SxS\VS7 or VisualStudio\6.0\Setup\Microsoft Visual C++
# $3 - registry key name, e.g.: 14.0 or ProductDir
# $4 - if not empty, then also check Wow6432Node (applicable only on Win64), tip: use $(IS_WIN_64)
# result (may be a list): C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/ C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
MS_REG_FIND_FILES_W  = $(call MS_REG_FIND_FILES_W1,$1,$2,$3,$4,$(call MS_REG_QUERY_PATH,$2,$3))
MS_REG_FIND_FILES_W1 = $(call MS_REG_FIND_FILES_W2,$1,$2,$3,$4,$5,$(if $5,$(call WWW,$(subst ?,\ ,$5$(firstword $1)))))
MS_REG_FIND_FILES_W2 = $(if $6,$5 $6,$(call MS_REG_FIND_FILES_W3,$1,$5,$(if $4,$(call MS_REG_QUERY_PATH,$2,$3,\Wow6432Node))))
MS_REG_FIND_FILES_W3 = $(call MS_REG_FIND_FILESW4,$1,$2,$3,$(if $3,$(call WWW,$(subst ?,\ ,$3$(firstword $1)))))
MS_REG_FIND_FILESW4 = $(if $4,$3 $4,$(call MS_REG_FIND_FILESW5,$(wordlist 2,999999,$1),$2,$3))
MS_REG_FIND_FILESW5 = $(if $1,$(call MS_REG_FIND_FILESW6,$1,$2,$3,$(if $2,$(call WWW,$(subst ?,\ ,$2$(firstword $1))))))
MS_REG_FIND_FILESW6 = $(if $4,$2 $4,$(call MS_REG_FIND_FILESW4,$1,$2,$3,$(if $3,$(call WWW,$(subst ?,\ ,$3$(firstword $1))))))

# same as MS_REG_FIND_FILES_W, but do not return a path where the files were found
# result (may be a list): C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
MS_REG_FIND_FILES = $(wordlist 2,999999,$(MS_REG_FIND_FILES_W))

# like MS_REG_FIND_FILES, but $1 - name of the macro that returns file patterns (VCCL_2005_PATTERN_GEN_VC or VCCL_2005_PATTERN_GEN_VS)
# $2 - registry key sub path, e.g.: VisualStudio\SxS\VC7 or VisualStudio\SxS\VS7 or VisualStudio\6.0\Setup\Microsoft Visual C++
# $3 - registry key name, e.g.: 14.0 or ProductDir
# $4 - if not empty, then also check Wow6432Node (applicable only on Win64), tip: use $(IS_WIN_64)
# $5 - list of second parameters for the macro $1
# note: first parameter for the macro $1 will be the path where the search takes place
# result (may be a list): C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
MS_REG_FIND_FILES_P  = $(call MS_REG_FIND_FILES_P1,$1,$2,$3,$4,$5,$(call MS_REG_QUERY_PATH,$2,$3))
MS_REG_FIND_FILES_P1 = $(call MS_REG_FIND_FILES_P2,$1,$2,$3,$4,$5,$6,$(if $6,$(call WWW,$(subst ?,\ ,$6$(call $1,$6,$(firstword $5))))))
MS_REG_FIND_FILES_P2 = $(if $7,$7,$(call MS_REG_FIND_FILES_P3,$1,$5,$6,$(if $4,$(call MS_REG_QUERY_PATH,$2,$3,\Wow6432Node))))
MS_REG_FIND_FILES_P3 = $(call MS_REG_FIND_FILESP4,$1,$2,$3,$4,$(if $4,$(call WWW,$(subst ?,\ ,$4$(call $1,$4,$(firstword $2))))))
MS_REG_FIND_FILESP4 = $(if $5,$5,$(call MS_REG_FIND_FILESP5,$1,$(wordlist 2,999999,$2),$3,$4))
MS_REG_FIND_FILESP5 = $(if $2,$(call MS_REG_FIND_FILESP6,$1,$2,$3,$4,$(if $3,$(call WWW,$(subst ?,\ ,$3$(call $1,$3,$(firstword $2)))))))
MS_REG_FIND_FILESP6 = $(if $5,$5,$(call MS_REG_FIND_FILESP4,$1,$2,$3,$4,$(if $4,$(call WWW,$(subst ?,\ ,$4$(call $1,$4,$(firstword $2)))))))

# find files by patterns in the paths found in registry
# $1 - files to find, e.g.: VC/bin/cl.exe (possibly be a mask, like: VC/Tools/MSVC/*/bin/HostX86/x86/cl.exe, may be with spaces)
# $2 - registry key sub paths and corresponding key names, e.g. VisualStudio\14.0\Setup\VC?ProductDir VisualStudio\SxS\VC7?14.0
# $3 - macro to call: MS_REG_FIND_FILES_W, MS_REG_FIND_FILES or MS_REG_FIND_FILES_P
# $4 - if $1 - is a macro, then $4 - list of second parameters for that macro
MS_REG_SEARCH_X  = $(if $2,$(call MS_REG_SEARCH_X1,$1,$2,$3,$4,$(subst ?, ,$(firstword $2))))
MS_REG_SEARCH_X1 = $(call MS_REG_SEARCH_X2,$1,$2,$3,$4,$(call $3,$1,$(firstword $5),$(lastword $5),$(IS_WIN_64),$4))
MS_REG_SEARCH_X2 = $(if $5,$5,$(call MS_REG_SEARCH_X,$1,$(wordlist 2,999999,$2),$3,$4))

# find files by pattern in the paths found in registry
# $1 - files to find, e.g.: VC/bin/cl.exe (possibly be a mask, like: VC/Tools/MSVC/*/bin/HostX86/x86/cl.exe, spaces replaced with ?)
# $2 - registry key sub paths and corresponding key names, e.g. VisualStudio\14.0\Setup\VC?ProductDir VisualStudio\SxS\VC7?14.0
# result (may be a list): C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/ C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
MS_REG_SEARCH_W = $(call MS_REG_SEARCH_X,$1,$2,MS_REG_FIND_FILES_W)

# same as MS_REG_SEARCH_W, but do not return a path where the files were found
# result (may be a list): C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
MS_REG_SEARCH = $(call MS_REG_SEARCH_X,$1,$2,MS_REG_FIND_FILES)

# like MS_REG_SEARCH, but $1 - name of the macro that returns file to find (VCCL_2005_PATTERN_GEN_VC or VCCL_2005_PATTERN_GEN_VS)
# $2 - registry key sub paths and corresponding key names, e.g. VisualStudio\14.0\Setup\VC?ProductDir VisualStudio\SxS\VC7?14.0
# $3 - list of second parameters for the macro $1
# note: first parameter for the macro $1 will be the path where the search takes place
# result (may be a list): C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
MS_REG_SEARCH_P = $(call MS_REG_SEARCH_X,$1,$2,MS_REG_FIND_FILES_P,$3)

# -------------

VS_COMNS_2017 := C:/Program?Files/Microsoft?Visual?Studio/2017/Community/ C:/Program?Files/Microsoft?Visual?Studio/2017/Enterprise/

# try to find Visual Studio 2017 cl.exe in the paths of VS*COMNTOOLS variables, e.g.:
#  C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x86/cl.exe
VCCL := $(call VS_2017_SELECT_LATEST_CL,cl.exe,$(call \
  CONF_FIND_FILES_W,$(VCCL_2017_PREFIXES:%=VC/Tools/MSVC/*/bin/%cl.exe),$(VS_COMNS_2017)))

# C:\Program?Files\Microsoft?Visual?Studio\2017\Community\Common7\Tools\ -> C:/Program?Files/Microsoft?Visual?Studio/2017/Community/
VS_STRIP_COMN = $(subst \,/,$(dir $(patsubst %\,%,$(dir $(patsubst %\,%,$1)))))

# search cl.exe in the paths of VS*COMNTOOLS
# $1 - MSVC versions, e.g. 140,120,110,100,90,80
# result: C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/x86_arm/cl.exe
VS_COMN_FIND_CL_2005 = $(if $1,$(call VS_COMN_FIND_CL_20051,$1,C:/Program?Files/Microsoft?Visual?Studio?14.0/))

# $1 - MSVC versions, e.g. 140,120,110,100,90,80
# $2 - C:/Program?Files/Microsoft?Visual?Studio?14.0/
VS_COMN_FIND_CL_20051 = $(call VS_COMN_FIND_CL_20052,$1,$(call CONF_FIND_FILES_P,VCCL_2005_PATTERN_GEN_VS,$2,$(TOOLCHAIN_CPUS)))

# recursion
# $1 - MSVC versions, e.g. 140,120,110,100,90,80
# $2 - C:/Program?Files/Microsoft?Visual?Studio?14.0/VC/bin/x86_arm/cl.exe
VS_COMN_FIND_CL_20052 = $(if $2,$2,$(call VS_COMN_FIND_CL_2005,$(wordlist 2,999999,$1)))

# select appropriate compiler for the $(CPU), e.g.:
# C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/x86_arm/cl.exe
VCCL := $(call VS_COMN_FIND_CL_2005,140)

# get registry keys of Visual C++ installation paths for MS_REG_SEARCH
# $1 - Visual Studio version, e.g.: 7.0 7.1 8.0 9.0 10.0 11.0 12.0 14.0 15.0
# note: for Visual Studio 2005 and later - check VCExpress key
VCCL_REG_KEYS_VC = VisualStudio\$1\Setup\VC?ProductDir $(if $(call \
  is_less_float,$1,8.0),,VCExpress\$1\Setup\VC?ProductDir) VisualStudio\SxS\VC7?$1

# get registry keys of Visual Studio installation paths for MS_REG_SEARCH
VCCL_REG_KEYS_VS = VisualStudio\$1\Setup\VS?ProductDir $(if $(call \
  is_less_float,$1,8.0),,VCExpress\$1\Setup\VS?ProductDir) VisualStudio\SxS\VS7?$1

$(info -----1)

# look for C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x86/cl.exe
VCCL := $(call VS_2017_SELECT_LATEST_CL,cl.exe,$(call \
  MS_REG_SEARCH_W,$(VCCL_2017_PREFIXES:%=Tools/MSVC/*/bin/%cl.exe),$(call VCCL_REG_KEYS_VC,15.0)))

$(info -----2)

# e.g.: C:/Program?Files/ C:/Program?Files?(x86)/
PROGRAM_FILES_PLACES := C:/Program?Files/ C:/Program?Files?(x86)/

# versions of Visual C++ starting with Visual Studio 2005
VCCL_2005_VERSIONS := 14.0 12.0 11.0 10.0 9.0 8.0

# look in the paths found in registry
# $1 - 14.0 12.0 11.0 10.0 9.0 8.0
# result: C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/x86_arm/cl.exe
VS_SEARCH_2005 = $(if $1,$(call VS_SEARCH_20051,$1,$(call \
  MS_REG_SEARCH_P,VCCL_2005_PATTERN_GEN_VC,$(call VCCL_REG_KEYS_VC,$(firstword $1)),$(TOOLCHAIN_CPUS))))

# check VS registry keys (like VisualStudio\SxS\VS7)
VS_SEARCH_20051 = $(if $2,$2,$(call VS_SEARCH_20052,$1,$(call \
  MS_REG_SEARCH_P,VCCL_2005_PATTERN_GEN_VS,$(call VCCL_REG_KEYS_VS,$(firstword $1)),$(TOOLCHAIN_CPUS))))

# check standard places
# $1 - 14.0 12.0 11.0 10.0 9.0 8.0
# note: for Visual Studio 2005 registry key ends with 8.0, but directory in Program Files ends with just 8
VS_SEARCH_20052 = $(if $2,$2,$(call VS_SEARCH_20053,$1,$(call CONF_FIND_FILES_P,VCCL_2005_PATTERN_GEN_VS,$(addsuffix \
  Microsoft?Visual?Studio?$(subst 8.0,8,$(firstword $1))/,$(PROGRAM_FILES_PLACES)),$(TOOLCHAIN_CPUS))))

# recursion
VS_SEARCH_20053 = $(if $2,$2,$(call VS_SEARCH_2005,$(wordlist 2,999999,$1)))

# result: C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/x86_arm/cl.exe
VCCL := $(call VS_SEARCH_2005,$(VCCL_2005_VERSIONS))

$(info VCCL=$(VCCL))
