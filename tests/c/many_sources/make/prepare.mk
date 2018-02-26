#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# original file: $(CBLD_ROOT)/stub/prepare.mk
# description:   prepare for project configuration

# Note: This file should be copied AS IS to the directory of the project build system
# Note: This file should be included at head of the project configuration makefile ('project.mk')

# save values of environment variables - to check that no variables were accidentally overwritten
#  due to collisions of the variable names
# Note: save environment variables _before_ defining any makefile variable
$(foreach =,$(filter-out MAKELEVEL GNUMAKEFLAGS MFLAGS MAKEOVERRIDES,$(.VARIABLES)),$(if \
  $(findstring environment,$(origin $=)),$(eval $$=.^e:=$$(value $$=))))

# version of the clean-build build system required by the project
clean_build_required_version := 0.9.1
