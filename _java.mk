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

# function to form paths passed to $(JAVAC),$(SCALAC) or $(JARC)
jpath ?= $(ospath)

# path separator for $(FORM_CLASS_PATH)
JPATHSEP ?= $(PATHSEP)

# make target filename, $1 - JAR
# note: $(JAREXT) - either .jar or .war
FORM_JTRG ?= $(BIN_DIR)/$($1)$(JAREXT)

# form $(BUNDLES) or $(BUNDLE_FILES) list
# $1 - root directory
# $2 - files in root directory
FORM_BUNDLES ?= $(call FIXPATH,$1)|$(subst $(space),|,$2)

# form options for $(JARC)
# $1 - list of bundles to add to the .jar formed by FORM_BUNDLES
# dir1|name11|name12 dir2|name21|name22|... -> -C dir1 name11 -C dir1 name12 -C dir2 name21 -C dir2 name22...
JAR_BUNDLES_OPTIONS1 = $(addprefix $(call qpath,$(firstword $1),-C ) ,$(wordlist 2,999999,$1))
JAR_BUNDLES_OPTIONS ?= $(foreach x,$1,$(call JAR_BUNDLES_OPTIONS1,$(call jpath,$(subst |, ,$x))))

# make jar dependencies from bundle files
# $1 - list of files formed by FORM_BUNDLES
# dir1|name11|name12 dir2|name21|name22|... -> dir1/name11 dir1/name12 dir2/name21 dir2/name22...
MAKE_BUNDLE_DEPS1 = $(addprefix $(firstword $1)/,$(wordlist 2,999999,$1))
MAKE_BUNDLE_DEPS ?= $(foreach x,$1,$(call MAKE_BUNDLE_DEPS1,$(subst |, ,$x)))

# directory name java classes are compiled to
JCLS_DIR := cls

# $1 - entries for classpath list
# note: $(JPATHSEP) - either ; (windows) or : (unix)
FORM_CLASS_PATH ?= $(if $1,-classpath $(call qpath,$(subst $(space),$(JPATHSEP),$(strip $(jpath)))))

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
CREATE_JARGS_FILE1 = $(if $(VERBOSE),,@)$(call ECHO_LINE,$1) >> $(call ospath,$2)
CREATE_JARGS_FILE ?= $(call DEL,$2)$(newline)$(call \
  xcmd,CREATE_JARGS_FILE1,$1,$(ARGS_FILE_SOURCES_PER_LINE),$2)$(newline)$(if $(VERBOSE),,@)

# $1 - .java sources
# $2 - $(word $(ARGS_FILE_SOURCES_PER_LINE),$1)
# note: javac call is added just before creating jar - all .java sources are compiled at once
# target-specific: JAVAC_FLAGS, JOBJDIR, CLASSPATH, EXTJARS, JARS
JAVA_CC2 = $(if $2,$(call CREATE_JARGS_FILE,$1,$(JOBJDIR)/java.txt)) \
  $(JAVAC) $(JAVAC_OPTIONS) $(JAVAC_FLAGS) -d $(call jpath,$(JOBJDIR)/$(JCLS_DIR)) $(if \
  $2,@$(call jpath,$(JOBJDIR)/java.txt),$1) $(call FORM_CLASS_PATH,$(JOBJDIR)/$(JCLS_DIR) $(CLASSPATH) $(EXTJARS) $(JARS))$(newline)

# compile $1 - .java sources
JAVA_CC1 = $(call SUP,JAVAC,$1)$(call JAVA_CC2,$(jpath),$(word $(ARGS_FILE_SOURCES_PER_LINE),$1))
JAVA_CC ?= $(if $1,$(JAVA_CC1))

# $1 - .scala + .java sources
# $2 - $(word $(ARGS_FILE_SOURCES_PER_LINE),$1)
# target-specific: SCALAC_FLAGS, JOBJDIR, CLASSPATH, EXTJARS, JARS
SCALA_CC2 = $(if $2,$(call CREATE_JARGS_FILE,$1,$(JOBJDIR)/scala.txt)) \
  $(SCALAC) $(SCALAC_OPTIONS) $(SCALAC_FLAGS) -d $(call jpath,$(JOBJDIR)/$(JCLS_DIR)) $(if \
  $2,@$(call jpath,$(JOBJDIR)/scala.txt),$1) $(call FORM_CLASS_PATH,$(JOBJDIR)/$(JCLS_DIR) $(CLASSPATH) $(EXTJARS) $(JARS))$(newline)

