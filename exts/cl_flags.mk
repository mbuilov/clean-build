# pedantic flags for cl

CL9_PEDANTIC_CFLAGS := /Wall
CL9_PEDANTIC_CFLAGS += /wd4251# 'class' needs to have dll-interface to be used by clients of class...
CL9_PEDANTIC_CFLAGS += /wd4275# non dll-interface class 'class' used as base for dll-interface class 'class'
CL9_PEDANTIC_CFLAGS += /wd4996# 'strdup': The POSIX name for this item is deprecated...
CL9_PEDANTIC_CFLAGS += /wd4001# nonstandard extension 'single line comment' was used
CL9_PEDANTIC_CFLAGS += /wd4820# 'x' bytes padding added after data member ...
CL9_PEDANTIC_CFLAGS += /wd4710# 'void fn()': function not inlined
CL9_PEDANTIC_CFLAGS += /wd4711# function 'fn' selected for automatic inline expansion
CL9_PEDANTIC_CFLAGS += /wd4514# 'fn': unreferenced inline function has been removed
CL9_PEDANTIC_CFLAGS += /wd4571# Informational: catch(...) semantics changed since Visual C++ 7.1; structured exceptions (SEH) are no longer caught
