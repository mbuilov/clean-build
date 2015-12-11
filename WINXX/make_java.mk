OSTYPE := WINDOWS

ifndef JAVA
JAVA := java.exe
endif

ifndef JAVAC
JAVAC := javac.exe
endif

ifndef JARC
JARC := jar.exe
endif

PATHSEP := ;

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_APPEND_PROTECTED_VARS,JAVA JAVAC JARC PATHSEP)
