#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# helper macro used to remember autoconfigured variables in the generated configuration makefile
# $1 - names of the macros
# $2 - non-empty if macros should be forcibly exported, empty - otherwise
# $3 - non-empty if macros should be saved again (likely with a new value)
config_remember_vars:=

# list of variables marked as 'exported' in the generated $(CBLD_CONFIG) makefile
# note: 'project_exported_vars' may be already defined either in the project configuration makefile (modified
#  version of the $(cb_dir)/stub/project.mk) or restored from the $(CBLD_CONFIG) makefile
ifneq (file,$(origin project_exported_vars))

project_exported_vars:=

else # file: project_exported_vars

# if 'project_exported_vars' was restored from the $(CBLD_CONFIG) makefile, simulate environment variables:
#  do not add the 'override' attribute to 'file' variables marked as exported in the $(CBLD_CONFIG) makefile
cb_project_vars := $(filter-out project_exported_vars $(project_exported_vars),$(cb_project_vars))

ifdef project_exported_vars

# variables in $(project_exported_vars) may legally overwrite environment variables
# note: %.^e - saved environment variables (see $(cb_dir)/stub/prepare.mk)
ifeq (command line,$(origin C))
ifeq (1,$C)
$(foreach =,$(project_exported_vars),$(if $(findstring file,$(origin $=^.e)),$(eval $$=^.e:=$$(value $$=))))
endif
endif

endif # defined: project_exported_vars
endif # file: project_exported_vars

ifneq (,$(filter config,$(MAKECMDGOALS)))

ifeq (,$(CBLD_CONFIG))
$(error CBLD_CONFIG - path to generated configuration makefile - is not defined)
endif

# config - is not a file, it's a goal
.PHONY: config

# encode a value of the variable $=
cb_config_remember_var = $(if $(findstring simple,$(flavor $v)),$= := $$(empty)$(subst \,$$(backslash),$(subst \
  $(comment),$$(comment),$(subst $(newline),$$(newline),$(subst $$,$$$$,$(value $=)))))$$(empty),define $=$(newline)$(subst \
  define,$$(keyword_define),$(subst endef,$$(keyword_endef),$(subst \,$$(backslash),$(value $=))))$(newline)endef)$(newline)

# Effective attributes of overridden variable v:
#  environment v=E  +  command line v=C  +  file     v=F  ->  command line exported v=C
#  environment v=E  +  command line v=C  +  override v=O  ->  override     exported v=O
#  environment v=E  +                       file     v=F  ->  file         exported v=F
#  environment v=E  +                       override v=O  ->  override     exported v=O
#                      command line v=C  +  file     v=F  ->  command line exported v=C
#                      command line v=C  +  override v=O  ->  override              v=O

# save current configuration:
# 1) command-line variables (exported by default)
# 2) variable PATH, likely exported - if it's origin is 'environment' or the PATH is in $(project_exported_vars) list
# 3) project-defined variables - those $(origin) is 'override' or the variable name is in $(cb_project_vars) list -
#  some of variables may be defined by the one-time included 'overrides' makefile (e.g. $(CBLD_OVERRIDES))
# note: once $(CBLD_CONFIG) makefile has been generated, variables defined in it may be altered only via command-line variables
# note: project_exported_vars - will be saved at end of generated $(CBLD_CONFIG) makefile

# list of variables stored in the 'config_text', updated as necessary
# note: ignore auto-defined variables: SHELL, GNUMAKEFLAGS, clean_build_version, cb_dir, cb_build, CBLD_CONFIG, $(dump_max)
# note: filter-out %.^e - saved environment variables (see $(cb_dir)/stub/prepare.mk)
# note: sort values to remove duplicates possibly added by the $(project_exported_vars)
cb_config_saved_vars := $(sort $(foreach =,$(filter-out SHELL GNUMAKEFLAGS clean_build_version cb_dir cb_build CBLD_CONFIG \
  $(dump_max) %.^e,$(.VARIABLES)),$(if $(or $(findstring command line,$(origin $=)),$(findstring override,$(origin \
  $=))),$=)) $(cb_project_vars) $(project_exported_vars))

# note: save current values of variables in the target-specific variable 'config_text' - variables may be overwritten later
config: config_text := define newline$(newline)$(newline)$(newline)endef$(newline)newline:= $$(newline)$(newline)comment:= \
  \$(comment)$(newline)empty:=$(newline)backslash:= \\$(comment)$(newline)keyword_define:= define$(newline)keyword_endef:= \
  endef$(newline)$(foreach =,$(cb_config_saved_vars),$(if $(or $(findstring command line,$(origin $=)),$(if $(findstring \
  override,$(origin $=)),$(filter $=,$(project_exported_vars)))),ifneq (command line,$$(origin $=))$(newline)export override \
  $(cb_config_remember_var)endif$(newline),$(if $(findstring override,$(origin $=)),override ,$(if \
  $(filter $=,$(project_exported_vars)),export ))$(cb_config_remember_var)))

