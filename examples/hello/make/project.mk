# project setting file, included by $(MTOP)/defs.mk

SUPPORTED_OSES    := WINXX SOLARIS LINUX
SUPPORTED_CPUS    := x86 x86_64 sparc sparc64 armv5 mips24k ppc
SUPPORTED_TARGETS := PROJECT PROJECTD

DEFINCLUDE = $(TOP)/include

PREDEFINES = $(if $(DEBUG),_DEBUG) TARGET_$(TARGET:D=) \
             $(if $(filter sparc%,$(CPU))$(filter mips%,$(CPU))$(filter ppc%,$(CPU)),B_ENDIAN,L_ENDIAN) \
             $(if $(filter arm%,$(CPU))$(filter sparc%,$(CPU))$(filter mips%,$(CPU))$(filter ppc%,$(CPU)),ADDRESS_NEEDALIGN)

APPDEFS :=

ifeq ($(OS),WINXX)
SUPPRESS_RC_LOGO := /nologo
endif
