#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# installation utility macros

# included by $(CLEAN_BUILD_DIR)/install/impl/_install_lib.mk

# source definitions of standard installation directories, such as DESTDIR, PREFIX, BINDIR, LIBDIR, INCLUDEDIR, etc.
include $(dir $(lastword $(MAKEFILE_LIST)))inst_dirs.mk

# create directory (with intermediate parent directories) while installing things
# $1 - path to directory to create, path may contain spaces, such as: "C:/Program Files/AcmeCorp"
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
DO_INSTALL_DIRq = $(call SUP,MKDIR,$(ospath),1,1)$(INSTALL_DIR)
DO_INSTALL_DIR  = $(call DO_INSTALL_DIRq,$(ifaddq))

# install file(s) (long list) to directory or copy file to file
# $1 - file(s) to install (to support long list, paths _must_ be without spaces)
# $2 - destination directory or file, path may contain spaces
# $3 - optional access mode, such as 644 (rw--r--r-) or 755 (rwxr-xr-x)
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
DO_INSTALL_FILESq = $(call SUP,CP,$(ospath) -> $(call ospath,$2),1,1)$(INSTALL_FILES)
DO_INSTALL_FILES  = $(call DO_INSTALL_FILESq,$1,$(call ifaddq,$2))

# create symbolic link $2 -> $1 while installing things
# $1 - target, such as '../package 2/trg', path may contain spaces
# $2 - simlink, such as '/opt/package 1/link', path may contain spaces
# NOTE: for UNIX only
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
DO_INSTALL_SIMLINKqq = $(call SUP,LN,$2 -> $1,1,1)$(CREATE_SIMLINK)
DO_INSTALL_SIMLINK   = $(call DO_INSTALL_SIMLINKqq,$(ifaddq),$(call ifaddq,$2))

# delete file or simlink while uninstalling things
# $1 - file/simlink to delete, path may contain spaces, such as: "C:/Program Files/AcmeCorp/file 1.txt"
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
DO_UNINSTALL_FILEq = $(call SUP,RM,$(ospath),1,1)$(DELETE_FILES)
DO_UNINSTALL_FILE  = $(call DO_UNINSTALL_FILEq,$(ifaddq))

# delete files in directory while uninstalling things
# $1 - path to directory where to delete files, path may contain spaces, such as: "C:/Program Files/AcmeCorp"
# $2 - $1-relative paths to files to delete (long list), to support long list, paths _must_ be without spaces
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
DO_UNINSTALL_FILES_INq = $(call SUP,RM,$(ospath) -> $(call ospath,$2),1,1)$(DELETE_FILES_IN)
DO_UNINSTALL_FILES_IN  = $(call DO_UNINSTALL_FILES_INq,$(ifaddq),$2)

# recursively delete directory (with files in it) while uninstalling things
# $1 - directory to delete, path may contain spaces, such as: "C:/Program Files/AcmeCorp"
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
DO_UNINSTALL_DIRq = $(call SUP,RMDIR,$(ospath),1,1)$(DELETE_DIRS)
DO_UNINSTALL_DIR  = $(call DO_UNINSTALL_DIRq,$(ifaddq))

# try to non-recursively delete directory if it is empty while uninstalling things
# $1 - directory to delete, path may contain spaces, such as: "C:/Program Files/AcmeCorp"
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
DO_UNINSTALL_DIR_IF_EMPTYq = $(call SUP,RMDIR,$(ospath),1,1)$(DELETE_DIRS_IF_EMPTY)
DO_UNINSTALL_DIR_IF_EMPTY  = $(call DO_UNINSTALL_DIR_IF_EMPTYq,$(ifaddq))

# global list of directories to install
NEEDED_INSTALL_DIRS:=

# PHONY target: install_dirs - depends on installed directories,
# may be used to adjust installed directories after they are created - set access rights, etc.,
# for example:
#  install: my_perms_on_dirs
#  .PHONY: my_perms_on_dirs
#  my_perms_on_dirs: install_dirs
#      chmod o-rw $(SOME_DIRS)
install_dirs:
.PHONY: install_dirs

# define rule for creating installation directories,
#  add those directories to global list NEEDED_INSTALL_DIRS
# $1 - result of $(call split_dirs,$1) on directories processed by $(call unspaces,...)
# $2 - list of directories to create: $(subst $(space),\ ,$(tospaces))
define ADD_INSTALL_DIRS_TEMPL
$(subst :|,:| ,$(subst $(space),\ ,$(call tospaces,$(subst $(space),,$(mk_dir_deps)))))
$2:
	$$(call INSTALL_MKDIR,$$(subst \ , ,$$@))
install_dirs: $2
NEEDED_INSTALL_DIRS += $1
endef

# remember new value of NEEDED_INSTALL_DIRS
# note: do not trace calls to NEEDED_INSTALL_DIRS because its value is incremented
ifdef MCHECK
$(call define_append,ADD_INSTALL_DIRS_TEMPL1,$(newline)$$(call SET_GLOBAL1,NEEDED_INSTALL_DIRS,0))
endif

# add rule for creating directory while installing things
# $1 - directory to install, absolute unix path, may contain spaces: C:/Program Files/AcmeCorp
# note: assume directory path does not contain % symbols
NEED_INSTALL_DIR1 = $(if $1,$(eval $(call ADD_INSTALL_DIRS_TEMPL,$1,$(subst $(space),\ ,$(tospaces)))))
NEED_INSTALL_DIR  = $(call NEED_INSTALL_DIR1,$(filter-out $(NEEDED_INSTALL_DIRS),$(call split_dirs,$(unspaces))))

# same as NEED_INSTALL_DIR, but return needed directory with spaces prefixed with slash: C:/Program\ Files/AcmeCorp
NEED_INSTALL_DIR_RET = $(NEED_INSTALL_DIR)$(subst $(space),\ ,$1)

# protect variables from modifications in target makefiles
# note: do not trace calls to NEEDED_INSTALL_DIRS because its value is incremented
$(call SET_GLOBAL1,NEEDED_INSTALL_DIRS,0)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,DO_INSTALL_DIRq DO_INSTALL_DIR DO_INSTALL_FILESq DO_INSTALL_FILES DO_INSTALL_SIMLINKqq DO_INSTALL_SIMLINK \
  DO_UNINSTALL_FILEq DO_UNINSTALL_FILE DO_UNINSTALL_FILES_INq DO_UNINSTALL_FILES_IN DO_UNINSTALL_DIRq DO_UNINSTALL_DIR \
  DO_UNINSTALL_DIR_IF_EMPTYq DO_UNINSTALL_DIR_IF_EMPTY ADD_INSTALL_DIRS_TEMPL NEED_INSTALL_DIR NEED_INSTALL_DIR_RET)
