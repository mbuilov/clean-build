#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define macros:
#  'o_dir'  - for given target virtual path, get absolute path to output directory
#  'o_path' - for given target virtual path, get absolute path to output file

# base part of sub-directory of $(cb_build) where artifacts are built, e.g. DEBUG-LINUX-x86
# note: build tools are built in another place - see 'tool_base' below
target_triplet := $(CBLD_TARGET)-$(CBLD_OS)-$(CBLD_CPU)

# sub-directory of $(cb_build)/$(target_triplet) for the targets private namespaces
# - where each target will have a private namespace directory, target files are built in this directory,
#  target prerequisites are linked to this directory prior building the target
# note: 'priv_prefix' may be overridden in project configuration makefile or in the command line
ifdef cb_checking
priv_prefix := pp
else
priv_prefix:=
endif

# check that paths are virtual (i.e. relative and simple): 1/2/3, but not /1/2/3 or 1//2/3 or 1/2/../3
ifdef cb_checking
cb_check_vpaths   = $(if $(filter-out $(addprefix /,$1),$(abspath $(addprefix /,$1))),$(error \
  path(s) are not relative and simple: $(foreach p,$1,$(if $(filter-out /$p,$(abspath /$p)),'$p'))))
cb_check_vpath    = $(if $(findstring $(space),$1),$(error path must not contain a space: '$1'),$(cb_check_vpaths))
cb_check_vpaths_r = $(cb_check_vpaths)$1
cb_check_vpath_r  = $(cb_check_vpath)$1
endif

# form names of private namespace directories for the targets: 1/2/3 4/5 -> 1-2-3 4-5
ifdef priv_prefix
ifdef cb_checking
cb_trg_priv = $(subst /,-,$(cb_check_vpaths_r))
else
cb_trg_priv = $(subst /,-,$1)
endif
endif

# ---------- output paths: 'o_dir' and 'o_path' ---------------

# get absolute paths to output directories for given targets
# $1 - simple paths relative to virtual $(out_dir), e.g.: gen/file.txt gen2/file2.txt
# note: define 'o_dir' assuming that we are not in "tool" mode
ifdef priv_prefix
$(eval o_dir = $$(addprefix $(cb_build)/$(target_triplet)/$(priv_prefix)/,$$(cb_trg_priv)))
else ifdef cb_checking
$(eval o_dir = $$(patsubst %,$(cb_build)/$(target_triplet),$$(cb_check_vpaths_r)))
else
$(eval o_dir = $$(patsubst %,$(cb_build)/$(target_triplet),$$1))
endif

# get absolute paths to built files
# $1 - simple paths relative to virtual $(out_dir), e.g.: gen/file.txt gen2/file2.txt
ifdef priv_prefix
$(eval o_path = $$(addprefix $(cb_build)/$(target_triplet)/$(priv_prefix)/,$$(join $$(addsuffix /,$$(cb_trg_priv)),$$1)))
else ifdef cb_checking
$(eval o_path = $$(addprefix $(cb_build)/$(target_triplet)/,$$(cb_check_vpaths_r)))
else
$(eval o_path = $$(addprefix $(cb_build)/$(target_triplet)/,$$1))
endif

# code to evaluate for restoring default output directory after "tool" mode
cb_set_default_vars := $(cb_set_default_vars)$(newline)o_dir=$(value o_dir)$(newline)o_path=$(value o_path)

# ---------- 'o_dir' and 'o_path' for "tool" mode -------------

# base path of sub-directory of $(cb_build) where auxiliary build tools are built
# note: path may be redefined in the project configuration makefile, must be relative and simple
tool_base:=

# macro to form a path where tools are built
# $1 - $(tool_base)
# $2 - $(CBLD_TCPU)
ifdef cb_checking
mk_tools_subdir = $(cb_check_vpath_r:=/)tool-$2-$(CBLD_TOOL_TARGET)
else
mk_tools_subdir = $(1:=/)tool-$2-$(CBLD_TOOL_TARGET)
endif

# sub-directory of $(cb_build) where tools are built, for the current values of 'tool_base' and CBLD_TCPU
cb_tools_subdir := $(call mk_tools_subdir,$(tool_base),$(CBLD_TCPU))

# code to evaluate for overriding default output directory in "tool" mode
ifdef priv_prefix
cb_tool_override_vars := $(cb_tool_override_vars)$(newline)o_dir=$$(addprefix \
  $(cb_build)/$(cb_tools_subdir)/$(priv_prefix)/,$$(cb_trg_priv))$(newline)o_path=$$(addprefix \
  $(cb_build)/$(cb_tools_subdir)/$(priv_prefix)/,$$(join $$(addsuffix /,$$(cb_trg_priv)),$$1))
else ifdef cb_checking
cb_tool_override_vars := $(cb_tool_override_vars)$(newline)o_dir=$$(patsubst \
  %,$(cb_build)/$(cb_tools_subdir),$$(cb_check_vpaths_r))$(newline)o_path=$$(addprefix \
  $(cb_build)/$(cb_tools_subdir)/,$$(cb_check_vpaths_r))
else
cb_tool_override_vars := $(cb_tool_override_vars)$(newline)o_dir=$$(patsubst \
  %,$(cb_build)/$(cb_tools_subdir),$$1)$(newline)o_path=$$(addprefix \
  $(cb_build)/$(cb_tools_subdir)/,$$1)
endif

# remember new values of 'o_dir' and 'o_path'
# note: trace namespace: o_path
ifdef set_global1
cb_set_default_vars   := $(cb_set_default_vars)$(newline)$(call set_global1,o_dir o_path,core)
cb_tool_override_vars := $(cb_tool_override_vars)$(newline)$(call set_global1,o_dir o_path,core)
endif

# makefile parsing first phase variables
# note: 'o_dir' and 'o_path' change their values in "tool" mode
cb_first_phase_vars += o_dir o_path

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,priv_prefix)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: o_path
$(call set_global,target_triplet cb_check_vpaths cb_check_vpath cb_check_vpaths_r cb_check_vpath_r \
  cb_trg_priv o_dir o_path tool_base mk_tools_subdir cb_tools_subdir,o_path)
