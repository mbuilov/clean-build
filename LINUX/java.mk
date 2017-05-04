#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

JAVA := java
JAVAC := javac
JARC := jar

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,JAVA JAVAC JARC)
