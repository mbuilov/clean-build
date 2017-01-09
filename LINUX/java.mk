#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPLv2+, see COPYING
#----------------------------------------------------------------------------------

OSTYPE := UNIX

ifndef JAVA
JAVA := java
endif

ifndef JAVAC
JAVAC := javac
endif

ifndef JARC
JARC := jar
endif

PATHSEP := :

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,JAVA JAVAC JARC PATHSEP)
