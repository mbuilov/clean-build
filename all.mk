# really define 'all' target only at end of top-level makefile

# define rules to create needed directories
# note: to avoid races when creating directories, create parent directories before child sub-directories,
# for example, if needed to create a/b/c1 and a/b/c2 - create a/b before creating a/b/c1 and a/b/c2 in parallel

GET_DIR = $(patsubst %/,%,$(patsubst ./%,%,$(filter %/,$(dir $1))))
SPLIT_DIRS = $(if $1,$1 $(call SPLIT_DIRS,$(GET_DIR)))
NEEDED_DIRS := $(sort $(call SPLIT_DIRS,$(NEEDED_DIRS:$(XTOP)/%=%)))

# define order-only dependencies for directories
$(eval $(foreach x,$(NEEDED_DIRS),$(addprefix $(newline)$(XTOP)/$x:| $(XTOP)/,$(call GET_DIR,$x))))

# define rules to create $(XTOP)-related needed directories
$(addprefix $(XTOP)/,$(NEEDED_DIRS)):
	$(call SUP,MKDIR,$@)$(call MKDIR,$@)

# default target
# note: $(PROCESSED_MAKEFILES) - $(TOP)-related names of all processed target makefiles with suffix -
# (otherwise, if real makefile names are used - make always wants to recreate makefiles, even before clean target)
all: $(PROCESSED_MAKEFILES)
	@:

# note: also evaluate and execute $(CLEAN_COMMANDS) to cleanup things
clean:
	$(call RM,$(CLEAN))$(eval CLEAN_CODE := $(CLEAN_COMMANDS))$(CLEAN_CODE)

# empty rule: don't complain if order deps are not resolved when build started in sub-directory
$(ORDER_DEPS):

# note: don't try to update makefiles in $(MAKEFILE_LIST) - mark them as .PHONY targets
# note: $(PROCESSED_MAKEFILES) - names of processed makefiles with '-' suffix
.PHONY: all clean $(MAKEFILE_LIST) $(PROCESSED_MAKEFILES)

# drop make's default legacy rules - we'll use custom ones
.SUFFIXES:

# delete target file if failed to execute any of rules to make it
.DELETE_ON_ERROR:

# specify default target
.DEFAULT_GOAL := all
