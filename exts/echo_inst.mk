#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

ifndef ECHO_INSTALL

# print $1 to file $2, then change its access mode to $3
define ECHO_INSTALL
$(ECHO) > $2
$(call CHMOD,$3,$2)
endef

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,ECHO_INSTALL)

endif
