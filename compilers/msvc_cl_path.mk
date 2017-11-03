#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# included by $(CLEAN_BUILD_DIR)/compilers/msvc_conf.mk

# adjust PATH environment variable so cl.exe may find needed dlls

# note: TMD must be defined, either as empty or as T, $(TMD)VCCL must also be defined

# by default, allow adjusting environment variable PATH
$(TMD)VCCL_DO_NOT_ADJUST_PATH:=

ifndef $(TMD)CL_DO_NOT_ADJUST_PATH

  # remember if environment variable PATH was changed
  $(TMD)VCCL_PATH_APPEND:=

  # compilers that need additional paths:
  #  C:\Program Files\Microsoft Visual Studio                                                  VC98\Bin\cl.exe
  #  C:\Program Files\Microsoft Visual Studio .NET 2003                                        Vc7\bin\cl.exe
  #  C:\Program Files\Microsoft Visual Studio 8                                                VC\bin\cl.exe
  #  C:\Program Files\Microsoft Visual Studio 8                                                VC\bin\x86_amd64\cl.exe
  #  C:\Program Files\Microsoft Visual Studio 8                                                VC\bin\x86_ia64\cl.exe
  #  C:\Program Files\Microsoft Visual Studio 8                                                VC\bin\amd64\cl.exe
  #  C:\Program Files\Microsoft Visual Studio 8                                                VC\bin\ia64\cl.exe
  #  C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503   bin\HostX86\x86\cl.exe
  #  C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503   bin\HostX86\x64\cl.exe
  #  C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503   bin\HostX86\arm\cl.exe
  #  C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503   bin\HostX64\x64\cl.exe
  #  C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503   bin\HostX64\x86\cl.exe
  #  C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503   bin\HostX64\arm\cl.exe

  # adjust environment variable PATH so cl.exe, lib.exe and link.exe will find their dlls
  VCCL_PARENT1 := $(patsubst %\,%,$(dir $(patsubst "%",%,$(subst $(space),?,$($(TMD)VCCL)))))
  VCCL_PARENT2 := $(patsubst %\,%,$(dir $(VCCL_PARENT1)))
  VCCL_PARENT3 := $(patsubst %\,%,$(dir $(VCCL_PARENT2)))
  VCCL_ENTRY1l := $(call tolower,$(notdir $(VCCL_PARENT1)))
  VCCL_ENTRY2l := $(call tolower,$(notdir $(VCCL_PARENT2)))
  VCCL_ENTRY3l := $(call tolower,$(notdir $(VCCL_PARENT3)))

  ifneq (,$(filter host%,$(VCCL_ENTRY2l)))
    # Visual Studio 2017 or later:
    #  VCCL="C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe"

    VCCL_HOST := $(patsubst host%,%,$(VCCL_ENTRY2l))

    # if cross-compiling, add path to host dlls
    ifneq ($(VCCL_HOST),$(VCCL_ENTRY1l))
      $(TMD)VCCL_PATH_APPEND := $(VCCL_PARENT2)\$(VCCL_HOST)
    endif

  else ifeq (vc bin,$(VCCL_ENTRY2l) $(VCCL_ENTRY1l))
    # Visual Studio 2005-2015:
    #  VCCL="C:\Program Files\Microsoft Visual Studio 8\VC\bin\cl.exe"
    #  VCCL="C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\cl.exe"

    #  add path to $(VS)\Common7\IDE if compiling on x86 host
    COMMON7_IDE_PATH := $(VCCL_PARENT3)\Common7\IDE

    # note: Visual Studio 2013 does not contain mspdb120.dll in $(VS)\Common7\IDE directory
    ifneq (,$(wildcard $(subst ?,\ ,$(subst \,/,$(COMMON7_IDE_PATH)))/mspdb*0.dll))
      $(TMD)VCCL_PATH_APPEND := $(COMMON7_IDE_PATH)
    endif

  else ifeq (vc7 bin,$(VCCL_ENTRY2l) $(VCCL_ENTRY1l))
    # for Visual Studio 2002-2003
    $(TMD)VCCL_PATH_APPEND := $(VCCL_PARENT3)\Common7\IDE

  else ifeq (vc98 bin,$(VCCL_ENTRY2l) $(VCCL_ENTRY1l))
    # for Visual Studio 6.0
    $(TMD)VCCL_PATH_APPEND := $(VCCL_PARENT3)\Common\MSDev98\Bin

  else ifeq (vc bin,$(VCCL_ENTRY3l) $(VCCL_ENTRY2l))
    # Visual Studio 2005-2015:
    #  VCCL="C:\Program Files\Microsoft Visual Studio 8\VC\bin\x86_amd64\cl.exe"
    #  VCCL="C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\x64\cl.exe"

    # x64       -> VCCL_HOST_PREF=\x64   VC_LIBS_PREF=\x64
    # amd64     -> VCCL_HOST_PREF=\amd64 VC_LIBS_PREF=\amd64
    # amd64_x86 -> VCCL_HOST_PREF=\amd64 VC_LIBS_PREF=
    # x86_amd64 -> VCCL_HOST_PREF=       VC_LIBS_PREF=\amd64
    VCCL_CPU       := $(call VS_SELECT_CPU,$(subst \,/,$(VCCL_PARENT1)))
    VCCL_HOST_PREF := $(addprefix \,$(call VCCL_GET_HOST_2005,$(VCCL_ENTRY1l),$(VCCL_CPU)))
    VC_LIBS_PREF   := $(call VCCL_GET_LIBS_2005,$(VCCL_ENTRY1l),$(VCCL_CPU))

    # if cross-compiling, add path to host dlls
    # note: some dlls are may be in $(VS)\Common7\IDE
    ifneq ($(VCCL_HOST_PREF),$(VC_LIBS_PREF))
      $(TMD)VCCL_PATH_APPEND := $(VCCL_PARENT2)$(VCCL_HOST_PREF)
    endif

    ifndef VCCL_HOST_PREF
      # add path to $(VS)\Common7\IDE if compiling on $(VS_CPU) host
      # note: needed only for Visual Studio 2012 and before

      # VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe"
      COMMON7_IDE_PATH := $(dir $(VCCL_PARENT3))Common7\IDE

      ifneq (,$(wildcard $(subst ?,\ ,$(subst \,/,$(COMMON7_IDE_PATH)))/mspdb*0.dll))
        $(TMD)VCCL_PATH_APPEND := $(addsuffix ;,$($(TMD)VCCL_PATH_APPEND))$(COMMON7_IDE_PATH)
      endif
    endif

  endif

  ifdef $(TMD)VCCL_PATH_APPEND
    override PATH := $(PATH);$(subst ?, ,$($(TMD)VCCL_PATH_APPEND))
  endif

  # PATH was adjusted, do not adjust it if read PATH variable from generated project configuration makefile
  $(TMD)VCCL_DO_NOT_ADJUST_PATH := 1

endif
