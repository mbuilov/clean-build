# add support for processing sub-makefiles
include $(dir $(lastword $(MAKEFILE_LIST)))project.mk
include $(MTOP)/parallel.mk
