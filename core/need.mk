#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define macros:
#  'need_built_files_a' - define rules for linking built files to target's private namespace
#  'need_built_files'   - define rules for linking built files to target's private namespace
#  'need_tool_files'    - define rules for linking deployed tool files to target's private namespace
#  'need_built_dirs'    - define rules for linking associated/deployed built directories to target's private namespace
#  'need_tool_dirs'     - define rules for linking deployed tool directories to target's private namespace
#  'need_tool_execs'    - define rules for linking built tool executables to target's private namespace
#  'get_tool_execs'     - return absolute paths to tool executables for given target

ifdef cb_namespaces

ifndef cleaning

# ---------- link needed files ----------------

# $1 - absolute path to the target for which built files are needed
# $2 - absolute paths to destination files
# $3 - absolute paths to needed files ended with |
# note: a rule for creating target $1 may be defined elsewhere, so do not set current makefile info for it here,
#  instead call 'set_makefile_info_r' for each linked file
# note: there must be a space between braces in '$(dir $2)) )))'
define cb_need_files
cb_needed_dirs += $(patsubst $(cb_build)/%/,%,$(dir $2))
$(subst |, | ,$(subst ||,: ,$(subst / ,$(newline),$(join $(join $(2:=||),$3),$(dir $2)) )))$1: $2
$(call set_makefile_info_r,$(call suppress_targets_r,$2)):
	$$(call suppress,LN,$$@)$$(call sh_simlink_files,$$<,$$@)
endef

# protect new value of 'cb_needed_dirs', do not trace calls to it because it's incremented
ifdef cb_checking
$(call define_append,cb_need_files,$(newline)$$(call set_global1,cb_needed_dirs))
endif

# $1 - targets for which the files are needed - must be simple paths relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file1.txt gen/file2.txt
# $3 - absolute paths to needed files ended with |
need_built_files1 = $(if $(foreach t,$1,$(eval $(call \
  cb_need_files,$(call o_path,$t),$(addprefix $(call o_ns,$t)/,$2),$3))),)

# $1 - targets for which the files are needed - must be simple paths relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file1.txt gen/file2.txt
# $3 - absolute paths to tool files: $(patsubst %,$(cb_build)/$(cb_tools_subdir)/%|,$2)
need_tool_files1 = $(if $(foreach t,$1,$(eval $(call \
  cb_need_files,$(call o_path,$t),$(addprefix $(dir $(call o_ns,$t))$(cb_tools_subdir)/,$2),$3))),)

# define rules for linking needed built files to target's private namespace
# $1 - targets for which the files are needed - must be simple paths relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file1.txt gen/file2.txt
# $3 - absolute paths to needed files
# note: built files are not deployed to "public" place by default (only via explicit 'deploy_files'), link them from private places
ifdef cb_checking
need_built_files_a = $(call need_built_files1,$1,$(call cb_check_vpaths_r,$2),$(addsuffix |,$(call cb_check_apaths_r,$3)))
else
need_built_files_a = $(call need_built_files1,$1,$2,$(3:=|))
endif

# define rules for linking needed (previously deployed via 'deploy_files') tool files to target's private namespace
# $1 - targets for which the files are needed - must be simple paths relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - tool files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file1.txt gen/file2.txt
# note: tool files should be deployed to "public" place, so link them from there
ifdef cb_checking
need_tool_files = $(call need_tool_files1,$1,$2,$(patsubst %,$(cb_build)/$(cb_tools_subdir)/%|,$(call cb_check_vpaths_r,$2)))
else
need_tool_files = $(call need_tool_files1,$1,$2,$(patsubst %,$(cb_build)/$(cb_tools_subdir)/%|,$2))
endif

# ---------- link needed directories ----------

# link built dirs from tag file's private namespace directory
# $1 - needed tag file, e.g.: gen/g1.tag
# $2 - absolute path to namespace directory of the target for which the dirs are needed, e.g.: /build/p/tt/bin-test.exe@-/tt/
# $3 - needed directories, e.g.: gen/g1
# $4 - destination directories: $(addprefix $2,$3)
define cb_need_built_dirs
$(call set_makefile_info_r,$(call suppress_targets_r,$2$1)): $(o_path) | $(patsubst %/,%,$(dir $2$1 $4))
	$$(call cb_gen_dir_linking_rules,$(addprefix $(o_ns)/,$3),$4)
	$$(call suppress,LN,$$@)$$(call sh_simlink_files,$$<,$$@)
