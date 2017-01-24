#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# rules for building java sources

ifndef DEF_HEAD_CODE
include $(MTOP)/_defs.mk
endif

# run via $(MAKE) L=1 to run java compiler with -Xlint
ifeq ("$(origin L)","command line")
JLINT := $L
else
JLINT:=
endif

# what we may build by including $(MTOP)/java.mk (for ex. JAR := my_jar)
BLD_JTARGETS := JAR

include $(MTOP)/$(OS)/java.mk

# define code to print debug info about built targets
DEBUG_JAVA_TARGETS := $(call GET_DEBUG_TARGETS,$(BLD_JTARGETS),FORM_JTRG)

# make target filename, $1 - JAR
# note: $(JAREXT) - either .jar or .war
FORM_JTRG = $(if \
            $(filter JAR,$1),$(BIN_DIR)/$($1)$(JAREXT))

# form options for $(JARC)
# $1 - list of bundles to add to the .jar
# dir1 name1 dir2 name2... -> -c dir1 name1 -c dir2 name2...
FORM_JAR_BUNDLES = $(if $1,$(call qpath,$(call ospath,$(call FIXPATH,$(firstword $1))),-C ) $(call \
  qpath,$(call ospath,$(word 2,$1))) $(call FORM_JAR_BUNDLES,$(wordlist 3,999999,$1)))

# dir1 name1 dir2 name2... -> dir1/name1 dir2/name2...
MAKE_BUNDLE_DEPS = $(if $1,$(call FIXPATH,$(firstword $1)/$(word 2,$1)) $(call MAKE_BUNDLE_DEPS,$(wordlist 3,999999,$1)))

# $1 - entries for classpath list
# note: $(PATHSEP) - either ; (windows) or : (unix)
FORM_CLASS_PATH = -classpath $(call qpath,$(subst $(space),$(PATHSEP),$(strip $(ospath))))

ifeq (undefined,$(origin JAVAC_OPTIONS))
JAVAC_OPTIONS := $(if $(JLINT),-Xlint)$(if $(DEBUG), -g) -encoding utf8
endif

ifeq (undefined,$(origin SCALAC_OPTIONS))
SCALAC_OPTIONS := $(if $(DEBUG),-g:vars)
endif

ifndef ARGS_FILE_SOURCES_PER_LINE
ARGS_FILE_SOURCES_PER_LINE := 40
endif

# create arguments file for java compiler
# $1 - sources
# $2 - args file name
CREATE_JARGS_FILE1 = $(if $(VERBOSE),,@)$(call ECHO_LINE,$1) >> $2
CREATE_JARGS_FILE = $(call DEL,$2)$(newline)$(call \
  xcmd,CREATE_JARGS_FILE1,$1,$(ARGS_FILE_SOURCES_PER_LINE),$2)$(newline)$(if $(VERBOSE),,@)

# compile $1 - .java sources
# note: javac call is added just before creating jar - all .java sources are compiled at once
# target-specific: JAVAC_FLAGS, OBJDIR, CLASSPATH, EXTJARS, JARS
JAVA_CC2 = $(if $(word $(ARGS_FILE_SOURCES_PER_LINE),$1),$(call CREATE_JARGS_FILE,$1,$(OBJDIR)/java.txt)) \
  $(JAVAC) $(JAVAC_OPTIONS) $(JAVAC_FLAGS) -d $(call ospath,$(OBJDIR)/cls) $(if \
  $(word $(ARGS_FILE_SOURCES_PER_LINE),$1),@$(OBJDIR)/java.txt,$1) $(call \
  FORM_CLASS_PATH,$(OBJDIR)/cls $(CLASSPATH) $(EXTJARS) $(JARS))$(newline)
JAVA_CC1 = $(call SUP,JAVAC,$1)$(call JAVA_CC2,$(ospath))
JAVA_CC  = $(if $1,$(JAVA_CC1))

# compile $1 - .scala, parse $2 - .java sources
# note: $2 - .java sources only parsed by scala compiler - it does not compiles .java sources
# target-specific: SCALAC_FLAGS, OBJDIR, CLASSPATH, EXTJARS, JARS
SCALA_CC2 = $(if $(word $(ARGS_FILE_SOURCES_PER_LINE),$1),$(call CREATE_JARGS_FILE,$1,$(OBJDIR)/scala.txt)) \
  $(SCALAC) $(SCALAC_OPTIONS) $(SCALAC_FLAGS) -d $(call ospath,$(OBJDIR)/cls) $(if \
  $(word $(ARGS_FILE_SOURCES_PER_LINE),$1),@$(OBJDIR)/scala.txt,$1) $(call \
  FORM_CLASS_PATH,$(OBJDIR)/cls $(CLASSPATH) $(EXTJARS) $(JARS))$(newline)
SCALA_CC1 = $(call SUP,SCALAC,$1)$(call SCALA_CC2,$(call ospath,$1 $2))
SCALA_CC  = $(if $1,$(if $(SCALAC),$(SCALA_CC1),$(error \
  SCALAC not defined, example: $$(JAVA) $$(call FORM_CLASS_PATH,scala-compiler-2.11.6.jar) scala.tools.nsc.Main)))

