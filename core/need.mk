#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define macros:
#  'need_built_files' - define rules for linking built files to target's private namespace
#  'need_tool_files'  - define rules for linking deployed tool files to target's private namespace
#  'need_built_dirs'  - define rules for linking associated/deployed built directories to target's private namespace
#  'need_tool_dirs'   - define rules for linking deployed tool directories to target's private namespace
#  'need_tool_execs'  - define rules for linking built tool executables to target's private namespace

ifdef priv_prefix

# ---------- needed files ---------------------

# $1 - absolute path to the target for which built files are needed
# $2 - absolute paths to needed files
# $3 - absolute paths to destination files
# note: a rule for creating target $1 may be defined elsewhere, so do not set current makefile info for it here,
#  instead call 'set_makefile_info_r' for each linked file
define cb_need_files
cb_needed_dirs += $(patsubst $(cb_build)/%/,%,$(dir $3))
$(subst |, | ,$(subst ||,: ,$(subst / ,$(newline),$(join $(join $(3:=||),$(2:=|)),$(dir $3)) )))$1: $3
$(call set_makefile_info_r,$(call suppress_targets_r,$3)):
	$$(call suppress,LN,$$@)$$(call create_simlink,$$@,$$<)
endef

# protect new value of 'cb_needed_dirs', do not trace calls to it because it's incremented
ifdef cb_checking
$(call define_append,cb_need_files,$(newline)$(call set_global1,cb_needed_dirs))
endif

# define rules for linking needed built files to target's private namespace
# $1 - the target for which the files are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file1.txt gen/file2.txt
# note: built files are not deployed to "public" place by default (only via explicit 'deploy_files'), link them from private places
ifdef cb_checking
need_built_files = $(cb_check_vpath)$(eval $(call cb_need_files,$(o_path),$(call o_path,$2),$(addprefix $(o_dir)/,$2)))
else
need_built_files = $(eval $(call cb_need_files,$(o_path),$(call o_path,$2),$(addprefix $(o_dir)/,$2)))
endif

# define rules for linking needed (previously deployed via 'deploy_files') tool files to target's private namespace
# $1 - the target for which the files are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - tool files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file1.txt gen/file2.txt
# note: tool files should be deployed to "public" place, so link them from there
ifdef cb_checking
need_tool_files = $(cb_check_vpath)$(eval $(call cb_need_files,$(o_path),$(addprefix \
  $(cb_build)/$(cb_tools_subdir)/,$(call cb_check_vpaths_r,$2)),$(addprefix $(o_dir)/,$2)))
else
need_tool_files = $(eval $(call cb_need_files,$(o_path),$(addprefix \
  $(cb_build)/$(cb_tools_subdir)/,$2),$(addprefix $(o_dir)/,$2)))
endif

# ---------- needed directories ---------------

# link built dirs from tag file's private namespace directory
# $1 - needed tag file, e.g.: gen/g1.tag
# $2 - absolute path to namespace directory of the target for which the dirs are needed, e.g.: /build/pp/bin-test.exe/
# $3 - needed directories, e.g.: gen/g1
# $4 - destination directories: $(addprefix $2,$3)
define cb_need_built_dirs
$(call set_makefile_info_r,$(call suppress_targets_r,$2$1)): $(o_path) | $(patsubst %/,%,$(dir $2$1 $4))
	$$(call cb_gen_dir_linking_rules,$(addprefix $(o_dir)/,$3),$4)
	$$(call suppress,LN,$$@)$$(call create_simlink,$$@,$$<)
endef

# link tool dirs from "public" place
# $1 - needed tag file, e.g.: gen/g1.tag
# $2 - absolute path to namespace directory of the target for which the dirs are needed, e.g.: /build/pp/bin-test.exe/
# $3 - needed directories, e.g.: gen/g1
# $4 - destination directories: $(addprefix $2,$3)
define cb_need_tool_dirs
$(call set_makefile_info_r,$(call suppress_targets_r,$2$1)): $(cb_build)/$(cb_tools_subdir)/$1 | $(patsubst %/,%,$(dir $2$1 $4))
	$$(call cb_gen_dir_linking_rules,$(addprefix $(cb_build)/$(cb_tools_subdir)/,$3),$4)
	$$(call suppress,LN,$$@)$$(call create_simlink,$$@,$$<)
