#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# installation utilities

# included by $(CLEAN_BUILD_DIR)/install/impl/_install_lib.mk

ifeq (,$(filter-out undefined environment,$(origin D_PKG_CONFIG_DIR)))
include $(dir $(lastword $(MAKEFILE_LIST)))inst_vars.mk
endif

ifneq (WINDOWS,$(INSTALL_OS))
INSTALL  := $(if $(filter SOLARIS,$(INSTALL_OS)),/usr/ucb/install,install)
LDCONFIG := $(if $(filter LINUX,$(INSTALL_OS)),/sbin/ldconfig)
endif

# create directory while installing things
# $1 - $(call ifaddq,$(subst \ , ,$@)), such as: "C:/Program Files/AcmeCorp"
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
INSTALL_MKDIR = $(call SUP,MKDIR,$(ospath),,1)$(MKDIR)

# global list of directories to install
NEEDED_INSTALL_DIRS:=

# PHONY target: install_dirs - depends on installed directories,
# may be used to adjust installed directories after they are created - set access rights, etc.,
# for example:
#  install: set_perms_on_dirs
#  .PHONY: set_perms_on_dirs
#  set_perms_on_dirs: install_dirs
#      chmod o-rw $(SOME_DIRS)
install_dirs:
.PHONY: install_dirs

# define rule for creating installation directories,
#  add those directories to global list NEEDED_INSTALL_DIRS
# $1 - result of $(call split_dirs,$1) on directories to install (spaces are replaced with ?)
define ADD_INSTALL_DIRS_TEMPL
ifneq (,$1)
$(subst ?,\ ,$(call mk_dir_deps,$1))
$(subst ?,\ ,$1):
	$$(call INSTALL_MKDIR,$$(call ifaddq,$$(subst \ , ,$$@)))
install_dirs: $(subst ?,\ ,$1)
NEEDED_INSTALL_DIRS += $1
endif
endef

# remember new value of NEEDED_INSTALL_DIRS
# note: do not trace calls to NEEDED_INSTALL_DIRS because its value is incremented
# note: assume result of $(call SET_GLOBAL1,...,0) will give an empty line at end of expansion
ifdef MCHECK
$(eval define ADD_INSTALL_DIRS_TEMPL$(newline)$(subst endif,$$(call \
  SET_GLOBAL1,NEEDED_INSTALL_DIRS,0)endif,$(value ADD_INSTALL_DIRS_TEMPL))$(newline)endef)
endif

# add rule for creating directory while installing things
# $1 - directory to install, absolute unix path, spaces are prefixed with backslash, such as: C:/Program\ Files/AcmeCorp
NEED_INSTALL_DIR = $(eval $(call ADD_INSTALL_DIRS_TEMPL,$(filter-out $(NEEDED_INSTALL_DIRS),$(call split_dirs,$(subst \ ,?,$1)))))

# same as NEED_INSTALL_DIR, but return needed directory
NEED_INSTALL_DIR_RET = $(NEED_INSTALL_DIR)$1

# delete one file or simlink while uninstalling things
# $1 - file to delete, such as: "C:/Program Files/AcmeCorp/file 1.txt", path may contain spaces
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
UNINSTALL_DEL1 = $(call SUP,DEL,$(ospath),1,1)$(DEL)
UNINSTALL_DEL = $(call UNINSTALL_DEL1,$(ifaddq))

# recursively delete one directory while uninstalling things
# $1 - directory to delete, such as: "C:/Program Files/AcmeCorp", path may contain spaces
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
UNINSTALL_DEL_DIR1 = $(call SUP,DEL_DIR,$(ospath),1,1)$(DEL_DIR)
UNINSTALL_DEL_DIR = $(call UNINSTALL_DEL_DIR1,$(ifaddq))

ifneq (WINDOWS,$(INSTALL_OS))
# create symbolic link while installing things
# $1 - target, such as '../package 2/trg', path may contain spaces
# $2 - simlink, such as '/opt/package 1/link', path may contain spaces
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
INSTALL_LN1 = $(call SUP,LN,$2 -> $1,1,1)$(LN)
INSTALL_LN = $(call INSTALL_LN1,$(ifaddq),$(call ifaddq,$2))
endif

# copy file(s) to directory or file to file while installing things
# $1 - file(s) to copy, without spaces in path
# $2 - destination directory or file, path may contain spaces
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
INSTALL_CP1 = $(call SUP,COPY,$(ospath) -> $(call ospath,$2),1,1)$(CP)
INSTALL_CP = $(call INSTALL_CP1,$1,$(call ifaddq,$2))

# protect variables from modifications in target makefiles
# note: do not trace calls to NEEDED_INSTALL_DIRS because its value is incremented
$(call SET_GLOBAL1,NEEDED_INSTALL_DIRS,0)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,INSTALL LDCONFIG INSTALL_MKDIR ADD_INSTALL_DIRS_TEMPL NEED_INSTALL_DIR NEED_INSTALL_DIR_RET \
  UNINSTALL_DEL1 UNINSTALL_DEL UNINSTALL_DEL_DIR1 UNINSTALL_DEL_DIR INSTALL_LN1 INSTALL_LN INSTALL_CP1 INSTALL_CP)
