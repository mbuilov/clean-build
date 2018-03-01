$(info ================ touch_files ==============)

# the first goal will be the default
all:

# define target-specific variable 'c_dir' - path to the directory of this makefile
all clean distclean: c_dir := $(dir $(lastword $(MAKEFILE_LIST)))

# test 'touch_files' macro
all clean distclean:
	$(MAKE) -f $(c_dir)touch.mk $@
	$(if $(filter all,$@),$(MAKE) -f $(c_dir)check.mk)
	$(MAKE) -f $(c_dir)touch2.mk $@
	$(MAKE) -f $(c_dir)check2.mk $@

.PHONY: all clean distclean
