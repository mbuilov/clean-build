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

# defaults, may be overridden either in command line or in project configuration makefile
# note: assume installation paths _may_ contain spaces
# note: use D_... macros to get $(DESTDIR)-prefixed paths

# normalize path: prepend it with $(DESTDIR), convert backslashes to forward ones, remove trailing and excessive slashes
DESTDIR_NORMALIZE = $(subst ?, ,$(subst $(space),/,$(strip $(subst \, ,$(subst /, ,$(subst $(space),?,$(DESTDIR)$($1)))))))

# root of program installation directory
PREFIX := $(if $(filter WINDOWS,$(OS)),artifacts,/usr/local)
D_PREFIX = $(call DESTDIR_NORMALIZE,PREFIX)

# directory for executables
EXEC_PREFIX := $(PREFIX)
D_EXEC_PREFIX = $(call DESTDIR_NORMALIZE,EXEC_PREFIX)

# directory for non-superuser executables
BINDIR := $(EXEC_PREFIX)/bin
D_BINDIR = $(call DESTDIR_NORMALIZE,BINDIR)

# directory for superuser executables
SBINDIR := $(EXEC_PREFIX)/sbin
D_SBINDIR = $(call DESTDIR_NORMALIZE,SBINDIR)

# directory for support executables not run by user
LIBEXECDIR := $(EXEC_PREFIX)/libexec
D_LIBEXECDIR = $(call DESTDIR_NORMALIZE,LIBEXECDIR)

# root of data directories
DATAROOTDIR := $(PREFIX)/share
D_DATAROOTDIR = $(call DESTDIR_NORMALIZE,DATAROOTDIR)

# directory for read-only program data (package should install files to $(DATADIR)/package-name/)
DATADIR := $(DATAROOTDIR)
D_DATADIR = $(call DESTDIR_NORMALIZE,DATADIR)

# directory for text configurations
SYSCONFDIR := $(PREFIX)/etc
D_SYSCONFDIR = $(call DESTDIR_NORMALIZE,SYSCONFDIR)

# shared directory for program state files (modified while program is run)
SHAREDSTATEDIR := $(PREFIX)/com
D_SHAREDSTATEDIR = $(call DESTDIR_NORMALIZE,SHAREDSTATEDIR)

# machine-local directory for program state files (modified while program is run)
LOCALSTATEDIR := $(PREFIX)/var
D_LOCALSTATEDIR = $(call DESTDIR_NORMALIZE,LOCALSTATEDIR)

# directory for program state files persisting no more than program lifetime (such as PIDs)
RUNSTATEDIR := $(LOCALSTATEDIR)/run
D_RUNSTATEDIR = $(call DESTDIR_NORMALIZE,RUNSTATEDIR)

# directory for header files
INCLUDEDIR := $(PREFIX)/include
D_INCLUDEDIR = $(call DESTDIR_NORMALIZE,INCLUDEDIR)

# name of the package
PACKAGE_NAME = $(error PACKAGE_NAME is not defined - define it in project configuration makefile)

# directory for documentation files
DOCDIR = $(DATAROOTDIR)/doc/$(PACKAGE_NAME)
D_DOCDIR = $(call DESTDIR_NORMALIZE,DOCDIR)

# directory for documentation files in the particular format
HTMLDIR = $(DOCDIR)
DVIDIR  = $(DOCDIR)
PDFDIR  = $(DOCDIR)
PSDIR   = $(DOCDIR)
D_HTMLDIR = $(call DESTDIR_NORMALIZE,HTMLDIR)
D_DVIDIR  = $(call DESTDIR_NORMALIZE,DVIDIR)
D_PDFDIR  = $(call DESTDIR_NORMALIZE,PDFDIR)
D_PSDIR   = $(call DESTDIR_NORMALIZE,PSDIR)

# directory where to install libraries
LIBDIR := $(EXEC_PREFIX)/lib
D_LIBDIR = $(call DESTDIR_NORMALIZE,LIBDIR)

# directory for locale-specific message catalogs
LOCALEDIR := $(DATAROOTDIR)/locale
D_LOCALEDIR = $(call DESTDIR_NORMALIZE,LOCALEDIR)

# directory for info files
INFODIR := $(DATAROOTDIR)/info
D_INFODIR = $(call DESTDIR_NORMALIZE,INFODIR)

# top-level directory for installing the man pages
MANDIR := $(DATAROOTDIR)/man
D_MANDIR = $(call DESTDIR_NORMALIZE,MANDIR)

# directories for manual pages
MAN1DIR := $(MANDIR)/man1
MAN2DIR := $(MANDIR)/man2
MAN3DIR := $(MANDIR)/man3
MAN4DIR := $(MANDIR)/man4
MAN5DIR := $(MANDIR)/man5
MAN6DIR := $(MANDIR)/man6
MAN7DIR := $(MANDIR)/man7
MAN8DIR := $(MANDIR)/man8
D_MAN1DIR = $(call DESTDIR_NORMALIZE,MAN1DIR)
D_MAN2DIR = $(call DESTDIR_NORMALIZE,MAN2DIR)
D_MAN3DIR = $(call DESTDIR_NORMALIZE,MAN3DIR)
D_MAN4DIR = $(call DESTDIR_NORMALIZE,MAN4DIR)
D_MAN5DIR = $(call DESTDIR_NORMALIZE,MAN5DIR)
D_MAN6DIR = $(call DESTDIR_NORMALIZE,MAN6DIR)
D_MAN7DIR = $(call DESTDIR_NORMALIZE,MAN7DIR)
D_MAN8DIR = $(call DESTDIR_NORMALIZE,MAN8DIR)

# directory where to install pkg-config files
PKG_CONFIG_DIR := $(LIBDIR)/pkgconfig
D_PKG_CONFIG_DIR = $(call DESTDIR_NORMALIZE,PKG_CONFIG_DIR)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,NO_DEVEL DESTDIR DESTDIR_NORMALIZE \
  PREFIX D_PREFIX EXEC_PREFIX D_EXEC_PREFIX BINDIR D_BINDIR SBINDIR D_SBINDIR LIBEXECDIR D_LIBEXECDIR \
  DATAROOTDIR D_DATAROOTDIR DATADIR D_DATADIR SYSCONFDIR D_SYSCONFDIR SHAREDSTATEDIR D_SHAREDSTATEDIR \
  LOCALSTATEDIR D_LOCALSTATEDIR RUNSTATEDIR D_RUNSTATEDIR INCLUDEDIR D_INCLUDEDIR PACKAGE_NAME DOCDIR D_DOCDIR \
  HTMLDIR DVIDIR PDFDIR PSDIR D_HTMLDIR D_DVIDIR D_PDFDIR D_PSDIR \
  LIBDIR D_LIBDIR LOCALEDIR D_LOCALEDIR INFODIR D_INFODIR MANDIR D_MANDIR \
  MAN1DIR MAN2DIR MAN3DIR MAN4DIR MAN5DIR MAN6DIR MAN7DIR MAN8DIR \
  D_MAN1DIR D_MAN2DIR D_MAN3DIR D_MAN4DIR D_MAN5DIR D_MAN6DIR D_MAN7DIR D_MAN8DIR \
  PKG_CONFIG_DIR D_PKG_CONFIG_DIR)