endef

# link tool dirs from "public" place
# $1 - needed tag file, e.g.: gen/g1.tag
# $2 - absolute path to namespace directory of the target for which the dirs are needed, e.g.: /build/p/tt/bin-test.exe@-/ts/
# $3 - needed directories, e.g.: gen/g1
# $4 - destination directories: $(addprefix $2,$3)
define cb_need_tool_dirs
$(call set_makefile_info_r,$(call suppress_targets_r,$2$1)): $(cb_build)/$(cb_tools_subdir)/$1 | $(patsubst %/,%,$(dir $2$1 $4))
	$$(call cb_gen_dir_linking_rules,$(addprefix $(cb_build)/$(cb_tools_subdir)/,$3),$4)
	$$(call suppress,LN,$$@)$$(call sh_simlink_files,$$<,$$@)
endef

# $1 - needed tag file, e.g.: gen/g1.tag
# $2 - absolute path to namespace directory of the target for which the dirs are needed, e.g.: /build/p/tt/bin-test.exe@-/tt/
#   or absolute path to namespace directory of the target for which the dirs are needed, e.g.: /build/p/tt/bin-test.exe@-/ts/
# $3 - needed directories, e.g.: gen/g1
# $4 - 'cb_need_built_dirs' or 'cb_need_tool_dirs'
cb_need_dirs3 = $(call $4,$1,$2,$3,$(addprefix $2,$3))

# $1 - absolute path to the target for which the dirs are needed,                        e.g.: /build/p/tt/bin-test.exe@-/tt/bin/test.exe
# $2 - absolute path to namespace directory of the target for which the dirs are needed, e.g.: /build/p/tt/bin-test.exe@-/tt/
#   or absolute path to namespace directory of the target for which the dirs are needed, e.g.: /build/p/tt/bin-test.exe@-/ts/
# $3 - needed directories, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1 gen/gen2/g3
# $4 - sorted list of needed tag files, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1.tag gen/gen2/g3.tag
# $5 - join of tag files and needed directories, e.g.: gen/g1.tag|gen/g1 gen/gen2/g3.tag|gen/gen2/g3
# $6 - 'cb_need_built_dirs' or 'cb_need_tool_dirs'
define cb_need_dirs2
cb_needed_dirs += $(patsubst $(cb_build)/%/,%,$(dir $(addprefix $2,$4 $3)))
$(foreach t,$4,$(call cb_need_dirs3,$t,$2,$(patsubst $t|%,%,$(filter $t|%,$5)),$6)$(newline))$1: $(addprefix $2,$4)
endef

# protect new value of 'cb_needed_dirs', do not trace calls to it because it's incremented
ifdef cb_checking
$(call define_append,cb_need_dirs2,$(newline)$$(call set_global1,cb_needed_dirs))
endif

# $1 - targets for which the dirs are needed - must be simple paths relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed directories, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1 gen/gen2/g3
# $3 - sorted list of needed tag files, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1.tag gen/gen2/g3.tag
# $4 - join of tag files and needed directories, e.g.: gen/g1.tag|gen/g1 gen/gen2/g3.tag|gen/gen2/g3
need_built_dirs2 = $(if $(foreach t,$1,$(eval $(call \
  cb_need_dirs2,$(call o_path,$t),$(call o_ns,$t)/,$2,$3,$4,cb_need_built_dirs))),)
need_tool_dirs2 = $(if $(foreach t,$1,$(eval $(call \
  cb_need_dirs2,$(call o_path,$t),$(dir $(call o_ns,$t))$(cb_tools_subdir)/,$2,$3,$4,cb_need_tool_dirs))),)

# $1 - targets for which the dirs are needed - must be simple paths relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed directories, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1 gen/gen2/g3
# $3 - needed tag files, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1.tag gen/gen2/g3.tag
# $4 - 'need_built_dirs2' or 'need_tool_dirs2'
ifdef cb_checking
cb_need_dirs1 = $(call $4,$1,$(call cb_check_vpaths_r,$2),$(call cb_check_vpaths_r,$(sort $3)),$(join $(3:=|),$2))
else
cb_need_dirs1 = $(call $4,$1,$2,$(sort $3),$(join $(3:=|),$2))
endif

