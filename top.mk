# this file included by $(MTOP)/defs.mk
# check values of $(TOP) and $(XTOP) variables

# $1 (TOP or XTOP) must contain unix-style path to directory without spaces like C:/opt/project or /home/oper/project
define CHECK_TOP1
ifneq ($(words x$($1)x),1)
$$(error $1=$($1), path with spaces is not allowed)
endif
ifneq ($(words $(subst \, ,x$($1)x)),1)
$$(error $1=$($1), path must use unix-style slashes: /)
endif
ifneq ($(subst //,,$($1)/),$($1)/)
$$(error $1=$($1), path must not end with slash: / or contain double-slash: //)
endif
endef
CHECK_TOP = $(eval $(CHECK_TOP1))

ifndef TOP
$(error TOP undefined, example: C:/opt/project,/home/oper/project)
endif

# make TOP nonrecursive (simple)
TOP := $(TOP)
$(call CHECK_TOP,TOP)

# directory for built files - base for $(BIN_DIR), $(LIB_DIR), $(OBJ_DIR), $(GEN_DIR)
# note: make XTOP nonrecursive (simple)
ifndef XTOP
XTOP := $(TOP)
else
XTOP := $(XTOP)
$(call CHECK_TOP,XTOP)
endif

# protect variables from modification in target makefiles
CLEAN_BUILD_PROTECTED_VARS := CLEAN_BUILD_PROTECTED_VARS CHECK_TOP1 CHECK_TOP TOP XTOP
