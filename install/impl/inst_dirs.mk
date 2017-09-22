#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define variables used in installation templates

# included by $(CLEAN_BUILD_DIR)/install/impl/inst_utils.mk

# non-empty if do not install development files and headers
# by default, install development files
# note: normally overridden in command line
NO_DEVEL:=

# prefix for installed directories
# note: normally overridden by specifying DESTDIR in command line
DESTDIR:=

# INSTALL_OS_TYPE - type of operating system on which to install
# note: $(INSTALL_OS_TYPE) value is used only to form names of standard makefiles with definitions of installation templates
# note: normally INSTALL_OS_TYPE get overridden by specifying it in command line
INSTALL_OS_TYPE := $(if $(filter CYGWIN WIN%,$(OS)),windows,unix)

# defaults, may be overridden either in command line or in project configuration makefile
# note: assume installation paths _may_ contain spaces
# note: use D_... macros to get $(DESTDIR)-prefixed paths

# normalize path: prepend it with $(DESTDIR), convert backslashes to forward ones, remove trailing and excessive slashes
DESTDIR_NORMALIZE = $(patsubst %/,%,$(subst //,/,$(subst \,/,$(DESTDIR)$1)))

# root of program installation directory
# note: assume PREFIX cannot be target-specific
PREFIX := $(if $(filter WIN%,$(OS)),artifacts,/usr/local)
D_PREFIX := $(call DESTDIR_NORMALIZE,$(PREFIX))

# directory for executables
EXEC_PREFIX := $(PREFIX)
D_EXEC_PREFIX := $(call DESTDIR_NORMALIZE,$(EXEC_PREFIX))

# directory for non-superuser executables
BINDIR := $(EXEC_PREFIX)/bin
D_BINDIR := $(call DESTDIR_NORMALIZE,$(BINDIR))

# directory for superuser executables
SBINDIR := $(EXEC_PREFIX)/sbin
D_SBINDIR := $(call DESTDIR_NORMALIZE,$(SBINDIR))

# directory for support executables not run by user
LIBEXECDIR := $(EXEC_PREFIX)/libexec
D_LIBEXECDIR := $(call DESTDIR_NORMALIZE,$(LIBEXECDIR))

# root of data directories
DATAROOTDIR := $(PREFIX)/share
D_DATAROOTDIR := $(call DESTDIR_NORMALIZE,$(DATAROOTDIR))

# directory for read-only program data (package should install files to $(DATADIR)/package-name/)
DATADIR := $(DATAROOTDIR)
D_DATADIR := $(call DESTDIR_NORMALIZE,$(DATADIR))

# directory for text configurations
SYSCONFDIR := $(PREFIX)/etc
D_SYSCONFDIR := $(call DESTDIR_NORMALIZE,$(SYSCONFDIR))

# shared directory for program state files (modified while program is run)
SHAREDSTATEDIR := $(PREFIX)/com
D_SHAREDSTATEDIR := $(call DESTDIR_NORMALIZE,$(SHAREDSTATEDIR))

# machine-local directory for program state files (modified while program is run)
LOCALSTATEDIR := $(PREFIX)/var
D_LOCALSTATEDIR := $(call DESTDIR_NORMALIZE,$(LOCALSTATEDIR))

# directory for program state files persisting no more than program lifetime (such as PIDs)
RUNSTATEDIR := $(LOCALSTATEDIR)/run
D_RUNSTATEDIR := $(call DESTDIR_NORMALIZE,$(RUNSTATEDIR))

# directory for header files
INCLUDEDIR := $(PREFIX)/include
D_INCLUDEDIR := $(call DESTDIR_NORMALIZE,$(INCLUDEDIR))

# name of the package
PACKAGE_NAME := $(error PACKAGE_NAME is not defined - define it in project configuration makefile)

# directory for documentation files
DOCDIR := $(DATAROOTDIR)/doc/$(PACKAGE_NAME)
D_DOCDIR := $(call DESTDIR_NORMALIZE,$(DOCDIR))

# directory for documentation files in the particular format
HTMLDIR := $(DOCDIR)
DVIDIR  := $(DOCDIR)
PDFDIR  := $(DOCDIR)
PSDIR   := $(DOCDIR)
D_HTMLDIR := $(call DESTDIR_NORMALIZE,$(HTMLDIR))
D_DVIDIR  := $(call DESTDIR_NORMALIZE,$(DVIDIR))
D_PDFDIR  := $(call DESTDIR_NORMALIZE,$(PDFDIR))
D_PSDIR   := $(call DESTDIR_NORMALIZE,$(PSDIR))

# directory where to install shared libraries
LIBDIR := $(EXEC_PREFIX)/lib
D_LIBDIR := $(call DESTDIR_NORMALIZE,$(LIBDIR))

# directory where to install development libraries
DEVLIBDIR := $(LIBDIR)
D_DEVLIBDIR := $(call DESTDIR_NORMALIZE,$(DEVLIBDIR))

# directory for locale-specific message catalogs
LOCALEDIR := $(DATAROOTDIR)/locale
D_LOCALEDIR := $(call DESTDIR_NORMALIZE,$(LOCALEDIR))

# directory for info files
INFODIR := $(DATAROOTDIR)/info
D_INFODIR := $(call DESTDIR_NORMALIZE,$(INFODIR))

# top-level directory for installing the man pages
MANDIR := $(DATAROOTDIR)/man
D_MANDIR := $(call DESTDIR_NORMALIZE,$(MANDIR))

# directories for manual pages
MAN1DIR := $(MANDIR)/man1
MAN2DIR := $(MANDIR)/man2
MAN3DIR := $(MANDIR)/man3
MAN4DIR := $(MANDIR)/man4
MAN5DIR := $(MANDIR)/man5
MAN6DIR := $(MANDIR)/man6
MAN7DIR := $(MANDIR)/man7
MAN8DIR := $(MANDIR)/man8
D_MAN1DIR := $(call DESTDIR_NORMALIZE,$(MAN1DIR))
D_MAN2DIR := $(call DESTDIR_NORMALIZE,$(MAN2DIR))
D_MAN3DIR := $(call DESTDIR_NORMALIZE,$(MAN3DIR))
D_MAN4DIR := $(call DESTDIR_NORMALIZE,$(MAN4DIR))
D_MAN5DIR := $(call DESTDIR_NORMALIZE,$(MAN5DIR))
D_MAN6DIR := $(call DESTDIR_NORMALIZE,$(MAN6DIR))
D_MAN7DIR := $(call DESTDIR_NORMALIZE,$(MAN7DIR))
D_MAN8DIR := $(call DESTDIR_NORMALIZE,$(MAN8DIR))

# directory where to install pkg-config files for a library
PKG_LIBDIR := $(DEVLIBDIR)/pkgconfig
D_PKG_LIBDIR := $(call DESTDIR_NORMALIZE,$(PKG_LIBDIR))

# directory where to install pkg-config files for header-only library
PKG_DATADIR := $(DATAROOTDIR)/pkgconfig
D_PKG_DATADIR := $(call DESTDIR_NORMALIZE,$(PKG_DATADIR))

# define install/uninstall targets
INSTALL_MSG := Successfully installed to '$(D_PREFIX)'
install:
	@$(info $(INSTALL_MSG))

UNINSTALL_MSG := Uninstalled from '$(D_PREFIX)'
uninstall:
	@$(info $(UNINSTALL_MSG))

# register more goals supported by clean-build
CLEAN_BUILD_GOALS += install uninstall

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,NO_DEVEL DESTDIR INSTALL_OS_TYPE DESTDIR_NORMALIZE \
  PREFIX D_PREFIX EXEC_PREFIX D_EXEC_PREFIX BINDIR D_BINDIR SBINDIR D_SBINDIR LIBEXECDIR D_LIBEXECDIR \
  DATAROOTDIR D_DATAROOTDIR DATADIR D_DATADIR SYSCONFDIR D_SYSCONFDIR SHAREDSTATEDIR D_SHAREDSTATEDIR \
  LOCALSTATEDIR D_LOCALSTATEDIR RUNSTATEDIR D_RUNSTATEDIR INCLUDEDIR D_INCLUDEDIR PACKAGE_NAME DOCDIR D_DOCDIR \
  HTMLDIR DVIDIR PDFDIR PSDIR D_HTMLDIR D_DVIDIR D_PDFDIR D_PSDIR \
  LIBDIR D_LIBDIR DEVLIBDIR D_DEVLIBDIR LOCALEDIR D_LOCALEDIR INFODIR D_INFODIR MANDIR D_MANDIR \
  MAN1DIR MAN2DIR MAN3DIR MAN4DIR MAN5DIR MAN6DIR MAN7DIR MAN8DIR \
  D_MAN1DIR D_MAN2DIR D_MAN3DIR D_MAN4DIR D_MAN5DIR D_MAN6DIR D_MAN7DIR D_MAN8DIR \
  PKG_LIBDIR D_PKG_LIBDIR PKG_DATADIR D_PKG_DATADIR INSTALL_MSG UNINSTALL_MSG)

# do not trace calls to macros modified via operator +=
$(call SET_GLOBAL,CLEAN_BUILD_GOALS,0)
