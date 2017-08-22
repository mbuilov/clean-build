#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define variables used in installation rules

# included by $(CLEAN_BUILD_DIR)/exts/_install_lib.mk

# type of the operating system on which installation is performed
INSTALL_OS := $(OS)

# non-empty if do not install development files and headers
# by default, install development files
# note: normally overridden in command line
NO_DEVEL:=

# prefix for installed directories
# note: normally overridden by specifying DESTDIR in command line
DESTDIR:=

# defaults, may be overridden either in command line or in project configuration makefile
# note: assume installation paths _may_ contain spaces
# note: use D_... macros to get $(DESTDIR)-prefixed paths

# root of program installation directory
PREFIX := $(if $(filter WINDOWS,$(INSTALL_OS)),artifacts,/usr/local)
D_PREFIX = $(DESTDIR)$(PREFIX)

# directory for executables
EXEC_PREFIX := $(PREFIX)
D_EXEC_PREFIX = $(DESTDIR)$(EXEC_PREFIX)

# directory for non-superuser executables
BINDIR := $(EXEC_PREFIX)/bin
D_BINDIR = $(DESTDIR)$(BINDIR)

# directory for superuser executables
SBINDIR := $(EXEC_PREFIX)/sbin
D_SBINDIR = $(DESTDIR)$(SBINDIR)

# directory for support executables not run by user
LIBEXECDIR := $(EXEC_PREFIX)/libexec
D_LIBEXECDIR = $(DESTDIR)$(LIBEXECDIR)

# root of data directories
DATAROOTDIR := $(PREFIX)/share
D_DATAROOTDIR = $(DESTDIR)$(DATAROOTDIR)

# directory for read-only program data (package should install files to $(DATADIR)/package-name/)
DATADIR := $(DATAROOTDIR)
D_DATADIR = $(DESTDIR)$(DATADIR)

# directory for text configurations
SYSCONFDIR := $(PREFIX)/etc
D_SYSCONFDIR = $(DESTDIR)$(SYSCONFDIR)

# shared directory for program state files (modified while program is run)
SHAREDSTATEDIR := $(PREFIX)/com
D_SHAREDSTATEDIR = $(DESTDIR)$(SHAREDSTATEDIR)

# machine-local directory for program state files (modified while program is run)
LOCALSTATEDIR := $(PREFIX)/var
D_LOCALSTATEDIR = $(DESTDIR)$(LOCALSTATEDIR)

# directory for program state files persisting no more than program lifetime (such as PIDs)
RUNSTATEDIR := $(LOCALSTATEDIR)/run
D_RUNSTATEDIR = $(DESTDIR)$(RUNSTATEDIR)

# directory for header files
INCLUDEDIR := $(PREFIX)/include
D_INCLUDEDIR = $(DESTDIR)$(INCLUDEDIR)

# name of the package
PACKAGE_NAME = $(error PACKAGE_NAME is not defined - define it in project configuration makefile)

# directory for documentation files
DOCDIR = $(DATAROOTDIR)/doc/$(PACKAGE_NAME)
D_DOCDIR = $(DESTDIR)$(DOCDIR)

# directory for documentation files in the particular format
HTMLDIR = $(DOCDIR)
DVIDIR  = $(DOCDIR)
PDFDIR  = $(DOCDIR)
PSDIR   = $(DOCDIR)
D_HTMLDIR = $(DESTDIR)$(HTMLDIR)
D_DVIDIR  = $(DESTDIR)$(DVIDIR)
D_PDFDIR  = $(DESTDIR)$(PDFDIR)
D_PSDIR   = $(DESTDIR)$(PSDIR)

# directory where to install libraries
LIBDIR := $(EXEC_PREFIX)/lib
D_LIBDIR = $(DESTDIR)$(LIBDIR)

# directory for locale-specific message catalogs
LOCALEDIR := $(DATAROOTDIR)/locale
D_LOCALEDIR = $(DESTDIR)$(LOCALEDIR)

# directory for info files
INFODIR := $(DATAROOTDIR)/info
D_INFODIR = $(DESTDIR)$(INFODIR)

# top-level directory for installing the man pages
MANDIR := $(DATAROOTDIR)/man
D_MANDIR = $(DESTDIR)$(MANDIR)

