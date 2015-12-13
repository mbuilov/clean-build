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
$(call CLEAN_BUILD_APPEND_PROTECTED_VARS,JAVA JAVAC JARC PATHSEP)
