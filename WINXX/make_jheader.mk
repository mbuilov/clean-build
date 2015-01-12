ifeq ($(JAVA),)
JAVA := java.exe
endif

ifeq ($(JAVAC),)
JAVAC := javac.exe
endif

ifeq ($(JARC),)
JARC := jar.exe
endif

PATHSEP := ;
