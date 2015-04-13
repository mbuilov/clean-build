PAM_PATH    ?= /usr
PAM_INCLUDE ?= $(PAM_PATH)/include
PAM_LIB     ?= $(PAM_PATH)/lib
SYSINCLUDE  += $(PAM_INCLUDE)
SYSLIBPATH  += $(PAM_LIB)
SYSLIBS     += pam
RPATH       += $(PAM_RPATH)
