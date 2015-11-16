ifndef MAKE_JHEADER_INCLUDED

# this file normally included at beginning of target Makefile
# used for building java sources
MAKE_JHEADER_INCLUDED := 1

# run via $(MAKE) L=1 to run java compiler with -Xlint
ifeq ("$(origin L)","command line")
JLINT := $L
else
JLINT:=
endif

# what we may build by including make_jheader.mk (for ex. JAR := my_jar)
BLD_JTARGETS := JAR

# avoid execution of $(DEF_HEAD_CODE) by make_defs.mk - $(DEF_HEAD_CODE) will be evaluated at end of this file
MAKE_DEFS_INCLUDED_BY := make_jheader.mk
include $(MTOP)/make_defs.mk
include $(MTOP)/$(OS)/make_jheader.mk

# define code to print debug info about built targets
DEBUG_JTARGETS := $(call GET_DEBUG_TARGETS,$(BLD_JTARGETS),FORM_JTRG)

# make target filename, $1 - JAR
FORM_JTRG = $(if \
            $(filter JAR,$1),$(BIN_DIR)/$($1)$(JAREXT))

JAVAC_OPTIONS := $(if $(JLINT),-Xlint) $(if $(DEBUG),-g)

# $1 - list of bundles to add to the .jar: dir1 name1 dir2 name2...
FORM_JAR_BUNDLES = $(if $1,$(call qpath,$(call ospath,$(call FIXPATH,$(firstword $1))),-C ) $(call \
  qpath,$(call ospath,$(word 2,$1))) $(call FORM_JAR_BUNDLES,$(wordlist 3,999999,$1)))

# $1 - entries for classpath list
FORM_CLASS_PATH = -classpath $(call qpath,$(subst $(space),$(PATHSEP),$(strip $(ospath))))

# $1 - sources
JAVA_CC1 = $(call SUPRESS,JAVAC,$1) $(JAVAC) $(JAVAC_OPTIONS) $(JCFLAGS) -d $(call ospath,$(OBJDIR)) $(ospath) $(call \
  FORM_CLASS_PATH,$(OBJDIR) $(CLASSPATH) $(EXTJARS) $(JARS))$(newline)
JAVA_CC  = $(if $1,$(JAVA_CC1))

# $1 - target
JAR_LD1  = $(call SUPRESS,JAR,$1)$(JARC) $(JRFLAGS) -cf$(if $(MANIFEST),m) $(ospath) $(call ospath,$(MANIFEST)) -C $(call \
            ospath,$(OBJDIR)) . $(call FORM_JAR_BUNDLES,$(BUNDLES))$(DEL_ON_FAIL)
JAR_LD   = $(call JAVA_CC,$(if $(filter $(JARS) $(EXTJARS),$?),$(JSRC),$(filter $(JSRC),$?)))$(JAR_LD1)

# $1 - target file: $(call FORM_JTRG,JAR)
# $2 - sources:     $(call FIXPATH,$(JSRC))
# $3 - manifest:    $(call FIXPATH,$(MANIFEST))
# $4 - objdir:      $(call FORM_OBJ_DIR,JAR)
# $5 - jars:        $(addprefix $(BIN_DIR)/,$(addsuffix .jar,$(JARS)))
define JAR_TEMPLATE
NEEDED_DIRS += $4
$(call STD_TARGET_VARS,$1)
$1: JSRC      := $2
$1: MANIFEST  := $3
$1: OBJDIR    := $4
$1: JARS      := $5
$1: EXTJARS   := $(EXTJARS)
$1: CLASSPATH := $(CLASSPATH)
$1: BUNDLES   := $(BUNDLES)
$1: VPREFIX   := $(VPREFIX)
$1: JCFLAGS   := $(JCFLAGS)
$1: JRFLAGS   := $(JRFLAGS)
$1: $(EXTJARS) $5 $2 $3 | $(BIN_DIR) $4 $(ORDER_DEPS)
	$$(eval COMMANDS := $(subst $$,$$$$,$(JARACTIONS)))$$(COMMANDS)$$(call JAR_LD,$$@)
$(CURRENT_MAKEFILE_TM): $1
CLEAN += $4 $1
endef

# how to build .jar library template
JAR_RULES = $(if $(JAR),$(call JAR_TEMPLATE,$(call FORM_JTRG,JAR),$(call FIXPATH,$(JSRC)),$(call \
  FIXPATH,$(MANIFEST)),$(call FORM_OBJ_DIR,JAR),$(addprefix $(BIN_DIR)/,$(addsuffix .jar,$(JARS)))))

# this file normally included at end of target Makefile
define DEFINE_JTARGETS_EVAL
$(if $(MDEBUG),$(eval $(DEBUG_JTARGETS)))
$(eval $(JAR_RULES))
$(DEF_TAIL_CODE)
endef
DEFINE_JTARGETS = $(if $(DEFINE_JTARGETS_EVAL),)

# code to be called at beginning of target makefile
define PREPARE_JVARS
JAR         :=
JSRC        :=
JARS        :=
EXTJARS     :=
CLASSPATH   :=
BUNDLES     :=
MANIFEST    :=
JCFLAGS     :=
JRFLAGS     :=
JARACTIONS  :=
JAREXT      := .jar
endef

# increment MAKE_CONT, eval tail code with $(DEFINE_JTARGETS)
# and start next circle - simulate including of "make_jheader.mk"
define MAKE_JCONTINUE_EVAL
$(eval MAKE_CONT := $(MAKE_CONT) 2)
$(DEFINE_JTARGETS_EVAL)
$(eval $(PREPARE_JVARS))
$(eval $(DEF_HEAD_CODE))
$(eval MAKE_CONT += 1)
endef
MAKE_JCONTINUE = $(if $(if $1,$(SAVE_VARS))$(MAKE_JCONTINUE_EVAL)$(if $1,$(RESTORE_VARS)),)

endif # MAKE_JHEADER_INCLUDED

# reset build targets, target-specific variables and variables modifiable in target makefiles
$(eval $(PREPARE_JVARS))

# define bin/lib/obj/etc... dirs
$(eval $(DEF_HEAD_CODE))
