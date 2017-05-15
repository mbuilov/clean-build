#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

ifndef ECHO_INSTALL

# CHMOD tool color
CHMOD_COLOR := [01;35m

# print $1 to file $2, then change its access mode to $3
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
define ECHO_INSTALL
$(call SUP,GEN,$2,1,1)$(ECHO) > $2
$(call SUP,CHMOD,$2,1,1)$(call CHMOD,$3,$2)
endef

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,CHMOD_COLOR ECHO_INSTALL)

endif
