#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# included by $(CLEAN_BUILD_DIR)/compilers/msvc_conf.mk

# if $(TMD)VCLIBPATH or $(TMD)VCINCLUDE are not defined in project configuration makefile or in command line,
#  define VCLIBPATH_AUTO and VCINCLUDE_AUTO values from path to cl.exe

# note: TMD must be defined, either as empty or as T, $(TMD)VCCL must also be defined

ifneq (,$(filter undefined environment,$(origin $(TMD)VCLIBPATH) $(origin $(TMD)VCINCLUDE)))

  # paths to cl.exe:
  #  C:\Program Files\Microsoft Visual Studio                                                  VC98\Bin\cl.exe
  #  C:\Program Files\Microsoft Visual Studio .NET 2003                                        Vc7\bin\cl.exe
  #  C:\Program Files\Microsoft Visual C++ Toolkit 2003                                        bin\cl.exe
  #  C:\Program Files\Microsoft Platform SDK for Windows Server 2003 R2                        Bin\win64\cl.exe
  #  C:\Program Files\Microsoft Platform SDK for Windows Server 2003 R2                        Bin\win64\x86\AMD64\cl.exe
  #  C:\Program Files\Microsoft Visual Studio 8                                                VC\bin\cl.exe
  #  C:\Program Files\Microsoft Visual Studio 8                                                VC\bin\x86_amd64\cl.exe
  #  C:\Program Files\Microsoft Visual Studio 8                                                VC\bin\x86_ia64\cl.exe
  #  C:\Program Files\Microsoft Visual Studio 8                                                VC\bin\amd64\cl.exe
  #  C:\Program Files\Microsoft Visual Studio 8                                                VC\bin\ia64\cl.exe
  #  C:\Program Files\Microsoft SDKs\Windows                                                   v6.0\VC\Bin\cl.exe
  #  C:\Program Files\Microsoft SDKs\Windows                                                   v6.0\VC\Bin\x64\cl.exe
  #  C:\WINDDK\3790.1830                                                                       bin\x86\cl.exe
  #  C:\WINDDK\3790.1830                                                                       bin\ia64\cl.exe
  #  C:\WINDDK\3790.1830                                                                       bin\win64\x86\cl.exe
  #  C:\WINDDK\3790.1830                                                                       bin\win64\x86\amd64\cl.exe
  #  C:\WinDDK\6001.18002                                                                      bin\x86\x86\cl.exe
  #  C:\WinDDK\6001.18002                                                                      bin\x86\amd64\cl.exe
  #  C:\WinDDK\6001.18002                                                                      bin\x86\ia64\cl.exe
  #  C:\WinDDK\6001.18002                                                                      bin\ia64\ia64\cl.exe
  #  C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503   bin\HostX86\x86\cl.exe
  #  C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503   bin\HostX86\x64\cl.exe
  #  C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503   bin\HostX86\arm\cl.exe
  #  C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503   bin\HostX64\x64\cl.exe
  #  C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503   bin\HostX64\x86\cl.exe
  #  C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503   bin\HostX64\arm\cl.exe

  # VCCL="C:\Program Files\Microsoft Visual Studio\VC98\Bin\cl.exe"
  VCCL_PARENT1 := $(patsubst %/,%,$(dir $(subst \,/,$(patsubst "%",%,$(subst $(space),?,$($(TMD)VCCL))))))
  VCCL_PARENT2 := $(patsubst %/,%,$(dir $(VCCL_PARENT1)))
  VCCL_PARENT3 := $(patsubst %/,%,$(dir $(VCCL_PARENT2)))
  VCCL_PARENT4 := $(patsubst %/,%,$(dir $(VCCL_PARENT3)))
  VCCL_ENTRY1l := $(call tolower,$(notdir $(VCCL_PARENT1)))
  VCCL_ENTRY2l := $(call tolower,$(notdir $(VCCL_PARENT2)))
  VCCL_ENTRY3l := $(call tolower,$(notdir $(VCCL_PARENT3)))

  ifeq (bin,$(VCCL_ENTRY3l))
    ifneq (,$(filter host%,$(VCCL_ENTRY2l)))
      # VCCL="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX86\x86\cl.exe"
      # VCCL="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX86\x64\cl.exe"
      # VCCL="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX86\arm\cl.exe"
      # VCCL="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x64\cl.exe"
      # VCCL="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe"
      # VCCL="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\arm\cl.exe"

      ifneq (,$(filter undefined environment,$(origin $(TMD)VCLIBPATH)))
        # C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\x64\msvcrt.lib
        # C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\x64\store\msvcrt.lib
        # C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\onecore\x64\msvcrt.lib
        MSVCRTLIB_PATH := $(VCCL_PARENT4)/lib$($(TMD)VC_LIB_TYPE_ONECORE:%=/%)/$(VCCL_ENTRY1l)$($(TMD)VC_LIB_TYPE_STORE:%=/%)/msvcrt.lib
        VCLIBPATH_AUTO := $(call CHECK_FILE_PATH,$(MSVCRTLIB_PATH))

        ifndef VCLIBPATH_AUTO
          $(error unable to autoconfigure $(TMD)VCLIBPATH for $(TMD)VCCL=$($(TMD)VCCL): file does not exist:$(if \
            ,)$(newline)$(call PATH_PRINTABLE,$(MSVCRTLIB_PATH))$(if \
            ,)$(newline)please specify $(TMD)VCLIBPATH explicitly, e.g.:$(if \
            ,)$(newline)$(TMD)VCLIBPATH=$(subst /,\,$(VCCL_PARENT4))\lib\$(CPU:x86_64=x64))
        endif
      endif

      ifneq (,$(filter undefined environment,$(origin $(TMD)VCINCLUDE)))
        # C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\include\varargs.h
        VARARGS_H_PATH := $(VCCL_PARENT4)/include/varargs.h
        VCINCLUDE_AUTO := $(call CHECK_FILE_PATH,$(VARARGS_H_PATH))

        ifndef VCINCLUDE_AUTO
          $(error unable to autoconfigure $(TMD)VCINCLUDE for $(TMD)VCCL=$($(TMD)VCCL): file does not exist:$(if \
            ,)$(newline)$(call PATH_PRINTABLE,$(VARARGS_H_PATH))$(if \
            ,)$(newline)please specify $(TMD)VCINCLUDE explicitly, e.g.:$(if \
            ,)$(newline)$(TMD)VCINCLUDE=$(subst /,\,$(VCCL_PARENT4))\include)
        endif
      endif

    endif
  endif

  ifeq (bin,$(VCCL_ENTRY1l))
    # VCCL="C:\Program Files\Microsoft Visual Studio\VC98\Bin\cl.exe"
    # VCCL="C:\Program Files\Microsoft Visual Studio .NET\Vc7\bin\cl.exe"
    # VCCL="C:\Program Files\Microsoft Visual Studio .NET 2003\Vc7\bin\cl.exe"
    # VCCL="C:\Program Files\Microsoft Visual C++ Toolkit 2003\bin\cl.exe"
    # VCCL="C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\cl.exe"
    # VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\cl.exe"

    ifneq (,$(filter undefined environment,$(origin $(TMD)VCLIBPATH)))
      MSVCRTLIB_PATH := $(VCCL_PARENT2)/lib/msvcrt.lib
      VCLIBPATH_AUTO := $(call CHECK_FILE_PATH,$(MSVCRTLIB_PATH))

      ifndef VCLIBPATH_AUTO
        $(error unable to autoconfigure $(TMD)VCLIBPATH for $(TMD)VCCL=$($(TMD)VCCL): file does not exist:$(if \
          ,)$(newline)$(call PATH_PRINTABLE,$(MSVCRTLIB_PATH))$(if \
          ,)$(newline)please specify $(TMD)VCLIBPATH explicitly, e.g.:$(if \
          ,)$(newline)$(TMD)VCLIBPATH=$(subst /,\,$(VCCL_PARENT2))\lib)
      endif
    endif

    ifneq (,$(filter undefined environment,$(origin $(TMD)VCINCLUDE)))
      VARARGS_H_PATH := $(VCCL_PARENT2)/include/varargs.h
      VCINCLUDE_AUTO := $(call CHECK_FILE_PATH,$(VARARGS_H_PATH))

      ifndef VCINCLUDE_AUTO
        $(error unable to autoconfigure $(TMD)VCINCLUDE for $(TMD)VCCL=$($(TMD)VCCL): file does not exist:$(if \
          ,)$(newline)$(call PATH_PRINTABLE,$(VARARGS_H_PATH))$(if \
          ,)$(newline)please specify $(TMD)VCINCLUDE explicitly, e.g.:$(if \
          ,)$(newline)$(TMD)VCINCLUDE=$(subst /,\,$(VCCL_PARENT2))\include)
      endif
    endif

  endif

  ifeq (vc bin,$(VCCL_ENTRY3l) $(VCCL_ENTRY2l))
    # VCCL="C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\x64\cl.exe"
    # VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe"

    ifneq (,$(filter undefined environment,$(origin $(TMD)VCLIBPATH)))
      # C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\LIB\x64\msvcrt.lib
      # C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\onecore\arm\msvcrt.lib
      # C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\onecore\msvcrt.lib
      # C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\store\amd64\msvcrt.lib
      MSVCRTLIB_PATH := $(VCCL_PARENT3)/lib$($(TMD)VC_LIB_TYPE_ONECORE:%=/%)$($(TMD)VC_LIB_TYPE_STORE:%=/%)$(call \
        VCCL_GET_LIBS_2005,$(VCCL_ENTRY1l),$(call VS_SELECT_CPU,$(VCCL_PARENT3)))/msvcrt.lib
      VCLIBPATH_AUTO := $(call CHECK_FILE_PATH,$(MSVCRTLIB_PATH))

      ifndef VCLIBPATH_AUTO
        $(error unable to autoconfigure $(TMD)VCLIBPATH for $(TMD)VCCL=$($(TMD)VCCL): file does not exist:$(if \
          ,)$(newline)$(call PATH_PRINTABLE,$(MSVCRTLIB_PATH))$(if \
          ,)$(newline)please specify $(TMD)VCLIBPATH explicitly, e.g.:$(if \
          ,)$(newline)$(TMD)VCLIBPATH=$(subst /,\,$(VCCL_PARENT3))\lib\$($(TMD)CPU:x86_64=amd64))
      endif
    endif

    ifneq (,$(filter undefined environment,$(origin $(TMD)VCINCLUDE)))
      # C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\INCLUDE\varargs.h
      # C:\Program Files\Microsoft Visual Studio 14.0\VC\include\varargs.h
      VARARGS_H_PATH := $(VCCL_PARENT3)/include/varargs.h
      VCINCLUDE_AUTO := $(call CHECK_FILE_PATH,$(VARARGS_H_PATH))

      ifndef VCINCLUDE_AUTO
        $(error unable to autoconfigure $(TMD)VCINCLUDE for $(TMD)VCCL=$($(TMD)VCCL): file does not exist:$(if \
          ,)$(newline)$(call PATH_PRINTABLE,$(VARARGS_H_PATH))$(if \
          ,)$(newline)please specify $(TMD)VCINCLUDE explicitly, e.g.:$(if \
          ,)$(newline)$(TMD)VCINCLUDE=$(subst /,\,$(VCCL_PARENT3))\include)
      endif
    endif

  endif

  ifeq (bin,$(VCCL_ENTRY3l)
    ifeq (,$(filter win64 host%,$(VCCL_ENTRY2l)))
      # VCCL="C:\WinDDK\6001.18002\bin\x86\x86\cl.exe"
      # VCCL="C:\WinDDK\6001.18002\bin\x86\amd64\cl.exe"
      # VCCL="C:\WinDDK\6001.18002\bin\x86\ia64\cl.exe"
      # VCCL="C:\WinDDK\6001.18002\bin\ia64\ia64\cl.exe"

      ifneq (,$(filter undefined environment,$(origin $(TMD)VCLIBPATH)))
        # C:\WinDDK\6001.18001\lib\crt\{i386,amd64,ia64}\msvcrt.lib
        MSVCRTLIB_PATH := $(VCCL_PARENT4)/lib/crt/$(patsubst x86,i386,$($(TMD)CPU:x86_64=amd64))/msvcrt.lib
        VCLIBPATH_AUTO := $(call CHECK_FILE_PATH,$(MSVCRTLIB_PATH))

        ifndef VCLIBPATH_AUTO
          $(error unable to autoconfigure $(TMD)VCLIBPATH for $(TMD)VCCL=$(VCCL): file does not exist:$(if \
            ,)$(newline)$(call PATH_PRINTABLE,$(MSVCRTLIB_PATH))$(if \
            ,)$(newline)please specify $(TMD)VCLIBPATH explicitly, e.g.:$(if \
            ,)$(newline)$(TMD)VCLIBPATH=$(subst /,\,$(VCCL_PARENT4))\lib\crt\$(patsubst x86,i386,$($(TMD)CPU:x86_64=amd64)))
        endif
      endif

    ifneq (,$(filter undefined environment,$(origin $(TMD)VCINCLUDE)))
      # C:\WinDDK\6001.18001\inc\crt\varargs.h
      VARARGS_H_PATH := $(VCCL_PARENT4)/inc/crt/varargs.h
      VCINCLUDE_AUTO := $(call CHECK_FILE_PATH,$(VARARGS_H_PATH))

      ifndef VCINCLUDE_AUTO
        $(error unable to autoconfigure $(TMD)VCINCLUDE for $(TMD)VCCL=$(VCCL): file does not exist:$(if \
          ,)$(newline)$(call PATH_PRINTABLE,$(VARARGS_H_PATH))$(if \
          ,)$(newline)please specify $(TMD)VCINCLUDE explicitly, e.g.:$(if \
          ,)$(newline)$(TMD)VCINCLUDE=$(subst /,\,$(VCCL_PARENT4))\inc\crt)
      endif
    endif

  endif

  ifndef VCLIBPATH_AUTO
  ifndef VCINCLUDE_AUTO
    # VCCL="C:\WINDDK\3790.1830\bin\x86\cl.exe"
    # VCCL="C:\WINDDK\3790.1830\bin\ia64\cl.exe"
    # VCCL="C:\WINDDK\3790.1830\bin\win64\x86\cl.exe"
    # VCCL="C:\Program Files\Microsoft Platform SDK for Windows Server 2003 R2\Bin\win64\x86\AMD64\cl.exe"
    # VCCL="C:\WINDDK\3790.1830\bin\win64\x86\amd64\cl.exe"

    ifeq (bin,$(VCCL_ENTRY2l))
      VCCL_PARENTx := $(VCCL_PARENT3)
    else ifeq (bin,$(VCCL_ENTRY3l))
      VCCL_PARENTx := $(VCCL_PARENT4)
    else
      VCCL_PARENTx := $(patsubst %/,%,$(dir $(VCCL_PARENT4)))
    endif

    ifneq (,$(filter undefined environment,$(origin $(TMD)VCLIBPATH)))
      # C:\WINDDK\3790.1830\lib\crt\{i386,amd64,ia64}\msvcrt.lib
      MSVCRTLIB_PATH1 := $(VCCL_PARENTx)/lib/crt/$(patsubst x86,i386,$($(TMD)CPU:x86_64=amd64))/msvcrt.lib
      VCLIBPATH_AUTO := $(call CHECK_FILE_PATH,$(MSVCRTLIB_PATH1))

      ifndef VCLIBPATH_AUTO
        # C:\WINDDK\2600\lib\wxp\{i386,ia64}\msvcrt.lib
        # C:\WINDDK\2600.1106\lib\wxp\{i386,ia64}\msvcrt.lib
        # C:\WINDDK\3790\lib\wxp\{i386,ia64}\msvcrt.lib
        # C:\WINDDK\3790\lib\wnet\{i386,amd64,ia64}\msvcrt.lib

        ifndef TMD
          VCCL_WIN_NAME := $(call WIN_NAME_FROM_WINVARIANT,$(WINVARIANT))
        else
          $(TMD)VCCL_WIN_NAME := wxp
        endif

        MSVCRTLIB_PATH2 := $(VCCL_PARENTx)/lib/$($(TMD)VCCL_WIN_NAME)/$(patsubst x86,i386,$($(TMD)CPU:x86_64=amd64))/msvcrt.lib
        VCLIBPATH_AUTO := $(call CHECK_FILE_PATH,$(MSVCRTLIB_PATH2))

        ifndef VCLIBPATH_AUTO
          # C:\Program Files\Microsoft Platform SDK for Windows Server 2003 R2\Lib\{AMD64,IA64}\msvcrt.Lib
          MSVCRTLIB_PATH3 := $(VCCL_PARENTx)/lib/$($(TMD)CPU:x86_64=amd64)/msvcrt.lib
          VCLIBPATH_AUTO := $(call CHECK_FILE_PATH,$(MSVCRTLIB_PATH3))

          ifndef VCLIBPATH_AUTO
            $(error unable to autoconfigure $(TMD)VCLIBPATH for $(TMD)VCCL=$($(TMD)VCCL): files do not exist:$(if \
              ,)$(newline)$(call PATH_PRINTABLE,$(MSVCRTLIB_PATH1))$(if \
              ,)$(newline)$(call PATH_PRINTABLE,$(MSVCRTLIB_PATH2))$(if \
              ,)$(newline)$(call PATH_PRINTABLE,$(MSVCRTLIB_PATH3))$(if \
              ,)$(newline)please specify $(TMD)VCLIBPATH explicitly, e.g.:$(if \
              ,)$(newline)$(TMD)VCLIBPATH=$(subst /,\,$(VCCL_PARENTx))\lib\crt\$(patsubst x86,i386,$($(TMD)CPU:x86_64=amd64)))
          endif
        endif
      endif
    endif

    ifneq (,$(filter undefined environment,$(origin $(TMD)VCINCLUDE)))
      # C:\WINDDK\3790.1830\inc\crt\varargs.h
      VARARGS_H_PATH1 := $(VCCL_PARENTx)/inc/crt/varargs.h
      VCINCLUDE_AUTO := $(call CHECK_FILE_PATH,$(VARARGS_H_PATH1))

      ifndef VCINCLUDE_AUTO
        # C:\Program Files\Microsoft Platform SDK for Windows Server 2003 R2\Include\crt\varargs.h
        VARARGS_H_PATH2 := $(VCCL_PARENTx)/Include/crt/varargs.h
        VCINCLUDE_AUTO := $(call CHECK_FILE_PATH,$(VARARGS_H_PATH2))

        ifndef VCINCLUDE_AUTO
          $(error unable to autoconfigure $(TMD)VCINCLUDE for $(TMD)VCCL=$($(TMD)VCCL): files do not exist:$(if \
            ,)$(newline)$(call PATH_PRINTABLE,$(VARARGS_H_PATH1))$(if \
            ,)$(newline)$(call PATH_PRINTABLE,$(VARARGS_H_PATH2))$(if \
            ,)$(newline)please specify $(TMD)VCINCLUDE explicitly, e.g.:$(if \
            ,)$(newline)$(TMD)VCINCLUDE=$(subst /,\,$(VCCL_PARENTx))\inc\crt)
        endif
      endif
    endif

  endif # !VCINCLUDE_AUTO
  endif # !VCLIBPATH_AUTO

endif
