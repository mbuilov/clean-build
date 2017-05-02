# project setting file, included by $(MTOP)/defs.mk

SUPPORTED_OSES    := WINXX SOLARIS LINUX
SUPPORTED_CPUS    := x86 x86_64 sparc sparc64 armv5 mips24k ppc

DEFINCLUDE = $(TOP)/include

PREDEFINES = $(if $(DEBUG),_DEBUG) TARGET_$(TARGET:D=) \
             $(if $(filter sparc%,$(CPU))$(filter mips%,$(CPU))$(filter ppc%,$(CPU)),B_ENDIAN,L_ENDIAN) \
             $(if $(filter arm%,$(CPU))$(filter sparc%,$(CPU))$(filter mips%,$(CPU))$(filter ppc%,$(CPU)),ADDRESS_NEEDALIGN)

APPDEFS :=

# major.minor.patch
PRODUCT_VER := 1.0.0

# next variables are needed for generating resurce file under Windows
PRODUCT_NAMES_H  := product_names.h
VENDOR_NAME      := Michael M. Builov
PRODUCT_NAME     := Sample app
VENDOR_COPYRIGHT := Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
