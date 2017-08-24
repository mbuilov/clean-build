#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# installation utilities

# included by $(CLEAN_BUILD_DIR)/install/impl/_install_lib.mk

ifeq (,$(filter-out undefined environment,$(origin D_PKG_CONFIG_DIR)))
include $(dir $(lastword $(MAKEFILE_LIST)))inst_dirs.mk
endif

# type of utilities to use for installation: cmd, unix, gnu, etc...
INSTALL_UTILS_TYPE := $(basename $(notdir $(UTILS)))

ifneq (cmd,$(INSTALL_UTILS_TYPE))
INSTALL  := $(if $(filter SOLARIS,$(OS)),/usr/ucb/install,install)
LDCONFIG := $(if $(filter LINUX,$(OS)),/sbin/ldconfig)
endif

# create directory (with intermediate parent directories) while installing things
# $1 - path to directory to create, such as: "C:/Program Files/AcmeCorp", path may contain spaces
ifneq (cmd,$(INSTALL_UTILS_TYPE))
INSTALL_DIR_COMMAND = $(INSTALL) -d $1
else
INSTALL_DIR_COMMAND = $(MKDIR)
endif

# install (copy) file(s) to directory
# $1 - file(s) to install, without spaces in path
# $2 - destination directory, path may contain spaces
# $3 - optional access mode, such as 644 (rw--r--r-) or 755 (rwxr-xr-x)
ifneq (cmd,$(INSTALL_UTILS_TYPE))
INSTALL_FILES_COMMAND = $(INSTALL) $(addprefix -m ,$3) $1 $2
else
INSTALL_FILES_COMMAND = $(CP)
endif

# create directory (with intermediate parent directories) while installing things
# $1 - path to directory to create, such as: "C:/Program Files/AcmeCorp", path may contain spaces
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
INSTALL_MKDIRq = $(call SUP,MKDIR,$(ospath),1,1)$(INSTALL_DIR_COMMAND)
INSTALL_MKDIR = $(call INSTALL_MKDIRq,$(ifaddq))

# install (copy) file(s) to directory or file to file while installing things
# $1 - file(s) to install, without spaces in path
# $2 - destination directory or file, path may contain spaces
# $3 - optional access mode, such as 644 (rw--r--r-) or 755 (rwxr-xr-x)
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
INSTALL_FILESq = $(call SUP,COPY,$(ospath) -> $(call ospath,$2),1,1)$(INSTALL_FILES_COMMAND)
INSTALL_FILES = $(call INSTALL_FILESq,$1,$(call ifaddq,$2))

ifneq (WINDOWS,$(OS))
# create symbolic link while installing things
# $1 - target, such as '../package 2/trg', path may contain spaces
# $2 - simlink, such as '/opt/package 1/link', path may contain spaces
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
INSTALL_LNqq = $(call SUP,LN,$2 -> $1,1,1)$(LN)
INSTALL_LN = $(call INSTALL_LNqq,$(ifaddq),$(call ifaddq,$2))
endif

# delete one file or simlink while uninstalling things
# $1 - file to delete, such as: "C:/Program Files/AcmeCorp/file 1.txt", path may contain spaces
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
UNINSTALL_DELq = $(call SUP,DEL,$(ospath),1,1)$(DEL)
UNINSTALL_DEL = $(call UNINSTALL_DELq,$(ifaddq))

# delete files in directory while uninstalling things
# $1 - path to directory where to delete files, such as: "C:/Program Files/AcmeCorp", path may contain spaces
# $2 - files to delete, without spaces in path
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
UNINSTALL_DELINq = $(call SUP,DELIN,$(ospath): $(call ospath,$2),1,1)$(DELIN)
UNINSTALL_DELIN = $(call UNINSTALL_DELINq,$(ifaddq),$2)

# recursively delete one directory while uninstalling things
# $1 - directory to delete, such as: "C:/Program Files/AcmeCorp", path may contain spaces
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
UNINSTALL_RMDIRq = $(call SUP,RMDIR,$(ospath),1,1)$(RMDIR)
UNINSTALL_RMDIR = $(call UNINSTALL_RMDIRq,$(ifaddq))

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
	$$(call INSTALL_MKDIR,$$(subst \ , ,$$@))
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

# protect variables from modifications in target makefiles
# note: do not trace calls to NEEDED_INSTALL_DIRS because its value is incremented
$(call SET_GLOBAL1,NEEDED_INSTALL_DIRS,0)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,INSTALL LDCONFIG INSTALL_DIR_COMMAND INSTALL_FILES_COMMAND INSTALL_MKDIRq INSTALL_MKDIR \
  INSTALL_FILESq INSTALL_FILES INSTALL_LNqq INSTALL_LN UNINSTALL_DELq UNINSTALL_DEL UNINSTALL_DELINq UNINSTALL_DELIN \
  UNINSTALL_RMDIRq UNINSTALL_RMDIR ADD_INSTALL_DIRS_TEMPL NEED_INSTALL_DIR NEED_INSTALL_DIR_RET)