endef

# $1 - needed tag file, e.g.: gen/g1.tag
# $2 - absolute path to namespace directory of the target for which the dirs are needed, e.g.: /build/pp/bin-test.exe/
# $3 - needed directories, e.g.: gen/g1
# $4 - 'cb_need_built_dirs'/'cb_need_tool_dirs'
cb_need_dirs3 = $(call $4,$1,$2,$3,$(addprefix $2,$3))

# $1 - absolute path to the target for which the dirs are needed,                        e.g.: /build/pp/bin-test.exe/bin/test.exe
# $2 - absolute path to namespace directory of the target for which the dirs are needed, e.g.: /build/pp/bin-test.exe/
# $3 - needed directories, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1 gen/gen2/g3
# $4 - sorted list of needed tag files, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1.tag gen/gen2/g3.tag
# $5 - join of tag files and needed directories, e.g.: gen/g1.tag|gen/g1 gen/gen2/g3.tag|gen/gen2/g3
# $6 - 'cb_need_built_dirs'/'cb_need_tool_dirs'
define cb_need_dirs2
cb_needed_dirs += $(patsubst $(cb_build)/%/,%,$(dir $(addprefix $2,$4 $3)))
$(foreach t,$4,$(call cb_need_dirs3,$t,$2,$(patsubst $t|%,%,$(filter $t|%,$5)),$6)$(newline))$1: $(addprefix $2,$4)
endef

# protect new value of 'cb_needed_dirs', do not trace calls to it because it's incremented
ifdef cb_checking
$(call define_append,cb_need_dirs2,$(newline)$(call set_global1,cb_needed_dirs))
endif

# $1 - the target for which the dirs are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed directories, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1 gen/gen2/g3
# $3 - needed tag files, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1.tag gen/gen2/g3.tag
# $4 - 'cb_need_built_dirs'/'cb_need_tool_dirs'
ifdef cb_checking
cb_need_dirs1 = $(call cb_need_dirs2,$(o_path),$(o_dir)/,$2,$(call cb_check_vpaths_r,$(sort $3)),$(join $(3:=|),$2),$4)
else
cb_need_dirs1 = $(call cb_need_dirs2,$(o_path),$(o_dir)/,$2,$(sort $3),$(join $(3:=|),$2),$4)
endif

# $1 - the target for which the dirs are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed directories, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1 gen/gen2/g3
# $3 - $2 or $(2:=/)
# $4 - 'cb_need_built_dirs'/'cb_need_tool_dirs'
ifdef cb_checking
cb_need_dirs = $(eval $(call cb_need_dirs1,$(cb_check_vpath_r),$(call cb_check_vpaths_r,$2),$(foreach d,$3,$($d.^d)),$4))
else
cb_need_dirs = $(eval $(call cb_need_dirs1,$1,$2,$(foreach d,$3,$($d.^d)),$4))
endif

# define rules for linking needed (previously associated via 'assoc_dirs'/'deploy_dirs') built directories to target's private namespace
# $1 - the target for which the dirs are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed directories, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1 gen/gen2/g3
# note: built directories are not deployed to "public" place by default (only via explicit 'deploy_dirs'), link them from private places
# note: multiple directories may be associated with a single tag file
need_built_dirs = $(call cb_need_dirs,$1,$2,$2,cb_need_built_dirs)

# define rules for linking needed (previously deployed via 'deploy_dirs') tool directories to target's private namespace
# $1 - the target for which the dirs are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed directories, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1 gen/gen2/g3
# note: tool directories should be deployed to "public" place, so link them from there
# note: multiple directories may be associated with a single tag file
need_tool_dirs = $(call cb_need_dirs,$1,$2,$(2:=/),cb_need_tool_dirs)

else # !priv_prefix

# files and directories are built directly in "public" place, no need to link there them from private modules build directories

