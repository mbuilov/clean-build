# to build C/C++
include $(MTOP)/c.mk
# definitions for running built executable
include $(MTOP)/ctest.mk
# we will build S-variant of 'hello' executable - with statically linked C runtime
EXE := hello S
SRC := hello.c
# will run built executable
$(DO_TEST_EXE)
# define targets and rules how to build them
$(DEFINE_TARGETS)
