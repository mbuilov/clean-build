ifndef MAKE_JHEADER_INCLUDED

# this file normally included at beginning of target Makefile
MAKE_JHEADER_INCLUDED := 1

# run via $(MAKE) L=1 to run java compiler with -Xlint
ifeq ("$(origin L)","command line")
JLINT := $L
else
JLINT:=
endif

BLD_JTARGETS := JAR

# avoid execution of $(DEF_HEAD_CODE) by make_defs.mk - $(DEF_HEAD_CODE) will be evaluated at end of this file
MAKE_DEFS_INCLUDED_BY := make_jheader.mk
include $(MTOP)/make_defs.mk
include $(MTOP)/$(OS)/make_jheader.mk

# $(BLD_JTARGETS) is now defined, define $(DEBUG_JTARGETS)
DEBUG_JTARGETS := $(call GET_DEBUG_TARGETS,$(BLD_JTARGETS),FORM_JTRG)

# make target filename, $1 - JAR
FORM_JTRG = $(if \
            $(filter JAR,$1),$(BIN_DIR)/$($1)$(JAREXT))

JAVAC_OPTIONS := $(if $(JLINT),-Xlint) $(if $(filter %D,$(TARGET)),-g)

# $1 - list of bundles to add to the .jar: dir1 name1 dir2 name2...
FORM_JAR_BUNDLES = $(if $1,$(call pqpath,-C ,$(call ospath,$(call FIXPATH,$(firstword $1)))) $(call \
  qpath,$(call ospath,$(word 2,$1))) $(call FORM_JAR_BUNDLES,$(wordlist 3,999999,$1)))

# $1 - entries for classpath list
FORM_CLASS_PATH = -classpath $(call qpath,$(subst $(space),$(PATHSEP),$(strip $(ospath))))

# $1 - sources
JAVA_CC1 = $(call SUPRESS,JAVAC,$1) $(JAVAC) $(JAVAC_OPTIONS) $(JCFLAGS) -classpath $(call ospath,$(OBJDIR)) -d $(call ospath,$(OBJDIR)) $(ospath) $(if \
  $(strip $(CLASSPATH)$(EXTJARS)$(JARS)),$(call FORM_CLASS_PATH,$(CLASSPATH) $(EXTJARS) $(addprefix $(BIN_DIR)/,$(addsuffix .jar,$(JARS)))))$(newline)
JAVA_CC  = $(if $1,$(JAVA_CC1))

# $1 - target
JAR_LD1  = $(call SUPRESS,JAR,$1)$(JARC) $(JRFLAGS) -cf$(if $(MANIFEST),m) $(ospath) $(call ospath,$(call FIXPATH,$(MANIFEST))) -C $(call \
            ospath,$(OBJDIR)) . $(call FORM_JAR_BUNDLES,$(BUNDLES))$(DEL_ON_FAIL)
JAR_LD   = $(call JAVA_CC,$(filter $(JSRC),$?))$(JAR_LD1)

# $1 - target file: $(call FORM_JTRG,JAR)
# $2 - sources:     $(call FIXPATH,$(JSRC))
# $3 - objdir:      $(call FORM_OBJ_DIR,JAR)
define JAR_TEMPLATE
NEEDED_DIRS += $3
$(call STD_TARGET_VARS,$1)
$1: JSRC      := $2
$1: OBJDIR    := $3
$1: JARS      := $(JARS)
$1: EXTJARS   := $(EXTJARS)
$1: CLASSPATH := $(CLASSPATH)
$1: BUNDLES   := $(BUNDLES)
$1: VPREFIX   := $(VPREFIX)
$1: MANIFEST  := $(MANIFEST)
$1: JCFLAGS   := $(JCFLAGS)
$1: JRFLAGS   := $(JRFLAGS)
$1: $(addprefix $(BIN_DIR)/,$(addsuffix .jar,$(JARS))) $2 $(CURRENT_DEPS) | $(BIN_DIR) $3
	$$(eval COMMANDS := $(subst $$,$$$$,$(JARACTIONS)))$$(COMMANDS)$$(call JAR_LD,$$@)
$(CURRENT_MAKEFILE_TM): $1
CLEAN += $3 $1
endef

# how to build .jar library template
JAR_RULES = $(if $(JAR),$(call JAR_TEMPLATE,$(call FORM_JTRG,JAR),$(call FIXPATH,$(JSRC)),$(call FORM_OBJ_DIR,JAR)))

# this file normally included at end of target Makefile
define DEFINE_JTARGETS_EVAL
$(if $(MDEBUG),$(eval $(DEBUG_JTARGETS)))
$(eval $(JAR_RULES))
$(DEF_TAIL_CODE)
endef
DEFINE_JTARGETS = $(if $(DEFINE_JTARGETS_EVAL),)

# code to be called at beginning of makefile
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

# increment SUB_LEVEL, mark MAKE_CONT, eval tail code with $(DEFINE_JTARGETS)
# and start next circle - restore SUB_LEVEL and simulate including of "make_jheader.mk"
define MAKE_JCONTINUE_EVAL
SUB_LEVEL := $(SUB_LEVEL) 1
MAKE_CONT := $(MAKE_CONT) 2
$(DEFINE_JTARGETS)
SUB_LEVEL := $(wordlist 2,999999,$(SUB_LEVEL))
$(eval $(PREPARE_JVARS))
$(eval $(DEF_HEAD_CODE))
MAKE_CONT += 1
endef
MAKE_JCONTINUE = $(if $(if $1,$(SAVE_VARS))$(MAKE_JCONTINUE_EVAL)$(if $1,$(RESTORE_VARS)),)

endif # MAKE_JHEADER_INCLUDED

# reset build targets, target-specific variables and variables modifiable in target makefiles
$(eval $(PREPARE_JVARS))

# define bin/lib/obj/etc... dirs
$(eval $(DEF_HEAD_CODE))