# define dependency on needed built files for the target
# $1 - the target for which the files are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file1.txt gen/file2.txt
ifdef cb_checking
need_built_files = $(eval $(call o_path,$(cb_check_vpath_r): $2))
else
need_built_files = $(eval $(call o_path,$1: $2))
endif

# define dependency on needed tool files for the target
# $1 - the target for which the files are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - tool files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file1.txt gen/file2.txt
ifdef cb_checking
need_tool_files1 = $(o_path): $(addprefix $(cb_build)/$(cb_tools_subdir)/,$(call cb_check_vpaths_r,$2))
need_tool_files = $(cb_check_vpath)$(eval $(need_tool_files1))
else
need_tool_files = $(eval $(o_path): $(addprefix $(cb_build)/$(cb_tools_subdir)/,$2))
endif

# define dependency on tag files of needed (previously associated via 'assoc_dirs'/'deploy_dirs') built directories for the target
# $1 - the target for which the dirs are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed directories, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1 gen/gen2/g3
# note: multiple directories may be associated with a single tag file
ifdef cb_checking
need_built_dirs = $(eval $(call o_path,$(cb_check_vpath_r): $(sort $(foreach d,$2,$($d.^d)))))
else
need_built_dirs = $(eval $(call o_path,$1: $(sort $(foreach d,$2,$($d.^d)))))
endif

# define dependency on tag files of needed (previously deployed via 'deploy_dirs') tool directories for the target
# $1 - the target for which the dirs are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed directories, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1 gen/gen2/g3
# note: multiple directories may be associated with a single tag file
ifdef cb_checking
need_tool_dirs1 = $(o_path): $(addprefix $(cb_build)/$(cb_tools_subdir)/,$(call cb_check_vpaths_r,$(sort $(foreach d,$(2:=/),$($d.^d)))))
need_tool_dirs = $(cb_check_vpath)$(eval $(need_tool_dirs1))
else
need_tool_dirs = $(eval $(o_path): $(sort $(foreach d,$(2:=/),$($d.^d)))))
endif

endif # !priv_prefix

# executable file suffix of the generated tools
tool_exe_suffix := $(if $(filter WIN% CYGWIN% MINGW%,$(CBLD_OS)),.exe)

# simplified version of 'need_tool_files': define rules for linking needed built executables to target's private namespace
# $1 - the target for which the tools are needed - must be a simple path relative to virtual $(out_dir), e.g.: gen/file.txt
# $2 - tool executable files, must be simple paths relative to virtual $(out_dir) _without_ extension, e.g.: bin/tool1 bin/tool2
need_tool_execs = $(call need_tool_files,$1,$(addsuffix $(tool_exe_suffix),$2))

# $1 - the target for which the files are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
need_built_files_r = $(need_built_files)$1
need_tool_files_r  = $(need_tool_files)$1
need_built_dirs_r  = $(need_built_dirs)$1
need_tool_dirs_r   = $(need_tool_dirs)$1
need_tool_execs_r  = $(need_tool_execs)$1

# makefile parsing first phase variables
# note: 'o_dir' and 'o_path' change their values in "tool" mode
cb_first_phase_vars += cb_need_files need_built_files need_tool_files cb_need_built_dirs cb_need_tool_dirs cb_need_dirs3 cb_need_dirs2 \
  cb_need_dirs1 cb_need_dirs need_built_dirs need_tool_dirs need_tool_files1 need_tool_dirs1 need_tool_execs need_built_files_r \
  need_tool_files_r need_built_dirs_r need_tool_dirs_r need_tool_execs_r

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: need
$(call set_global,cb_need_files need_built_files need_tool_files cb_need_built_dirs cb_need_tool_dirs cb_need_dirs3 cb_need_dirs2 \
  cb_need_dirs1 cb_need_dirs need_built_dirs need_tool_dirs need_tool_files1 need_tool_dirs1 tool_exe_suffix need_tool_execs \
  need_built_files_r need_tool_files_r need_built_dirs_r need_tool_dirs_r need_tool_execs_r,need)
