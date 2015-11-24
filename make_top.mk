# check values of $(TOP) and $(XTOP) variables

# must be unix-style path to directory without spaces like C:/opt/project or /home/oper/project
define CHECK_TOP1
ifneq ($(words x$($1)x),1)
$$(error $1=$($1), path with spaces is not allowed)
endif
ifneq ($(words $(subst \, ,x$($1)x)),1)
$$(error $1=$($1), path must use unix-style slashes: /)
endif
ifneq ($(subst //,,$($1)/),$($1)/)
$$(error $1=$($1), path must not end with slash: /)
endif
endef
CHECK_TOP = $(eval $(CHECK_TOP1))

ifndef TOP
$(error TOP undefined, example: C:/opt/project,/home/oper/project)
endif
$(call CHECK_TOP,TOP)

ifdef XTOP
$(call CHECK_TOP,XTOP)
endif
