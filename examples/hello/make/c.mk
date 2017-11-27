# define rules for building C/C++ sources
include $(dir $(lastword $(MAKEFILE_LIST)))project.mk
include $(MTOP)/c.mk
