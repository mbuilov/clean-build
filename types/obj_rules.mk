#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# support for compiling objects from sources: one source -> one object

# add source-dependencies for object files
# $1 - source dependencies list, e.g. dir1/src1/| dir2/dep1| dep2 dir3/src2/| dep3
# $2 - objdir
# $3 - $(OBJ_SUFFIX)
ADD_OBJ_SDEPS = $(subst |, ,$(subst $(space),$(newline),$(join \
  $(patsubst %,$2/%$3:,$(basename $(notdir $(filter %/|,$1)))),$(subst | ,|,$(filter-out %/|,$1)))))

# call compiler: OBJ_CXX,OBJ_CC,OBJ_ASM,...
# $1 - sources type: CXX,CC,ASM,...
# $2 - sources to compile
# $3 - sdeps (result of FIX_SDEPS)
# $4 - objdir
# $5 - $(OBJ_SUFFIX)
# $6 - objects: $(patsubst %,$4/%$5,$(basename $(notdir $2)))
# $t - target type: EXE,LIB,...
# $v - non-empty variant: R,P,D,S... (one of variants supported by selected toolchain)
# returns: list of object files
# note: postpone expansion of ORDER_DEPS to optimize parsing
define OBJ_RULES_BODY
$6
$(subst $(space),$(newline),$(join $(addsuffix :,$6),$2))
$(call ADD_OBJ_SDEPS,$(subst |,| ,$(call FILTER_SDEPS,$2,$3,$5)),$4)
$6:| $4 $$(ORDER_DEPS)
	$$(call OBJ_$1,$$@,$$<,$t,$v)
endef
ifndef NO_DEPS
$(call define_append,OBJ_RULES_BODY,$(newline)-include $$(patsubst %$$5,%.d,$$6))
endif

# rule that defines how to build objects from sources
# $1 - sources type: CXX,CC,ASM,...
# $2 - sources to compile
# $3 - sdeps (result of FIX_SDEPS)
# $4 - objdir
# $5 - $(OBJ_SUFFIX)
# $t - target type: EXE,LIB,...
# $v - non-empty variant: R,P,D,S... (one of variants supported by selected toolchain)
# returns: list of object files
ifndef TOCLEAN
OBJ_RULES = $(if $2,$(call OBJ_RULES_BODY,$1,$2,$3,$4,$5,$(patsubst %,$4/%$5,$(basename $(notdir $2)))))
else
# note: also cleanup auto-generated dependencies
OBJ_RULES1 = $(call TOCLEAN,$1 $(patsubst %$2,%,.d,$1))
OBJ_RULES = $(if $2,$(call OBJ_RULES1,$(patsubst %,$4/%$5,$(basename $(notdir $2)),$5)))
endif

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,ADD_OBJ_SDEPS OBJ_RULES_BODY=t;v OBJ_RULES1=t;v OBJ_RULES=t;v)
