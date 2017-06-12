#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# should be included after $(CLEAN_BUILD_DIR)/java.mk

ifeq (,$(filter-out undefined environment,$(origin DO_TEST_JAR_TEMPLATE)))

# rule for running test java archive, for 'check' target

# run $(JAR) and send its stderr to $(JAR).out
# $1 - $(call FORM_JTRG,JAR)
# $2 - main class name, for example com.mycomp.myproj.MyMainClass
# $3 - $(call FORM_BUILT_JARS,$(JARS)) + class paths/jars needed to run the test
# $4 - auxiliary parameters to pass to executed jar
# $5 - options to pass to $(JAVA) interpreter
# note: $(JAVA) - path to java interpreter must be defined
define DO_TEST_JAR_TEMPLATE
$(call ADD_GENERATED,$1.out)
$1.out: $1
	$$(call SUP,TEST,$$@)$(JAVA) $5 $$(call FORM_CLASS_PATH,$3 $$<) $2 $4 > $$@
endef

ifneq (,$(filter check clean,$(MAKECMDGOALS)))

# for 'check' target, run built jar(s)
# $1 - main class name, for example com.mycomp.myproj.MyMainClass
# $2 - class paths/jars needed to run the test
# $3 - auxiliary parameters to pass to executed jar
# $4 - options to pass to $(JAVA) interpreter
DO_TEST_JAR = $(eval $(call DO_TEST_JAR_TEMPLATE,$(call FORM_JTRG,JAR),$1,$(call FORM_BUILT_JARS,$(JARS)) $2,$3,$4))

else # not check or clean

DO_TEST_JAR:=

endif # not check or clean

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,DO_TEST_JAR_TEMPLATE DO_TEST_JAR)

endif # DO_TEST_JAR_TEMPLATE
