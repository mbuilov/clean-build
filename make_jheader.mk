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

# $1 - list of bundles to add to the .jar: dir1 name1 dir2 name2...
FORM_JAR_BUNDLES = $(if $1,$(call qpath,$(call ospath,$(call FIXPATH,$(firstword $1))),-C ) $(call \
  qpath,$(call ospath,$(word 2,$1))) $(call FORM_JAR_BUNDLES,$(wordlist 3,999999,$1)))

# dir1 name1 dir2 name2... -> dir1/name1 dir2/name2...
MAKE_BUNDLE_DEPS = $(if $1,$(VPREFIX)$(firstword $1)/$(word 2,$1) $(call MAKE_BUNDLE_DEPS,$(wordlist 3,999999,$1)))

# $1 - entries for classpath list
FORM_CLASS_PATH = -classpath $(call qpath,$(subst $(space),$(PATHSEP),$(strip $(ospath))))

ifndef JAVAC_OPTIONS
JAVAC_OPTIONS  := $(if $(JLINT),-Xlint) $(if $(DEBUG),-g)
endif

ifndef SCALAC_OPTIONS
SCALAC_OPTIONS := $(if $(DEBUG),-g:vars)
endif

# compile $1 - .java sources
JAVA_CC1 = $(call SUPRESS,JAVAC,$1)$(JAVAC) $(JAVAC_OPTIONS) $(JAVAC_FLAGS) -d $(call ospath,$(OBJDIR)) $(ospath) $(call \
  FORM_CLASS_PATH,$(OBJDIR) $(CLASSPATH) $(EXTJARS) $(JARS))$(newline)
JAVA_CC  = $(if $1,$(JAVA_CC1))

# compile $1 - .scala, parse $2 - .java sources
SCALA_CC1 = $(call SUPRESS,SCALAC,$1)$(SCALAC) $(SCALAC_OPTIONS) -d $(call ospath,$(OBJDIR)) $(call ospath,$1 $2) $(call \
  FORM_CLASS_PATH,$(OBJDIR) $(CLASSPATH) $(EXTJARS) $(JARS))$(newline)
SCALA_CC  = $(if $1,$(if $(SCALAC),$(SCALA_CC1),$(error \
  SCALAC not defined, example: $$(JAVA) $$(call FORM_CLASS_PATH,scala-compiler-2.11.6.jar) scala.tools.nsc.Main)))

# make jar, $1 - .jar target
JAR_LD1  = $(call SUPRESS,JAR,$1)$(JARC) $(JRFLAGS) -cf$(if $(MANIFEST),m) $(ospath) $(call ospath,$(MANIFEST)) -C $(call \
            ospath,$(OBJDIR)) . $(call FORM_JAR_BUNDLES,$(ALL_BUNDLES))$(DEL_ON_FAIL)

# rebuild all sources if any of $(JARS) or $(EXTJARS) is newer that the target jar
# rebuild all $(SCALA) if any of $(JSCALA) is newer that the target jar
# else rebuild only changed sources
JAR_LD   = $(if $(filter $(JARS) $(EXTJARS),$?),$(call SCALA_CC,$(SCALA),$(JSCALA))$(call JAVA_CC,$(JSRC)),$(call \
            SCALA_CC,$(if $(filter $(JSCALA),$?),$(SCALA),$(filter $(SCALA),$?)),$(JSCALA))$(call \
            JAVA_CC,$(filter $(JSRC),$?)))$(JAR_LD1)

# $1 - target file: $(call FORM_JTRG,JAR)
# $2 - sources:     $(call FIXPATH,$(JSRC))
# $3 - sources:     $(call FIXPATH,$(SCALA))
# $4 - sources:     $(call FIXPATH,$(JSCALA))
# $5 - manifest:    $(call FIXPATH,$(MANIFEST))
# $6 - objdir:      $(call FORM_OBJ_DIR,JAR)
# $7 - jars:        $(addprefix $(BIN_DIR)/,$(addsuffix .jar,$(JARS)))
define JAR_TEMPLATE
NEEDED_DIRS += $6
$(call STD_TARGET_VARS,$1)
$1: JSRC         := $2
$1: SCALA        := $3
$1: JSCALA       := $4
$1: MANIFEST     := $5
$1: OBJDIR       := $6
$1: JARS         := $7
$1: EXTJARS      := $(EXTJARS)
$1: CLASSPATH    := $(CLASSPATH)
$1: ALL_BUNDLES  := $(BUNDLES) $(BUNDLE_FILES)
$1: VPREFIX      := $(VPREFIX)
$1: SCALAC       := $(SCALAC)
$1: JAVAC_FLAGS  := $(JAVAC_FLAGS)
$1: JRFLAGS      := $(JRFLAGS)
$1: $(EXTJARS) $7 $2 $3 $4 $5 $(call MAKE_BUNDLE_DEPS,$(BUNDLE_FILES)) | $(BIN_DIR) $6 $(ORDER_DEPS)
	$$(eval $1: COMMANDS := $(subst $$,$$$$,$(JARACTIONS)))$$(COMMANDS)$$(call JAR_LD,$$@)
$(CURRENT_MAKEFILE_TM): $1
CLEAN += $6 $1
endef

# how to build .jar library template
# NOTE: if JSCALA value is empty then it defaults to $(JSRC), to assign nothing to JSCALA use JSCALA = $(empty)
JAR_RULES = $(if $(JAR),$(call JAR_TEMPLATE,$(call FORM_JTRG,JAR),$(call \
  FIXPATH,$(JSRC)),$(call FIXPATH,$(SCALA)),$(call FIXPATH,$(if $(value JSCALA),$(JSCALA),$(JSRC))),$(call \
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
JAR          :=
JSRC         :=
SCALA        :=
JSCALA       :=
JARS         :=
EXTJARS      :=
CLASSPATH    :=
BUNDLES      :=
BUNDLE_FILES :=
MANIFEST     :=
SCALAC       :=
JAVAC_FLAGS  :=
JRFLAGS      :=
JARACTIONS   :=
JAREXT       := .jar
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