# add command-line variables to the list of exported variables
# note: now 'project_exported_vars' list may contain duplicates - it will be sorted just before saving it to the $(CBLD_CONFIG) makefile
project_exported_vars += $(foreach =,$(cb_config_saved_vars),$(if $(findstring command line,$(origin $=)),$=))

# finally define helper macro used to remember autoconfigured variables in the generated configuration makefile
# $1 - names of the macros
# $2 - non-empty if macros should be forcibly exported, empty - otherwise
# $3 - non-empty if macros should be saved again (likely with a new value)
# note: if a variable is defined in the environment, it is saved as exported
# note: command-line variables are already saved, so filter them out
# note: variables in the list $1 _must_ be defined
# note: exported variables added to the 'project_exported_vars' list permanently
config_remember_vars = $(call config_remember_vars1,$(if $3,$(foreach =,$1,$(if $(findstring \
  command line,$(origin $=)),,$=)),$(filter-out $(cb_config_saved_vars),$1)),$2)
config_remember_vars1 = $(if $1,$(eval config: config_text += $$(foreach =,$$1,$$(if $$2,$$(if $$(findstring override,$$(origin \
  $$=)),ifneq (command line,$$$$(origin $$=))$$(newline)export override $$(cb_config_remember_var)endif$$(newline),export \
  $$(cb_config_remember_var)),$$(if $$(findstring environment,$$(origin $$=)),export )$$(cb_config_remember_var))))$(eval \
  project_exported_vars += $(if $2,$$1,$$(foreach =,$$1,$$(if $$(findstring environment,$$(origin $$=)),$$=))))$(eval \
  cb_config_saved_vars += $$1)$(call set_global,project_exported_vars cb_config_saved_vars))

# temporary define, to be able to call 'config_remember_vars' until 'set_global' is finally defined in the $(cb_dir)/core/protection.mk
set_global:=

# remember PATH value in the generated configuration makefile
PATH ?=

# write by that number of lines at a time while generating configuration makefile
# note: with too many lines it is possible to exceed maximum command string length
CBLD_CONFIG_WRITE_BY_LINES ?= 10

# remember PATH and CBLD_CONFIG_WRITE_BY_LINES in the $(CBLD_CONFIG) makefile
$(call config_remember_vars,PATH CBLD_CONFIG_WRITE_BY_LINES)

# generate configuration makefile
# note: suppress - defined in $(cb_dir)/core/_defs.mk
# note: write_text - defined in $(cb_dir)/utils/$(CBLD_UTILS).mk
# note: pass 1 as 4-th argument of 'suppress' function to not update percents of executed target makefiles
# note: 'config_text' - defined above as target-specific variable
config: F.^ := $(abspath $(firstword $(MAKEFILE_LIST)))
config: C.^ :=
config: cf := $(abspath $(CBLD_CONFIG))
config:| $(abspath $(dir $(CBLD_CONFIG)))
	$(call suppress,GEN,$(cf),,1)$(call write_text,$(config_text)project_exported_vars := $(sort \
  $(project_exported_vars)),$(cf),$(CBLD_CONFIG_WRITE_BY_LINES))

# if $(CBLD_CONFIG) makefile is generated under the $(cb_build), create that directory automatically,
# else - $(CBLD_CONFIG) makefile is outside of $(cb_build), configuration makefile directory must be created manually
ifneq (,$(filter $(cb_build)/%,$(abspath $(CBLD_CONFIG))))
cb_needed_dirs += $(abspath $(dir $(CBLD_CONFIG)))
else
$(abspath $(dir $(CBLD_CONFIG))):
	$(error config file directory '$@' does not exist, it is not under '$(cb_build)', so should be created manually)
endif

endif # config

# protect variables from modification in target makefiles
# note: do not trace calls to these macros
# note: 'cb_target_makefile' variable is used here temporary and will be redefined later
cb_target_makefile += $(call set_global,project_exported_vars cb_config_saved_vars PATH CBLD_CONFIG_WRITE_BY_LINES)

# protect variables from modification in target makefiles
# note: trace namespace: config
# note: 'cb_target_makefile' variable is used here temporary and will be redefined later
cb_target_makefile += $(call set_global,config_remember_vars cb_config_remember_var config_remember_vars1,config)