# define rules for linking needed (previously associated via 'assoc_dirs'/'deploy_dirs') built directories to target's private namespace
# $1 - targets for which the dirs are needed - must be simple paths relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed directories, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1 gen/gen2/g3
# note: built directories are not deployed to "public" place by default (only via explicit 'deploy_dirs'), link them from private places
# note: multiple directories may be associated with a single tag file
need_built_dirs = $(call cb_need_dirs1,$1,$2,$(foreach d,$2,$($d.^d)),need_built_dirs2)

# define rules for linking needed (previously deployed via 'deploy_dirs') tool directories to target's private namespace
# $1 - targets for which the dirs are needed - must be simple paths relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed directories, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1 gen/gen2/g3
# note: tool directories should be deployed to "public" place, so link them from there
# note: multiple directories may be associated with a single tag file
need_tool_dirs = $(call cb_need_dirs1,$1,$2,$(foreach d,$2,$($d/.^d)),need_tool_dirs2)

else # cleaning

# just delete simlinks to needed files/directories for the target
need_built_files_a = $(if $(foreach t,$1,$(call toclean,$t,$2)),)
need_built_files = $(if $(foreach t,$1,$(call toclean,$t,$2)),)
need_tool_files = $(if $(foreach t,$1,$(call toclean,$t,$2)),)
cb_need_dirs1 = $(if $(foreach t,$1,$(call toclean,$t,$2)),)
need_built_dirs = $(call cb_need_dirs1,$1,$2 $(sort $(foreach d,$2,$($d.^d))))
need_tool_dirs = $(call cb_need_dirs1,$1,$2 $(sort $(foreach d,$2,$($d/.^d))))

# check that paths $3 are absolute
ifdef cb_checking
$(eval need_built_files_a = $$(call cb_check_apaths,$$3)$(value need_built_files_a))
endif

endif # cleaning

else ifndef cleaning # !cb_namespaces

# files and directories are built directly in "public" place, no need to link there them from private modules build directories

# $1 - targets for which the files are needed - must be simple paths relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file1.txt gen/file2.txt
# $3 - absolute paths to needed files
ifdef cb_checking
need_built_files1 = $(call cb_check_vpaths,$2)$(o_path): $(call cb_check_apaths_r,$3)
else
need_built_files1 = $(o_path): $3
endif

# define dependencies on needed built files for the targets
# $1 - targets for which the files are needed - must be simple paths relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file1.txt gen/file2.txt
# $3 - absolute paths to needed files
need_built_files_a = $(eval $(value need_built_files1))

# define dependencies on needed tool files for the targets
# $1 - targets for which the files are needed - must be simple paths relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - tool files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file1.txt gen/file2.txt
ifdef cb_checking
need_tool_files1 = $(o_path): $(addprefix $(cb_build)/$(cb_tools_subdir)/,$(call cb_check_vpaths_r,$2))
else
$(eval need_tool_files1 = $$(o_path): $$(addprefix $(cb_build)/$(cb_tools_subdir)/,$$2))
endif
need_tool_files = $(eval $(value need_tool_files1))

# define dependencies on tag files of needed (previously associated via 'assoc_dirs'/'deploy_dirs') built directories for the targets
# $1 - targets for which the dirs are needed - must be simple paths relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed directories, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1 gen/gen2/g3
# note: multiple directories may be associated with a single tag file
ifdef cb_checking
need_built_dirs1 = $(o_path): $(call o_path,$(sort $(foreach d,$(call cb_check_vpaths_r,$2),$($d.^d))))
else
need_built_dirs = $(o_path): $(call o_path,$(sort $(foreach d,$2,$($d.^d))))
endif
need_built_dirs = $(eval $(value need_built_dirs1))

# define dependencies on tag files of needed (previously deployed via 'deploy_dirs') tool directories for the targets
# $1 - targets for which the dirs are needed - must be simple paths relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed directories, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1 gen/gen2/g3
# note: multiple directories may be associated with a single tag file
ifdef cb_checking
need_tool_dirs1 = $(o_path): $(addprefix $(cb_build)/$(cb_tools_subdir)/,$(call \
  cb_check_vpaths_r,$(sort $(foreach d,$(call cb_check_vpaths_r,$2),$($d/.^d)))))
else
$(eval need_tool_dirs1 = $$(o_path): $$(addprefix $(cb_build)/$(cb_tools_subdir)/,$$(sort $$(foreach d,$$2,$$($$d/.^d)))))
endif
need_tool_dirs = $(eval $(value need_tool_dirs1))

