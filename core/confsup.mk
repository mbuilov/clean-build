#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# helper macro used to remember autoconfigured variables in the generated configuration makefile
# $1 - names of the macros
# $2 - 'export' if macros should be forcibly exported, empty - otherwise
cb_config_remember_vars:=

# list of exported variables defined in the $(CBLD_CONFIG) makefile
# if cb_config_exported_vars was not restored from the $(CBLD_CONFIG) makefile, define it here
ifneq (file,$(origin cb_config_exported_vars))
cb_config_exported_vars:=
else
# simulate environment variables: do not add the 'override' attribute to the exported 'file' variables
cb_project_vars := $(filter-out cb_config_exported_vars $(cb_config_exported_vars),$(cb_project_vars))
endif

ifneq (,$(filter config,$(MAKECMDGOALS)))

# note: override the value, if it was accidentally set in the project configuration makefile
override cb_config := $(abspath $(CBLD_CONFIG))

ifndef cb_config
$(error CBLD_CONFIG - path to generated configuration makefile - is not defined)
endif

# config - is not a file, it's a goal
.PHONY: config

# encode a value of the variable $=
cb_config_remember_var = $(if $(findstring simple,$(flavor $v)),$= := $$(empty)$(subst \,$$(backslash),$(subst \
  $(comment),$$(comment),$(subst $(newline),$$(newline),$(subst $$,$$$$,$(value $=)))))$$(empty),define $=$(newline)$(subst \
  define,$$(keyword_define),$(subst endef,$$(keyword_endef),$(subst \,$$(backslash),$(value $=))))$(newline)endef)$(newline)

# Note:
#  environment v=E  +  command line v=C  +  file     v=F  ->  command line exported v=C
#  environment v=E  +  command line v=C  +  override v=O  ->  override     exported v=O
#  environment v=E  +                       file     v=F  ->  file         exported v=F
#  environment v=E  +                       override v=O  ->  override     exported v=O
#                      command line v=C  +  file     v=F  ->  command line exported v=C
#                      command line v=C  +  override v=O  ->  override              v=O

# save current configuration:
# 1) command-line variables (exported by default)
# 2) variable PATH, likely exported - if it's origin is 'environment' or the PATH is in $(cb_config_exported_vars) list
# 3) project-defined variables - those $(origin) is 'override' or the variable name is in $(cb_project_vars) list -
#  some of variables may be defined by the one-time included 'overrides' makefile (e.g. $(PROJ_OVERRIDES))
# note: once $(CBLD_CONFIG) makefile has been generated, variables defined in it may be altered only via command-line variables
# note: save current values of variables to the target-specific variable config_text - variables may be overridden later
# note: PATH will be saved later
# note: ignore auto-defined variables: SHELL, GNUMAKEFLAGS, clean_build_version, cb_dir, cb_build, CBLD_CONFIG, cb_config, $(dump_max)
# note: filter-out %.^e - saved environment variables (see $(cb_dir)/stub/prepare.mk)
# note: cb_config_exported_vars - will be saved at end of generated $(CBLD_CONFIG) makefile
config: config_text := define newline$(newline)$(newline)$(newline)endef$(newline)newline:= $$(newline)$(newline)comment:= \
  \$(comment)$(newline)empty:=$(newline)backslash:= \\$(comment)$(newline)keyword_define:= define$(newline)keyword_endef:= \
  endef$(newline)$(foreach =,$(filter-out SHELL GNUMAKEFLAGS clean_build_version cb_dir cb_build CBLD_CONFIG cb_config \
  $(dump_max) %.^e,$(.VARIABLES)),$(if $(or $(findstring command line,$(origin $=)),$(if $(findstring override,$(origin \
  $=)),$(filter $=,$(cb_config_exported_vars)))),ifneq (command line,$$(origin $=))$(newline)export override \
  $(cb_config_remember_var)endif$(newline),$(if $(findstring override,$(origin $=)),override $(cb_config_remember_var),$(if $(filter \
  $=,$(cb_config_exported_vars)),export $(cb_config_remember_var),$(if $(filter $=,$(cb_project_vars)),$(cb_config_remember_var),$(if \
  $(filter PATH,$=),$(if $(findstring environment,$(origin PATH)),export $(cb_config_remember_var))))))))

# add command-line variables to the list of exported variables
cb_config_exported_vars += $(foreach =,$(filter-out GNUMAKEFLAGS %.^e,$(.VARIABLES)),$(if $(findstring command line,$(origin $=)),$=))

# remember if PATH is exported
ifneq (,$(findstring environment,$(origin PATH)))
cb_config_exported_vars += PATH
endif

# finally define helper macro used to remember autoconfigured variables in the generated configuration makefile
# $1 - names of the macros
# $2 - 'export' if macros should be forcibly exported, empty - otherwise
# note: command-line variables are already saved
cb_config_remember_vars = $(eval config: config_text += $$(foreach =,$$1,$$(if $$(findstring command line,$$(origin $$=)),,$$(if \
  $$2,$$(if $$(findstring override,$$(origin $$=)),ifneq (command line,$$$$(origin $$=))$$(newline)export override \
  $$(cb_config_remember_var)endif$$(newline),export $$(cb_config_remember_var)),$$(if $$(findstring environment,$$(origin \
  $$=)),export )$$(cb_config_remember_var)))))$(eval cb_config_exported_vars += $(if $2,$$1,$$(foreach \
  =,$$1,$$(if $$(findstring environment,$$(origin $$=)),$$=))))$(call set_global,cb_config_exported_vars)

# temporary define, to be able to call cb_config_remember_vars below
# note: set_global is defined in $(cb_dir)/core/protection.mk
set_global:=

# write by that number of lines at a time while generating configuration makefile
# note: with too many lines it is possible to exceed maximum command string length
CBLD_CONFIG_WRITE_BY_LINES ?= 10

# remember CBLD_CONFIG_WRITE_BY_LINES in the $(CBLD_CONFIG) makefile
$(call cb_config_remember_vars,CBLD_CONFIG_WRITE_BY_LINES)

# generate configuration makefile
# note: suppress - defined in $(cb_dir)/core/_defs.mk
# note: write_text - defined in $(cb_dir)/utils/$(CBLD_UTILS).mk
# note: pass 1 as 4-th argument of 'suppress' function to not update percents of executed target makefiles
# note: 'config_text' - defined above as target-specific variable
config: F.^ := $(abspath $(firstword $(MAKEFILE_LIST)))
config: C.^ :=
config:| $(patsubst %/,%,$(dir $(cb_config)))
	$(call suppress,GEN,$(cb_config),,1)$(call write_text,$(config_text)cb_config_exported_vars := $(sort \
  $(cb_config_exported_vars)),$(cb_config),$(CBLD_CONFIG_WRITE_BY_LINES))

# if $(cb_config) makefile is generated under the $(cb_build), create that directory automatically,
# else - $(cb_config) makefile is outside of $(cb_build), configuration makefile directory must be created manually
ifneq (,$(filter $(cb_build)/%,$(cb_config)))
cb_needed_dirs += $(patsubst %/,%,$(dir $(cb_config)))
else
$(patsubst %/,%,$(dir $(cb_config))):
	$(error config file directory '$@' does not exist, it is not under '$(cb_build)', so should be created manually)
endif

endif # config

# protect variables from modification in target makefiles
# note: 'cb_target_makefile' variable is used here temporary and will be redefined later
cb_target_makefile += $(call set_global,cb_config_remember_vars cb_config_exported_vars cb_config cb_config_remember_var \
  CBLD_CONFIG_WRITE_BY_LINES)