# compile $1 - .scala
# note: $2 - .java sources only parsed by scala compiler - it does not compiles .java sources
SCALA_CC1 = $(call SUP,SCALAC,$1)$(call SCALA_CC2,$(call jpath,$2),$(word $(ARGS_FILE_SOURCES_PER_LINE),$2))
SCALA_CC ?= $(if $1,$(if $(SCALAC),$(call SCALA_CC1,$1,$1 $2),$(error \
  SCALAC not defined, example: $$(JAVA) $$(call FORM_CLASS_PATH,scala-compiler-2.11.6.jar) scala.tools.nsc.Main)))

# $1 - .jar target
# $2 - $(word $(ARGS_FILE_SOURCES_PER_LINE),$(ALL_BUNDLES))
# target-specific: JRFLAGS, MANIFEST, JOBJDIR, ALL_BUNDLES
JAR_LD1 = $(call SUP,JAR,$1)$(if $2,$(call CREATE_JARGS_FILE,$(ALL_BUNDLES),$(JOBJDIR)/jar.txt)) \
  $(JARC) $(JRFLAGS) -cf$(if $(MANIFEST),m) $(jpath) $(call jpath,$(MANIFEST)) -C $(call jpath,$(JOBJDIR)/$(JCLS_DIR)) . $(if \
  $2,@$(call jpath,$(JOBJDIR)/jar.txt),$(ALL_BUNDLES))$(DEL_ON_FAIL)

# make jar, $1 - .jar target
# note: always rebuild all sources if any of $(JARS), $(EXTJARS), $(JSRC), $(SCALA) or $(JSCALA) is newer than the target jar
# because $(JARC) do not checks cross-classes dependencies, it just creates .zip
# target-specific: JARS, EXTJARS, JSRC, SCALA, JSCALA, ALL_BUNDLES
JAR_LD ?= $(if $(filter $(JARS) $(EXTJARS) $(JSRC) $(SCALA) $(JSCALA),$?),$(call \
  SCALA_CC,$(SCALA),$(JSCALA))$(call JAVA_CC,$(JSRC)))$(call JAR_LD1,$1,$(word $(ARGS_FILE_SOURCES_PER_LINE),$(ALL_BUNDLES)))

# make list of full paths to built jars
# $1 - list of built jars
FORM_BUILT_JARS ?= $(addprefix $(BIN_DIR)/,$(addsuffix .jar,$1))

# $1 - target jar:              $(call FORM_JTRG,JAR)
# $2 - .java sources:           $(call FIXPATH,$(JSRC))
# $3 - .scala sources:          $(call FIXPATH,$(SCALA))
# $4 - .java sources for scala: $(call FIXPATH,$(JSCALA))
# $5 - manifest:                $(call FIXPATH,$(MANIFEST))
# $6 - objdir:                  $(call FORM_OBJ_DIR,JAR)
# $7 - jars:                    $(addprefix $(BIN_DIR)/,$(addsuffix .jar,$(JARS)))
ifndef JAR_TEMPLATE
define JAR_TEMPLATE
$(STD_TARGET_VARS)
NEEDED_DIRS += $6/$(JCLS_DIR)
$1: JSRC         := $2
$1: SCALA        := $3
$1: JSCALA       := $4
$1: MANIFEST     := $5
$1: JOBJDIR      := $6
$1: JARS         := $7
$1: EXTJARS      := $(EXTJARS)
$1: CLASSPATH    := $(CLASSPATH)
$1: ALL_BUNDLES  := $(call JAR_BUNDLES_OPTIONS,$(BUNDLES) $(BUNDLE_FILES))
$1: SCALAC       := $(SCALAC)
$1: JAVAC_FLAGS  := $(JAVAC_FLAGS)
$1: SCALAC_FLAGS := $(SCALAC_FLAGS)
$1: JRFLAGS      := $(JRFLAGS)
$1: $(EXTJARS) $7 $2 $3 $4 $5 $(call MAKE_BUNDLE_DEPS,$(BUNDLE_FILES)) | $6/$(JCLS_DIR)
	$$(eval $1: COMMANDS := $(subst $$,$$$$,$(JARACTIONS)))$$(COMMANDS)$$(call JAR_LD,$$@)