# make jar, $1 - .jar target
# target-specific: JRFLAGS, MANIFEST, OBJDIR, ALL_BUNDLES
JAR_LD1 = $(call SUP,JAR,$1)$(if $(word $(ARGS_FILE_SOURCES_PER_LINE),$(ALL_BUNDLES)),$(call \
  CREATE_JARGS_FILE,$(ALL_BUNDLES),$(OBJDIR)/jar.txt))$(JARC) $(JRFLAGS) -cf$(if $(MANIFEST),m) $(ospath) $(call \
  ospath,$(MANIFEST)) -C $(call ospath,$(OBJDIR)/cls) . $(if \
  $(word $(ARGS_FILE_SOURCES_PER_LINE),$(ALL_BUNDLES)),@$(OBJDIR)/jar.txt,$(ALL_BUNDLES))$(DEL_ON_FAIL)

# note: always rebuild all sources if any of $(JARS), $(EXTJARS), $(JSRC), $(SCALA) or $(JSCALA) is newer than the target jar
# because $(JARC) do not checks cross-classes dependencies, it just creates .zip
# target-specific: JARS, EXTJARS, JSRC, SCALA, JSCALA
JAR_LD = $(if $(filter $(JARS) $(EXTJARS) $(JSRC) $(SCALA) $(JSCALA),$?),$(call \
  SCALA_CC,$(SCALA),$(JSCALA))$(call JAVA_CC,$(JSRC)))$(JAR_LD1)

# $1 - target file: $(call FORM_JTRG,JAR)
# $2 - sources:     $(call FIXPATH,$(JSRC))
# $3 - sources:     $(call FIXPATH,$(SCALA))
# $4 - sources:     $(call FIXPATH,$(JSCALA))
# $5 - manifest:    $(call FIXPATH,$(MANIFEST))
# $6 - objdir:      $(call FORM_OBJ_DIR,JAR)
# $7 - jars:        $(addprefix $(BIN_DIR)/,$(addsuffix .jar,$(JARS)))
define JAR_TEMPLATE
$(STD_TARGET_VARS)
NEEDED_DIRS += $6/cls
$1: JSRC         := $2
$1: SCALA        := $3
$1: JSCALA       := $4
$1: MANIFEST     := $5
$1: OBJDIR       := $6
$1: JARS         := $7
$1: EXTJARS      := $(EXTJARS)
$1: CLASSPATH    := $(CLASSPATH)
$1: ALL_BUNDLES  := $(call FORM_JAR_BUNDLES,$(BUNDLES) $(BUNDLE_FILES))
$1: SCALAC       := $(SCALAC)
$1: JAVAC_FLAGS  := $(JAVAC_FLAGS)
$1: SCALAC_FLAGS := $(SCALAC_FLAGS)
$1: JRFLAGS      := $(JRFLAGS)
$1: $(EXTJARS) $7 $2 $3 $4 $5 $(call MAKE_BUNDLE_DEPS,$(BUNDLE_FILES)) | $6/cls
	$$(eval $1: COMMANDS := $(subst $$,$$$$,$(JARACTIONS)))$$(COMMANDS)$$(call JAR_LD,$$@)
$(call TOCLEAN,$6)
endef

# how to build .jar library template
# NOTE: if $(JSCALA) value is empty then it defaults to $(JSRC), to assign nothing to JSCALA use JSCALA = $(empty)
JAR_RULES = $(if $(JAR),$(call JAR_TEMPLATE,$(call FORM_JTRG,JAR),$(call \
  FIXPATH,$(JSRC)),$(call FIXPATH,$(SCALA)),$(call FIXPATH,$(if $(value JSCALA),$(JSCALA),$(JSRC))),$(call \
  FIXPATH,$(MANIFEST)),$(call FORM_OBJ_DIR,JAR),$(addprefix $(BIN_DIR)/,$(addsuffix .jar,$(JARS)))))

# tools colors
JAR_COLOR    := [01;33m
JAVAC_COLOR  := [01;36m
SCALAC_COLOR := [01;36m

# this code is normally evaluated at end of target makefile
define DEFINE_JAVA_TARGETS_EVAL
$(if $(MDEBUG),$(eval $(DEBUG_JAVA_TARGETS)))
$(eval $(JAR_RULES))
$(DEF_TAIL_CODE_EVAL)
endef

# code to be called at beginning of target makefile
# note: target jar will depend on $(BUNDLE_FILES)
define PREPARE_JAVA_VARS
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
SCALAC_FLAGS :=
JRFLAGS      :=
JARACTIONS   :=
JAREXT       := .jar
DEFINE_TARGETS_EVAL_NAME := DEFINE_JAVA_TARGETS_EVAL
MAKE_CONTINUE_EVAL_NAME  := MAKE_JAVA_EVAL
endef

# reset build targets, target-specific variables and variables modifiable in target makefiles
# then define bin/lib/obj/... dirs
# NOTE: expanded by $(MTOP)/java.mk
MAKE_JAVA_EVAL = $(eval $(PREPARE_JAVA_VARS)$(DEF_HEAD_CODE))

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,JLINT BLD_JTARGETS DEBUG_JAVA_TARGETS \
  FORM_JTRG FORM_JAR_BUNDLES MAKE_BUNDLE_DEPS FORM_CLASS_PATH JAVAC_OPTIONS SCALAC_OPTIONS \
  ARGS_FILE_SOURCES_PER_LINE CREATE_JARGS_FILE1 CREATE_JARGS_FILE \
  JAVA_CC2 JAVA_CC1 JAVA_CC SCALA_CC2 SCALA_CC1 SCALA_CC JAR_LD1 JAR_LD JAR_TEMPLATE JAR_RULES \
  JAR_COLOR JAVAC_COLOR SCALAC_COLOR DEFINE_JAVA_TARGETS_EVAL PREPARE_JAVA_VARS MAKE_JAVA_EVAL)
