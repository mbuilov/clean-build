#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# must be included after $(MTOP)/java.mk

ifndef DO_TEST_JAR_TEMPLATE

# rule for running test java archive for 'check' target

# run $(JAR) and dump its stderr to $(JAR).out
# $1 - $(call FORM_JTRG,JAR)
# $2 - auxiliary parameters to pass to executed jar
# $3 - additional class paths needed to run executed jar
# $4 - options to pass to $(JAVA)
# note: $(JAVA) - path to java interpreter must be defined
define DO_TEST_JAR_TEMPLATE
$(call ADD_GENERATED,$1.out)
$1.out: $1
	$$(call SUP,TEST,$$@)$(JAVA) $(call FORM_CLASS_PATH,$3) $4 -jar $$(call jpath,$$<) $2 > $$@
endef

# $1 - main class name
# $2 - list of jars
JTEST_MANIFEST ?= $(if $2,Class-Path: $2$(newline))Main-Class: $1

ifneq ($(filter check clean,$(MAKECMDGOALS)),)

# for 'check' target, run built jar(s)
# $1 - auxiliary parameters to pass to executed jar
# $2 - main class name
# $3 - list of jars
# $2 - options to pass to $(JAVA)
# $3 - additional class paths needed to run executed jar
DO_TEST_JAR ?= $(eval $(call DO_TEST_JAR_TEMPLATE,$(call FORM_JTRG,JAR),$1,$2,$3))

endif # check

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,DO_TEST_JAR_TEMPLATE DO_TEST_JAR)

endif # DO_TEST_JAR_TEMPLATE
