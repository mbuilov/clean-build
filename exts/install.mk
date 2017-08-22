#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define variables used in installation rules

# defaults, may be overridden either in command line or in project configuration makefile
# note: assume installation paths _may_ contain spaces

# root of program installation directory
PREFIX := /usr/local

# directory for executables
EXEC_PREFIX := $(PREFIX)

# directory for non-superuser executables
BINDIR := $(EXEC_PREFIX)/bin

# directory for superuser executables
SBINDIR := $(EXEC_PREFIX)/sbin

# directory for support executables not run by user
LIBEXECDIR := $(EXEC_PREFIX)/libexec

# root of data directories
DATAROOTDIR := $(PREFIX)/share

# directory for read-only program data (package should install files to $(DATADIR)/package-name/)
DATADIR := $(DATAROOTDIR)

# directory for text configurations
SYSCONFDIR := $(PREFIX)/etc

# shared directory for program state files (modified while program is run)
SHAREDSTATEDIR := $(PREFIX)/com

# machine-local directory for program state files (modified while program is run)
LOCALSTATEDIR := $(PREFIX)/var

# directory for program state files persisting no more than program lifetime (such as PIDs)
RUNSTATEDIR := $(LOCALSTATEDIR)/run

# directory for header files
INCLUDEDIR := $(PREFIX)/include

# name of the package
PACKAGE_NAME = $(error PACKAGE_NAME is not defined - define it in project configuration makefile)

# directory for documentation files
DOCDIR = $(DATAROOTDIR)/doc/$(PACKAGE_NAME)

# directory for documentation files in the particular format
HTMLDIR = $(DOCDIR)
DVIDIR  = $(DOCDIR)
PDFDIR  = $(DOCDIR)
PSDIR   = $(DOCDIR)

# directory where to install libraries
LIBDIR := $(EXEC_PREFIX)/lib

# directory for locale-specific message catalogs
LOCALEDIR := $(DATAROOTDIR)/locale

# directory for info files
INFODIR := $(DATAROOTDIR)/info

# top-level directory for installing the man pages
MANDIR := $(DATAROOTDIR)/man

# directories for manual pages
MAN1DIR := $(MANDIR)/man1
MAN2DIR := $(MANDIR)/man2
MAN3DIR := $(MANDIR)/man3
MAN4DIR := $(MANDIR)/man4
MAN5DIR := $(MANDIR)/man5
MAN6DIR := $(MANDIR)/man6
MAN7DIR := $(MANDIR)/man7
MAN8DIR := $(MANDIR)/man8

# directory where to install pkg-config files
PKG_CONFIG_DIR := $(LIBDIR)/pkgconfig

# type of the operating system on which installation is performed
INSTALL_OS := $(OS)

# installation tools
ifneq (WINDOWS,$(INSTALL_OS))
INSTALL  := $(if $(filter SOLARIS,$(OS)),/usr/ucb/install,install)
LDCONFIG := $(if $(filter LINUX,$(OS)),/sbin/ldconfig)
endif

# create directory while installing things
# $1 - "$(subst \ , ,$@)", such as: "C:/Program Files/AcmeCorp"
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
	$$(call INSTALL_MKDIR,'$$(subst \ , ,$$@)')
NEEDED_INSTALL_DIRS += $1
endif
endef

ifeq (WINDOWS,$(INSTALL_OS))
$(eval define ADD_INSTALL_DIRS_TEMPL$(newline)$(subst ',",$(value ADD_INSTALL_DIRS_TEMPL))$(newline)endef)
endif

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
