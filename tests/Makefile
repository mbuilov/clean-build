c_dir := $(dir $(lastword $(MAKEFILE_LIST)))

all:

trace_tests:
	$(MAKE) -f $(c_dir)trace_tests.mk

trace_tests_no_color: export MAKE_TRACE_IN_COLOR:=0
trace_tests_no_color:
	$(MAKE) -f $(c_dir)trace_tests.mk

function_tests:
	$(MAKE) -f $(c_dir)function_tests.mk

all: \
  trace_tests \
  trace_tests_no_color \
  function_tests
	@echo all tests passed

.PHONY: all \
  traces_test \
  trace_tests_no_color \
  function_tests
