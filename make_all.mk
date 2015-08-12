# really define 'all' target only at end of top-level Makefile
ifdef SUB_LEVEL
$(error Don't include make_all.mk directly, instead execute $$(DEF_TAIL_CODE) at end of $(CURRENT_MAKEFILE))
endif

# rules to create needed directories

GET_DIR = $(patsubst %/,%,$(subst ./,,$(filter %/,$(dir $1))))
SPLIT_DIRS = $(if $1,$1 $(call SPLIT_DIRS,$(GET_DIR)))
NEEDED_DIRS := $(sort $(call SPLIT_DIRS,$(patsubst $(XTOP)/%,%,$(NEEDED_DIRS))))

$(eval $(foreach x,$(NEEDED_DIRS),$(addprefix $(newline)$(XTOP)/$x:| $(XTOP)/,$(call GET_DIR,$x))))

$(addprefix $(XTOP)/,$(NEEDED_DIRS)):
	$(call SUPRESS,MKDIR,$@)$(call MKDIR,$@)

$(PROCESSED_MAKEFILES): | $(BLD_MAKEFILES_TIMESTAMPS_DIR)
	$(call SUPRESS,TOUCH,$@)$(call TOUCH,$@)

all: $(PROCESSED_MAKEFILES)
	@:

clean:
	$(call RM,$(CLEAN) $(PROCESSED_MAKEFILES))$(eval CLEAN_CODE := $(CLEAN_COMMANDS))$(CLEAN_CODE)

.PHONY: all clean $(MAKEFILE_LIST)
.DEFAULT_GOAL := all
.SUFFIXES:
