# this file is included by $(MTOP)/make_defs.mk

SUPPORTED_OSES    := WINXX SOLARIS LINUX
SUPPORTED_CPUS    := x86 x86_64 sparc sparc64 armv5 mips24k ppc
SUPPORTED_TARGETS := PROJECT PROJECTD

DEFINCLUDE = $(TOP)/include $(BLDINC_DIR)

PREDEFINES = $(if $(DEBUG),_DEBUG) TARGET_$(patsubst %D,%,$(TARGET)) \
             $(if $(filter sparc%,$(CPU))$(filter mips%,$(CPU))$(filter ppc%,$(CPU)),B_ENDIAN,L_ENDIAN) \
             $(if $(filter arm%,$(CPU))$(filter sparc%,$(CPU))$(filter mips%,$(CPU))$(filter ppc%,$(CPU)),ADDRESS_NEEDALIGN)

ifeq ($(OS),LINUX)

APPDEFS :=
KRNDEFS =

else ifeq ($(OS),WINXX)

APPDEFS :=
KRNDEFS :=
SUPPRESS_RC_LOGO := /nologo

else ifeq ($(OS),SOLARIS)

APPDEFS :=
KRNDEFS =

endif
