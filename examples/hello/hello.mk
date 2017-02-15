include $(MTOP)/c.mk
include $(MTOP)/ctest.mk
EXE := hello S
SRC := hello.c
$(DO_TEST_EXE)
$(DEFINE_TARGETS)