else ifdef cb_checking # !cb_namespaces && cleaning

# just check that paths are simple and relative
need_built_files_a = $(call cb_check_vpaths,$1 $2)$(call cb_check_apaths,$3)
need_built_files = $(call cb_check_vpaths,$1 $2)
need_tool_files = $(call cb_check_vpaths,$1 $2)
need_built_dirs = $(call cb_check_vpaths,$1 $2)
need_tool_dirs = $(call cb_check_vpaths,$1 $2)

else # !cb_namespaces && cleaning && !cb_checking

# do nothing
need_built_files_a:=
need_built_files:=
need_tool_files:=
need_built_dirs:=
need_tool_dirs:=

endif # !cb_namespaces && cleaning && !cb_checking

ifndef cleaning

# define rules for linking needed built files to target's private namespace
# $1 - targets for which the files are needed - must be simple paths relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file1.txt gen/file2.txt
# note: built files are not deployed to "public" place by default (only via explicit 'deploy_files'), link them from private places
need_built_files = $(call need_built_files_a,$1,$2,$(call o_path,$2))

# define dependencies on needed built files for the targets
# $1 - targets for which the files are needed - must be simple paths relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file1.txt gen/file2.txt
need_built_files = $(call need_built_files_a,$1,$2,$(call o_path,$2))

endif # cleaning




# executable file suffix of the generated tools
tool_exe_suffix := $(if $(filter WIN% CYGWIN% MINGW%,$(CBLD_OS)),.exe)

# simplified version of 'need_tool_files': define rules for linking needed built executables to target's private namespace
# $1 - the target for which the tools are needed - must be a simple path relative to virtual $(out_dir), e.g.: gen/file.txt
# $2 - tool executable files, must be simple paths relative to virtual $(out_dir) _without_ extension, e.g.: bin/tool1 bin/tool2
need_tool_execs = $(call need_tool_files,$1,$(addsuffix $(tool_exe_suffix),$2))

# return absolute paths to tool executables needed for given target
# $1 - the target for which the tools are needed - must be a simple path relative to virtual $(out_dir), e.g.: gen/file.txt
# $2 - tool executable files, must be simple paths relative to virtual $(out_dir) _without_ extension, e.g.: bin/tool1 bin/tool2
# note: 'get_tool_dir' - defined in $(cb_dir)/o_path.mk
ifdef cb_checking
get_tool_execs = $(patsubst %,$(get_tool_dir)/%$(tool_exe_suffix),$(call cb_check_vpaths_r,$2))
else
get_tool_execs = $(patsubst %,$(get_tool_dir)/%$(tool_exe_suffix),$2)
endif

# $1 - targets for which files/directories are needed - must be simple paths relative to virtual $(out_dir), e.g.: bin/test.exe
need_built_files_r = $(need_built_files)$1
need_tool_files_r  = $(need_tool_files)$1
need_built_dirs_r  = $(need_built_dirs)$1
need_tool_dirs_r   = $(need_tool_dirs)$1
need_tool_execs_r  = $(need_tool_execs)$1

# makefile parsing first phase variables
# note: 'o_ns', 'o_path' and 'get_tool_dir' change their values in "tool" mode
cb_first_phase_vars += cb_need_files need_built_files1 need_tool_files1 need_built_files_a need_built_files need_tool_files \
  cb_need_built_dirs cb_need_tool_dirs cb_need_dirs3 cb_need_dirs2 need_built_dirs2 need_tool_dirs2 cb_need_dirs1 need_built_dirs \
  need_tool_dirs need_built_dirs1 need_tool_dirs1 need_tool_execs get_tool_execs need_built_files_r need_tool_files_r need_built_dirs_r \
  need_tool_dirs_r need_tool_execs_r

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: need
$(call set_global,cb_need_files need_built_files1 need_tool_files1 need_built_files_a need_built_files need_tool_files \
  cb_need_built_dirs cb_need_tool_dirs cb_need_dirs3 cb_need_dirs2 need_built_dirs2 need_tool_dirs2 cb_need_dirs1 need_built_dirs \
  need_tool_dirs need_built_dirs1 need_tool_dirs1 tool_exe_suffix need_tool_execs get_tool_execs need_built_files_r need_tool_files_r \
  need_built_dirs_r need_tool_dirs_r need_tool_execs_r,need)
