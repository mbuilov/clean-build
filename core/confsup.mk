#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# helper macro to remember autoconfigured variables in the generated configuration makefile
# $1 - names of the macros
# $2 - empty or 'export' keyword, if macros should be exported
cb_config_remember_vars:=

ifneq (,$(filter config,$(MAKECMDGOALS)))

ifeq (,$(CBLD_CONFIG))
$(error CBLD_CONFIG - path to generated configuration makefile - is not defined)
endif

# save $(CBLD_CONFIG) value to the target-specific variable cf
config: cf := $(abspath $(CBLD_CONFIG))

# config - is not a file, it's a goal
.PHONY: config

# list of exported variables defined in the $(CBLD_CONFIG) makefile
# if cb_config_exported_vars was not restored from the $(CBLD_CONFIG) makefile, define it here
ifneq (file,$(origin cb_config_exported_vars))
cb_config_exported_vars:=
endif

# temporary
cb_config_remember_vars = $(if $(findstring simple,$(flavor $v)),$= := $$(empty)$(subst \,$$(backslash),$(subst \
  $(comment),$$(comment),$(subst $(newline),$$(newline),$(subst $$,$$$$,$(value $=)))))$$(empty),define $=$(newline)$(subst \
  define,$$(keyword_define),$(subst endef,$$(keyword_endef),$(subst \,$$(backslash),$(value $=))))$(newline)endef)$(newline)

# save current configuration:
# 1) command-line variables (exported by default)
# 2) exported variable PATH
# 3) special variable SHELL
# 4) project-defined variables - those $(origin) is 'override' or the variable name is in $(cb_project_vars) list -
#  some of variables may be defined by the optional 'overrides' makefile (e.g. $(PROJ_OVERRIDES))
# note: once $(CBLD_CONFIG) makefile has been generated, variables defined in it may be altered only via command-line variables
# note: save current values of variables to the target-specific variable config_text - variables may be overridden later
# note: do not save auto-defined GNUMAKEFLAGS, clean_build_version, cb_dir, cb_build, CBLD_CONFIG and $(dump_max) variables
# note: filter-out %.^e - saved environment variables (see $(cb_dir)/stub/prepare.mk)
config config_text := define newline$(newline)$(newline)$(newline)endef$(newline)newline:= $$(newline)$(newline)comment:= \
  \$(comment)$(newline)empty:=$(newline)backslash:= \\$(comment)$(newline)keyword_define:= define$(newline)keyword_endef:= \
  endef$(newline)$(foreach =,$(filter-out GNUMAKEFLAGS clean_build_version cb_dir cb_build CBLD_CONFIG $(dump_max) \
  cb_config_exported_vars %.^e,$(.VARIABLES)),$(if $(or $(findstring command line,$(origin $=)),$(if $(findstring override,$(origin \
  $=)),$(filter $=,$(cb_config_exported_vars)))),ifneq (command line,$$(origin $=))$(newline)export override \
  $(cb_config_remember_vars)endif$(newline),$(if $(findstring override,$(origin $=)),override $(cb_config_remember_vars))))$(foreach \
  =,$(cb_config_exported_vars),$(if $(findstring file,$(origin $=)),export $(cb_config_remember_vars)))

# simulate environment variables: do not add the 'override' attribute to the exported 'file' variables
cb_project_vars := $(filter-out $(cb_config_exported_vars),$(cb_project_vars))

# add command-line variables to the list of exported variables
cb_config_exported_vars := $(sort $(cb_config_exported_vars) $(foreach =,$(filter-out GNUMAKEFLAGS %.^e,$(.VARIABLES)),$(if \
  $(findstring command line,$(origin $=))$=)))



# helper macro to remember autoconfigured variables in the generated configuration makefile
# $1 - names of the macros
# $2 - empty or 'export' keyword, if macros should be exported
$(eval cb_config_remember_vars = $$(eval config: config_text += $$$$(foreach =,$$(if $$2,$$(foreach =,$$1,$$(if $$(findstring \
  environment,$$(origin $$=)),$$=)),$$1),$$$$2 $(subst $$,$$$$,$(value cb_config_remember_vars)))))

# write by that number of lines at a time while generating configuration makefile
# note: with too many lines it is possible to exceed maximum command string length
CBLD_CONFIG_WRITE_BY_LINES ?= 10

# remember CBLD_CONFIG_WRITE_BY_LINES in generated configuration makefile
$(call cb_config_remember_vars,CBLD_CONFIG_WRITE_BY_LINES,export)

# generate configuration makefile
# note: suppress - defined in $(cb_dir)/core/_defs.mk
# note: write_text - defined in $(cb_dir)/utils/$(CBLD_UTILS).mk
# note: pass 1 as 4-th argument of 'suppress' function to not update percents of executed target makefiles
# note: 'config_text' was defined above as target-specific variable
conf: F.^ := $(abspath $(firstword $(MAKEFILE_LIST)))
conf: C.^ :=
conf:| $(abspath $(dir $(CBLD_CONFIG)))
	$(call suppress,GEN,$(cf),,1)$(call write_text,$(config_text),$(cf),$(CBLD_CONFIG_WRITE_BY_LINES))

# if $(CBLD_CONFIG) makefile is generated under the $(CBLD_BUILD), create that directory automatically
# else - $(CBLD_CONFIG) makefile is outside of $(CBLD_BUILD), configuration makefile directory must be created manually
ifneq (,$(filter $(abspath $(CBLD_BUILD))/%,$(CONFIG)))
CB_NEEDED_DIRS += $(patsubst %/,%,$(dir $(CONFIG)))
else
$(patsubst %/,%,$(dir $(CONFIG))):
	$(error config file directory '$@' does not exist, it is not under '$(BUILD)', so should be created manually)
endif

endif # conf
endif # CONFIG




define cb_config_override_var_template

ifneq (command line,$$(origin $v))
$(keyword_define) $v
$(value $v)
$(keyword_endef)$(if $(findstring simple,$(flavor $v)),$(newline)$v:=$$(value $v))
endif
endef


# generate text of $(cb_config) file so that by including it:
# 1) define and export old environment variables
# 2) undefine/unexport new environment variables
# 3) restore old command-line variables that do not conflict with a new ones
# $v - variable name

cb_env_vars:= aa bb cc

define aaa
c:$(backslash)
endef
aaa:=$(value aaa)

define eee
c:$(backslash)
endef
export eee






# protect variables from modification in target makefiles
# note: TARGET_MAKEFILE variable is used here temporary and will be redefined later
TARGET_MAKEFILE += $(call SET_GLOBAL,CONFIG config_remember_vars config_override_var_template CONFSUP_WRITE_BY_LINES)