$(call TOCLEAN,$6)
endef
endif

# how to build .jar library template
# NOTE: if $(JSCALA) value is empty then it defaults to $(JSRC), to assign nothing to JSCALA use JSCALA = $(empty)
JAR_RULES ?= $(if $(JAR),$(call JAR_TEMPLATE,$(call FORM_JTRG,JAR),$(call \
  FIXPATH,$(JSRC)),$(call FIXPATH,$(SCALA)),$(call FIXPATH,$(if $(value JSCALA),$(JSCALA),$(JSRC))),$(call \
  FIXPATH,$(MANIFEST)),$(call FORM_OBJ_DIR,JAR),$(call FORM_BUILT_JARS,$(JARS))))

# Jar package version manifest template
# $1 - javay/server/
# $2 - Java API
# $3 - dot-separated digits: 1.2.3
# $4 - Acme Inc.
# $5 - javay.server
# $6 - free form string
# $7 - Vega Software Foundation
define JAR_VERSION_MANIFEST
Name: $1
Specification-Title: $2
Specification-Version: $3
Specification-Vendor: $4
Implementation-Title: $5
Implementation-Version: $6
Implementation-Vendor: $7
endef

# tools colors
# if JAR_COLOR is defined, other tools colors must also be defined
ifndef JAR_COLOR
JAR_COLOR    := [01;33m
JAVAC_COLOR  := [01;36m
SCALAC_COLOR := [01;36m
endif

# this code is normally evaluated at end of target makefile
ifndef DEFINE_JAVA_TARGETS_EVAL
define DEFINE_JAVA_TARGETS_EVAL
$(if $(MDEBUG),$(eval $(call DEBUG_TARGETS,$(BLD_JTARGETS),FORM_JTRG)))
$(eval $(JAR_RULES))
$(DEF_TAIL_CODE_EVAL)
endef
endif

# code to be called at beginning of target makefile
# note: target jar will depend on $(BUNDLE_FILES)
ifndef PREPARE_JAVA_VARS
define PREPARE_JAVA_VARS
$(subst $(space),:=$(newline),$(BLD_JTARGETS)):=
JSRC:=
SCALA:=
JSCALA:=
JARS:=
EXTJARS:=
CLASSPATH:=
BUNDLES:=
BUNDLE_FILES:=
MANIFEST:=
SCALAC:=
JAVAC_FLAGS:=
SCALAC_FLAGS:=
JRFLAGS:=
JARACTIONS:=
JAREXT := .jar
DEFINE_TARGETS_EVAL_NAME := DEFINE_JAVA_TARGETS_EVAL
MAKE_CONTINUE_EVAL_NAME  := MAKE_JAVA_EVAL
endef
ifeq (simple,$(flavor BLD_JTARGETS))
PREPARE_JAVA_VARS := $(PREPARE_JAVA_VARS)
endif
endif

# reset build targets, target-specific variables and variables modifiable in target makefiles
# then define bin/lib/obj/... dirs
# NOTE: expanded by $(MTOP)/java.mk
MAKE_JAVA_EVAL ?= $(eval $(PREPARE_JAVA_VARS)$(DEF_HEAD_CODE))

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,JLINT BLD_JTARGETS \
  jpath JPATHSEP FORM_JTRG JAR_BUNDLES_OPTIONS1 JAR_BUNDLES_OPTIONS MAKE_BUNDLE_DEPS1 MAKE_BUNDLE_DEPS \
  JCLS_DIR FORM_CLASS_PATH JAVAC_OPTIONS SCALAC_OPTIONS \
  ARGS_FILE_SOURCES_PER_LINE CREATE_JARGS_FILE1 CREATE_JARGS_FILE \
  JAVA_CC2 JAVA_CC1 JAVA_CC SCALA_CC2 SCALA_CC1 SCALA_CC JAR_LD1 JAR_LD FORM_BUILT_JARS JAR_TEMPLATE JAR_RULES \
  JAR_VERSION_MANIFEST JAR_COLOR JAVAC_COLOR SCALAC_COLOR DEFINE_JAVA_TARGETS_EVAL PREPARE_JAVA_VARS MAKE_JAVA_EVAL)
