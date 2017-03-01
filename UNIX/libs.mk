#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

ifndef GET_ALL_LIBS

# get all built variants of static and dynamic libraries in form <lib>?<variant>
# $1 - built static libraries
# $2 - variants of built static libraries
# $3 - built dynamic libraries
# $4 - variants of built dynamic libraries
GET_ALL_LIBS = $(sort $(join \
  $(patsubst $(LIB_PREFIX)%$(LIB_SUFFIX),%?,$(notdir $1)),$2) $(join \
  $(patsubst $(DLL_PREFIX)%$(DLL_SUFFIX),%?,$(notdir $3)),$4))

# print $1 to file $2, then change its access mode to $3
define ECHO_INSTALL
$(ECHO) > $2
$(call CHMOD,$3,$2)
endef

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,GET_ALL_LIBS ECHO_INSTALL)

endif
