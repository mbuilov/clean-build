#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# write lines of text $1 to the file $2 by $3 lines at one time, then set access mode of written file $2 to $4
# note: pass non-empty 3-d argument to 'suppress' function to not colorize tool arguments
# note: 'write_text' - defined in $(utils_mk) makefile (such as $(cb_dir)/utils/unix.mk)
install_text = $(call suppress,GEN,$2,1)$(write_text)

# set access mode of the file $2 to $4
# note: 'change_mode' defined in $(cb_dir)/utils/unix.mk, if it was included by $(cb_dir)/core/_defs.mk
ifdef change_mode
$(call define_append,install_text,$(newline)$$(call suppress,CHMOD,$$2,1)$$(call change_mode,$$4,$$2))
endif

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: inst_text
$(call set_global,install_text,inst_text)
