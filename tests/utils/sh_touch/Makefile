$(info ================ sh_touch =================)

# the first goal will be the default
all:

# define target-specific variable 'c_dir' - path to the directory of this makefile
all clean distclean: c_dir := $(dir $(lastword $(MAKEFILE_LIST)))

# test 'sh_touch' macro
all clean distclean:
	$(MAKE) -f $(c_dir)touch.mk $@
	$(if $(filter all,$@),$(MAKE) -f $(c_dir)check.mk)
	$(if $(filter all,$@),$(MAKE) -f $(c_dir)touch.mk test_phase:=2)
	$(if $(filter all,$@),$(MAKE) -f $(c_dir)check.mk test_phase:=2)

.PHONY: all clean distclean
