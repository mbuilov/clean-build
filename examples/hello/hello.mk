# include templates for building C/C++ sources
include $(MTOP)/c.mk

# add definitions for running built executable
include $(MTOP)/exts/ctest.mk

# we will build S-variant of 'hello' executable - with statically linked C runtime
EXE := hello S
SRC := hello.c

# will run built executable
$(DO_TEST_EXE)

# define targets and rules how to build them
$(DEFINE_TARGETS)
