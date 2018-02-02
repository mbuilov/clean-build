#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define variables used in installation templates

# included by $(cb_dir)/install/impl/inst_utils.mk

# non-empty if do not install development files and headers
# by default, install development files
# note: normally overridden in the command line
CBLD_NO_DEVEL ?=

# type of operating system on which to install
# note: this value is used only to form the names of standard makefiles with definitions of installation templates
CBLD_INSTALL_OS_TYPE ?= $(if $(filter CYGWIN% MINGW% WIN%,$(CBLD_OS)),windows,unix)

# prefix for installed directories
DESTDIR ?=

# normalize path: prepend it with $(DESTDIR), convert backslashes to forward ones, remove trailing and excessive slashes
destdir_normalize = $(patsubst %/,%,$(subst //,/,$(subst \,/,$(DESTDIR)$1)))

# defaults, may be overridden either in the command line or in project configuration makefile
# note: assume installation paths _may_ contain spaces
# note: use d_... macros to get $(DESTDIR)-prefixed paths

# root of program installation directory
PREFIX ?= $(if $(filter WIN%,$(CBLD_OS)),artifacts,/usr/local)
d_prefix := $(call destdir_normalize,$(PREFIX))

# directory for executables
EXEC_PREFIX ?= $(PREFIX)
d_exec_prefix := $(call destdir_normalize,$(EXEC_PREFIX))

# directory for non-superuser executables
BINDIR ?= $(EXEC_PREFIX)/bin
d_bindir := $(call destdir_normalize,$(BINDIR))

# directory for superuser executables
SBINDIR ?= $(EXEC_PREFIX)/sbin
d_sbindir := $(call destdir_normalize,$(SBINDIR))

# directory for support executables not run by user
LIBEXECDIR ?= $(EXEC_PREFIX)/libexec
d_libexecdir := $(call destdir_normalize,$(LIBEXECDIR))

# root of data directories
DATAROOTDIR ?= $(PREFIX)/share
d_datarootdir := $(call destdir_normalize,$(DATAROOTDIR))

# directory for read-only program data (package should install files to $(DATADIR)/package-name/)
DATADIR ?= $(DATAROOTDIR)
d_datadir := $(call destdir_normalize,$(DATADIR))

# directory for text configurations
SYSCONFDIR ?= $(PREFIX)/etc
d_sysconfdir := $(call destdir_normalize,$(SYSCONFDIR))

# shared directory for program state files (modified while program is run)
SHAREDSTATEDIR ?= $(PREFIX)/com
d_sharedstatedir := $(call destdir_normalize,$(SHAREDSTATEDIR))

# machine-local directory for program state files (modified while program is run)
LOCALSTATEDIR ?= $(PREFIX)/var
d_localstatedir := $(call destdir_normalize,$(LOCALSTATEDIR))

# directory for program state files persisting no more than program lifetime (such as PIDs)
RUNSTATEDIR ?= $(LOCALSTATEDIR)/run
d_runstatedir := $(call destdir_normalize,$(RUNSTATEDIR))

# directory for header files
INCLUDEDIR ?= $(PREFIX)/include
d_includedir := $(call destdir_normalize,$(INCLUDEDIR))

# name of the package
package_name := $(product_name)

# directory for documentation files
DOCDIR ?= $(DATAROOTDIR)/doc/$(package_name)
d_docdir := $(call destdir_normalize,$(DOCDIR))

# directory for documentation files in the particular format
HTMLDIR ?= $(DOCDIR)
DVIDIR  ?= $(DOCDIR)
PDFDIR  ?= $(DOCDIR)
PSDIR   ?= $(DOCDIR)
d_htmldir := $(call destdir_normalize,$(HTMLDIR))
d_dvidir  := $(call destdir_normalize,$(DVIDIR))
d_pdfdir  := $(call destdir_normalize,$(PDFDIR))
d_psdir   := $(call destdir_normalize,$(PSDIR))

# directory where to install shared libraries
LIBDIR ?= $(EXEC_PREFIX)/lib
d_libdir := $(call destdir_normalize,$(LIBDIR))

# directory where to install development libraries
DEVLIBDIR ?= $(LIBDIR)
d_devlibdir := $(call destdir_normalize,$(DEVLIBDIR))

# directory for locale-specific message catalogs
LOCALEDIR ?= $(DATAROOTDIR)/locale
d_localedir := $(call destdir_normalize,$(LOCALEDIR))

# directory for files in the 'info' format
INFODIR ?= $(DATAROOTDIR)/info
d_infodir := $(call destdir_normalize,$(INFODIR))

# top-level directory for installing the man pages
MANDIR ?= $(DATAROOTDIR)/man
d_mandir := $(call destdir_normalize,$(MANDIR))

# directories for manual pages
MAN1DIR ?= $(MANDIR)/man1
MAN2DIR ?= $(MANDIR)/man2
MAN3DIR ?= $(MANDIR)/man3
MAN4DIR ?= $(MANDIR)/man4
MAN5DIR ?= $(MANDIR)/man5
MAN6DIR ?= $(MANDIR)/man6
MAN7DIR ?= $(MANDIR)/man7
MAN8DIR ?= $(MANDIR)/man8
d_man1dir := $(call destdir_normalize,$(MAN1DIR))
d_man2dir := $(call destdir_normalize,$(MAN2DIR))
d_man3dir := $(call destdir_normalize,$(MAN3DIR))
d_man4dir := $(call destdir_normalize,$(MAN4DIR))
d_man5dir := $(call destdir_normalize,$(MAN5DIR))
d_man6dir := $(call destdir_normalize,$(MAN6DIR))
d_man7dir := $(call destdir_normalize,$(MAN7DIR))
d_man8dir := $(call destdir_normalize,$(MAN8DIR))

# directory where to install pkg-config files for a library
PKG_LIBDIR ?= $(DEVLIBDIR)/pkgconfig
d_pkg_libdir := $(call destdir_normalize,$(PKG_LIBDIR))

# directory where to install pkg-config files for header-only library
PKG_DATADIR ?= $(DATAROOTDIR)/pkgconfig
d_pkg_datadir := $(call destdir_normalize,$(PKG_DATADIR))

# define install/uninstall targets
install_msg := Successfully installed to '$(d_prefix)'
install:
	@$(info $(install_msg))

uninstall_msg := Uninstalled from '$(d_prefix)'
uninstall:
	@$(info $(uninstall_msg))

# register more goals supported by the build system
build_system_goals += install uninstall

# remember value of variables possibly taken from the environment
$(call config_remember_vars,CBLD_NO_DEVEL CBLD_INSTALL_OS_TYPE DESTDIR PREFIX EXEC_PREFIX BINDIR SBINDIR LIBEXECDIR DATAROOTDIR \
  DATADIR SYSCONFDIR SHAREDSTATEDIR LOCALSTATEDIR RUNSTATEDIR INCLUDEDIR DOCDIR HTMLDIR DVIDIR PDFDIR PSDIR LIBDIR DEVLIBDIR \
  LOCALEDIR INFODIR MANDIR MAN1DIR MAN2DIR MAN3DIR MAN4DIR MAN5DIR MAN6DIR MAN7DIR MAN8DIR PKG_LIBDIR PKG_DATADIR)

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,CBLD_NO_DEVEL CBLD_INSTALL_OS_TYPE DESTDIR PREFIX EXEC_PREFIX BINDIR SBINDIR LIBEXECDIR DATAROOTDIR \
  DATADIR SYSCONFDIR SHAREDSTATEDIR LOCALSTATEDIR RUNSTATEDIR INCLUDEDIR DOCDIR HTMLDIR DVIDIR PDFDIR PSDIR LIBDIR DEVLIBDIR \
  LOCALEDIR INFODIR MANDIR MAN1DIR MAN2DIR MAN3DIR MAN4DIR MAN5DIR MAN6DIR MAN7DIR MAN8DIR PKG_LIBDIR PKG_DATADIR build_system_goals)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: inst_dirs
$(call set_global,destdir_normalize d_prefix d_exec_prefix d_bindir d_sbindir d_libexecdir d_datarootdir d_datadir d_sysconfdir \
  d_sharedstatedir d_localstatedir d_runstatedir d_includedir package_name d_docdir d_htmldir d_dvidir d_pdfdir d_psdir d_libdir \
  d_devlibdir d_localedir d_infodir d_mandir d_man1dir d_man2dir d_man3dir d_man4dir d_man5dir d_man6dir d_man7dir d_man8dir \
  d_pkg_libdir d_pkg_datadir,inst_dirs)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: install
$(call set_global,install_msg uninstall_msg,install)