# directories for manual pages
MAN1DIR := $(MANDIR)/man1
MAN2DIR := $(MANDIR)/man2
MAN3DIR := $(MANDIR)/man3
MAN4DIR := $(MANDIR)/man4
MAN5DIR := $(MANDIR)/man5
MAN6DIR := $(MANDIR)/man6
MAN7DIR := $(MANDIR)/man7
MAN8DIR := $(MANDIR)/man8
D_MAN1DIR = $(DESTDIR)$(MAN1DIR)
D_MAN2DIR = $(DESTDIR)$(MAN2DIR)
D_MAN3DIR = $(DESTDIR)$(MAN3DIR)
D_MAN4DIR = $(DESTDIR)$(MAN4DIR)
D_MAN5DIR = $(DESTDIR)$(MAN5DIR)
D_MAN6DIR = $(DESTDIR)$(MAN6DIR)
D_MAN7DIR = $(DESTDIR)$(MAN7DIR)
D_MAN8DIR = $(DESTDIR)$(MAN8DIR)

# directory where to install pkg-config files
PKG_CONFIG_DIR := $(LIBDIR)/pkgconfig
D_PKG_CONFIG_DIR = $(DESTDIR)$(PKG_CONFIG_DIR)

# installation tools
ifneq (WINDOWS,$(INSTALL_OS))
INSTALL  := $(if $(filter SOLARIS,$(OS)),/usr/ucb/install,install)
LDCONFIG := $(if $(filter LINUX,$(OS)),/sbin/ldconfig)
endif

# create directory while installing things
# $1 - $(call ifaddq,$(subst \ , ,$@)), such as: "C:/Program Files/AcmeCorp"
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
INSTALL_MKDIR = $(call SUP,MKDIR,$(ospath),,1)$(MKDIR)

# global list of directories to install
NEEDED_INSTALL_DIRS:=

# define rule for creating installation directories,
#  add those directories to global list NEEDED_INSTALL_DIRS
# $1 - result of $(call split_dirs,$1) on directories to install (spaces are replaced with ?)
define ADD_INSTALL_DIRS_TEMPL
ifneq (,$1)
$(subst ?,\ ,$(call mk_dir_deps,$1))
$(subst ?,\ ,$1):
	$$(call INSTALL_MKDIR,$$(call ifaddq,$$(subst \ , ,$$@)))
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

# add rule for creating installation directories
# $1 - directory to install, spaces in path are prefixed with backslash, such as: C:/Program\ Files/AcmeCorp
ADD_INSTALL_DIR = $(eval $(call ADD_INSTALL_DIRS_TEMPL,$(filter-out $(NEEDED_INSTALL_DIRS),$(call split_dirs,$(subst \ ,?,$1)))))

# protect variables from modifications in target makefiles
# note: do not trace calls to NEEDED_INSTALL_DIRS because its value is incremented
$(call SET_GLOBAL1,NEEDED_INSTALL_DIRS,0)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,INSTALL_OS NO_DEVEL DESTDIR \
  PREFIX D_PREFIX EXEC_PREFIX D_EXEC_PREFIX BINDIR D_BINDIR SBINDIR D_SBINDIR LIBEXECDIR D_LIBEXECDIR \
  DATAROOTDIR D_DATAROOTDIR DATADIR D_DATADIR SYSCONFDIR D_SYSCONFDIR SHAREDSTATEDIR D_SHAREDSTATEDIR \
  LOCALSTATEDIR D_LOCALSTATEDIR RUNSTATEDIR D_RUNSTATEDIR INCLUDEDIR D_INCLUDEDIR PACKAGE_NAME DOCDIR D_DOCDIR \
  HTMLDIR DVIDIR PDFDIR PSDIR D_HTMLDIR D_DVIDIR D_PDFDIR D_PSDIR \
  LIBDIR D_LIBDIR LOCALEDIR D_LOCALEDIR INFODIR D_INFODIR MANDIR D_MANDIR \
  MAN1DIR MAN2DIR MAN3DIR MAN4DIR MAN5DIR MAN6DIR MAN7DIR MAN8DIR \
  D_MAN1DIR D_MAN2DIR D_MAN3DIR D_MAN4DIR D_MAN5DIR D_MAN6DIR D_MAN7DIR D_MAN8DIR \
  PKG_CONFIG_DIR D_PKG_CONFIG_DIR INSTALL LDCONFIG INSTALL_MKDIR ADD_INSTALL_DIRS_TEMPL ADD_INSTALL_DIR)
