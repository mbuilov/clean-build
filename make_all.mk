# really define 'all' target only at end of top-level Makefile
ifdef SUB_LEVEL
$(error Don't include make_all.mk directly, instead execute $$(DEF_TAIL_CODE) at end of $(CURRENT_MAKEFILE))
endif

# define rules to create needed directories
# note: to avoid races when creating directories, create parent directories before child sub-directories,
# for example, if needed to create a/b/c1 and a/b/c2 - create a/b before creating a/b/c1 and a/b/c2 in parallel

GET_DIR = $(patsubst %/,%,$(subst ./,,$(filter %/,$(dir $1))))
SPLIT_DIRS = $(if $1,$1 $(call SPLIT_DIRS,$(GET_DIR)))
NEEDED_DIRS := $(sort $(call SPLIT_DIRS,$(patsubst $(XTOP)/%,%,$(NEEDED_DIRS))))

# define order-only dependencies
$(eval $(foreach x,$(NEEDED_DIRS),$(addprefix $(newline)$(XTOP)/$x:| $(XTOP)/,$(call GET_DIR,$x))))

# define rules to create needed directories
$(addprefix $(XTOP)/,$(NEEDED_DIRS)):
	$(call SUPRESS,MKDIR,$@)$(call MKDIR,$@)

# default target
all: $(TOP_MAKEFILES)
	@:

# note: evaluate and call $(CLEAN_COMMANDS) to cleanup things
clean:
	$(call RM,$(CLEAN))$(eval CLEAN_CODE := $(CLEAN_COMMANDS))$(CLEAN_CODE)

# note: don't try to update makefiles in $(MAKEFILE_LIST) - mark them as .PHONY targets
.PHONY: all clean $(MAKEFILE_LIST) $(TOP_MAKEFILES)

# drop make's default legacy rules - we'll use custom ones
.SUFFIXES:

# delete target file if any of rules to make it was failed
.DELETE_ON_ERROR:

# specify default target
.DEFAULT_GOAL := all
