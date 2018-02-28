# the first goal will be the default
all:

# define target-specific variable 'c_dir' - path to the directory of this makefile
all clean distclean: c_dir := $(dir $(lastword $(MAKEFILE_LIST)))

trace_tests:
	$(MAKE) -f $(c_dir)trace_tests.mk

# define environment variable 'MAKE_TRACE_IN_COLOR' for the rules of 'trace_tests_no_color' goal
trace_tests_no_color: export MAKE_TRACE_IN_COLOR:=0
trace_tests_no_color:
	$(MAKE) -f $(c_dir)trace_tests.mk

function_tests:
	$(MAKE) -f $(c_dir)function_tests.mk

all: trace_tests trace_tests_no_color function_tests

# test shell utilities
all clean distclean:
	$(MAKE) -f $(c_dir)utils/Makefile $@

.PHONY: all clean distclean traces_test trace_tests_no_color function_tests
