#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# installation utility macros

# included by $(cb_dir)/install/impl/_install_lib.mk

# source definitions of standard installation directories, such as DESTDIR, PREFIX, BINDIR, LIBDIR, INCLUDEDIR, etc.
include $(dir $(lastword $(MAKEFILE_LIST)))inst_dirs.mk

# create a directory (with intermediate parent directories) while installing things
# $1 - path to the directory to create, path may contain spaces, such as: "C:/Program Files/AcmeCorp"
# note: pass non-empty 3-d argument to 'suppress' function to not colorize tool arguments
# note: 'install_dir' - defined in $(utils_mk) makefile (such as $(cb_dir)/utils/unix.mk)
do_install_dirq = $(call suppress,MKDIR,$(ospath),1)$(install_dir)
do_install_dir  = $(call do_install_dirq,$(ifaddq))

# install file(s) (long list) to a directory or copy file to a file
# $1 - file(s) to install (to support long list, paths _must_ be without spaces)
# $2 - destination directory or file, path may contain spaces
# $3 - optional access mode, such as 644 (rw--r--r-) or 755 (rwxr-xr-x)
# note: pass non-empty 3-d argument to 'suppress' function to not colorize tool arguments
# note: 'install_files' - defined in $(utils_mk) makefile (such as $(cb_dir)/utils/unix.mk)
do_install_filesq = $(call suppress,CP,$(ospath) -> $(call ospath,$2),1)$(install_files)
do_install_files  = $(call do_install_filesq,$1,$(call ifaddq,$2))

# create symbolic link $2 -> $1 while installing things
# $1 - target, such as '../package 2/trg', path may contain spaces
# $2 - simlink, such as '/opt/package 1/link', path may contain spaces
# NOTE: for UNIX only
# note: pass non-empty 3-d argument to 'suppress' function to not colorize tool arguments
# note: 'create_simlink' - defined in $(utils_mk) makefile (such as $(cb_dir)/utils/unix.mk)
do_install_simlinkqq = $(call suppress,LN,$2 -> $1,1)$(create_simlink)
do_install_simlink   = $(call do_install_simlinkqq,$(ifaddq),$(call ifaddq,$2))

# delete file or simlink while uninstalling things
# $1 - file/simlink to delete, path may contain spaces, such as: "C:/Program Files/AcmeCorp/file 1.txt"
# note: pass non-empty 3-d argument to 'suppress' function to not colorize tool arguments
# note: 'delete_files' - defined in $(utils_mk) makefile (such as $(cb_dir)/utils/unix.mk)
do_uninstall_fileq = $(call suppress,RM,$(ospath),1)$(delete_files)
do_uninstall_file  = $(call do_uninstall_fileq,$(ifaddq))

# delete files in a directory while uninstalling things
# $1 - path to the directory where to delete files, path may contain spaces, such as: "C:/Program Files/AcmeCorp"
# $2 - $1-relative paths to the files to delete (long list), to support long list, paths _must_ be without spaces
# note: pass non-empty 3-d argument to 'suppress' function to not colorize tool arguments
# note: 'delete_files_in' - defined in $(utils_mk) makefile (such as $(cb_dir)/utils/unix.mk)
do_uninstall_files_inq = $(call suppress,RM,$(ospath) -> $(call ospath,$2),1)$(delete_files_in)
do_uninstall_files_in  = $(call do_uninstall_files_inq,$(ifaddq),$2)

# recursively delete a directory (with files in it) while uninstalling things
# $1 - directory to delete, path may contain spaces, such as: "C:/Program Files/AcmeCorp"
# note: pass non-empty 3-d argument to 'suppress' function to not colorize tool arguments
# note: 'delete_dirs' - defined in $(utils_mk) makefile (such as $(cb_dir)/utils/unix.mk)
do_uninstall_dirq = $(call suppress,RMDIR,$(ospath),1)$(delete_dirs)
do_uninstall_dir  = $(call do_uninstall_dirq,$(ifaddq))

# try to non-recursively delete a directory if it is empty while uninstalling things
# $1 - directory to delete, path may contain spaces, such as: "C:/Program Files/AcmeCorp"
# note: pass non-empty 3-d argument to 'suppress' function to not colorize tool arguments
# note: 'try_delete_dirs' - defined in $(utils_mk) makefile (such as $(cb_dir)/utils/unix.mk)
do_try_uninstall_dirq = $(call suppress,RMDIR,$(ospath),1)$(try_delete_dirs)
do_try_uninstall_dir  = $(call do_try_uninstall_dirq,$(ifaddq))

# global list of directories to install
cb_needed_install_dirs:=

# PHONY target: 'install_dirs' - depends on installed directories,
#   may be used to adjust installed directories after they are created - set access rights, etc.,
# for example:
#  install: set_my_perms_on_dirs
#  .PHONY: set_my_perms_on_dirs
#  set_my_perms_on_dirs: install_dirs
#      chmod o-rw $(some_dirs)
install_dirs:

# register more goals supported by the build system
build_system_goals += install_dirs

# define the rule for creating installation directories,
#  add those directories to global list 'cb_needed_install_dirs'
# $1 - result of $(call split_dirs,$1) on directories processed by $(call unspaces,...)
# $2 - list of directories to create: $(subst $(space),\ ,$(tospaces))
define add_install_dirs_templ
$(subst :|,:| ,$(subst $(space),\ ,$(call tospaces,$(subst $(space),,$(mk_dir_deps)))))
$2:
	$$(call do_install_dir,$$(subst \ , ,$$@))
install_dirs: $2
cb_needed_install_dirs += $1
endef

# remember new value of 'cb_needed_install_dirs'
# note: do not trace calls to 'cb_needed_install_dirs' because its value is incremented
ifdef cb_checking
$(call define_append,add_install_dirs_templ,$(newline)$$(call set_global1,cb_needed_install_dirs))
endif

# register a rule for creating a directory while installing things
# $1 - directory to install, absolute (unix) path, may contain spaces: C:/Program Files/AcmeCorp
need_install_dir1 = $(if $1,$(eval $(call add_install_dirs_templ,$1,$(subst $(space),\ ,$(tospaces)))))
need_install_dir = $(call need_install_dir1,$(filter-out $(cb_needed_install_dirs),$(subst %,$$(percent),$(call split_dirs,$(unspaces)))))

# same as 'need_install_dir', but return needed directory with spaces prefixed by slash: C:/Program\ Files/AcmeCorp
need_install_dir_ret = $(need_install_dir)$(subst $(space),\ ,$1)

# makefile parsing first phase variables
cb_first_phase_vars += cb_needed_install_dirs add_install_dirs_templ need_install_dir1 need_install_dir need_install_dir_ret

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,cb_needed_install_dirs build_system_goals cb_first_phase_vars)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: inst_utils
$(call set_global,do_install_dirq do_install_dir do_install_filesq do_install_files do_install_simlinkqq do_install_simlink \
  do_uninstall_fileq do_uninstall_file do_uninstall_files_inq do_uninstall_files_in do_uninstall_dirq do_uninstall_dir \
  do_try_uninstall_dirq do_try_uninstall_dir add_install_dirs_templ need_install_dir1 need_install_dir need_install_dir_ret,inst_utils)
