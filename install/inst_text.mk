#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# write lines of text $1 to file $2 by $3 lines at one time,
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
define INSTALL_TEXT
$(call SUP,GEN,$2,1,1)$(WRITE_TEXT)
endef

# then set access mode of written file $2 to $4
ifneq (cmd,$(UTILS))
$(call define_append,INSTALL_TEXT,$$(call SUP,CHMOD,$$2,1,1)$$(call CHANGE_MODE,$$4,$$2))
endif

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,INSTALL_TEXT)
