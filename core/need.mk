
ifdef cb_checking

# $1 - absolute path to the target for which the files are needed
# $2 - absolute paths to needed files
# $3 - absolute paths to destination files
# note: assume built files are needed only by the target, so
#  1) create all needed directories prior copying
define cb_need_built_files
cb_needed_dirs += $(patsubst $(cb_build)/%/,%,$(dir $3))
$1: $3 | $(patsubst %/,%,$(dir $3))
$(subst |,: ,$(subst $(space),$(newline),$(join $(3:=|),$2)))
$(call set_makefile_info_r,$(call suppress_targets_r,$3)):
	$$(call suppress,COPY,$$@)$$(call copy_files,$$<,$$@)
endef

# define rules for copying needed built files for the target
# $1 - the target for which the files are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file1.txt gen/file2.txt
# note: built files generally are not deployed to "public" place, copy them from private places
need_built_files = $(eval $(call cb_need_built_files,$(o_path),$(call o_path,$2),$(addprefix $(o_dir)/,$2)))

# define rules for copying needed tool files for the target
# $1 - the target for which the files are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - tool files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file1.txt gen/file2.txt
# note: tool files should be deployed to "public" place, so copy them from there
need_tool_files = $(eval $(call cb_need_built_files,$(o_path),$(addprefix \
  $(cb_build)/$(cb_tools_subdir)/,$(call cb_check_virt_paths_r,$2)),$(addprefix $(o_dir)/,$2)))

# $1 - absolute path to the target for which the dirs are needed
# $2 - absolute paths to needed tag files
# $3 - absolute paths to destination tag files
# $4 - absolute paths to needed dirs
# $5 - absolute paths to destination dirs
define cb_need_built_dirs
cb_needed_dirs += $(patsubst $(cb_build)/%,%,$(patsubst %/,%,$(dir $3)) $5)
$1: $3 | $(patsubst %/,%,$(dir $3)) $5
$(subst |,: ,$(subst $(space),$(newline),$(join $(3:=|),$2)))
$(call set_makefile_info_r,$(call suppress_targets_r,$3)):
	$$(call cb_gen_dir_copying_rules,$4,$5)
	$$(call suppress,COPY,$$@)$$(call copy_files,$$<,$$@)
endef

# $1 - the target for which the dirs are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed directories, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1 gen/gen2/g3
# $3 - needed tag files, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1.tag gen/gen2/g3.tag
need_built_dirs1 = $(call cb_need_built_dirs,$(o_path),$(call o_path,$3),$(addprefix \
  $(o_dir)/,$3),$(call o_path,$2),$(addprefix $(o_dir)/,$2))

# define rules for copying needed built directories for the target
# $1 - the target for which the dirs are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed directories, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1 gen/gen2/g3
# note: built directories generally are not deployed to "public" place, copy them from private places
need_built_dirs = $(eval $(call need_built_dirs1,$1,$2,$(foreach d,$2,$($d.^d))))

# $1 - the target for which the dirs are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed directories, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1 gen/gen2/g3
# $3 - needed tag files, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1.tag gen/gen2/g3.tag
need_tool_dirs1 = $(call cb_need_built_dirs,$(o_path),$(addprefix $(cb_build)/$(cb_tools_subdir)/,$(call \
  cb_check_virt_paths_r,$3)),$(addprefix $(o_dir)/,$3),$(addprefix $(cb_build)/$(cb_tools_subdir)/,$(call \
  cb_check_virt_paths_r,$2)),$(addprefix $(o_dir)/,$2))

# define rules for copying needed tool directories for the target
# $1 - the target for which the dirs are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed directories, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1 gen/gen2/g3
# note: tool directories should be deployed to "public" place, so copy them from there
need_tool_dirs = $(eval $(call need_tool_dirs1,$1,$2,$(foreach d,$2,$($d.^d))))

else # !cb_checking

# files are built directly in "public" place, no need to copy them from private places

# define dependency on needed built files for the target
# $1 - the target for which the files are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file1.txt gen/file2.txt
need_built_files = $(eval $(o_path): $(call o_path,$2))

# define dependency on needed tool files for the target
# $1 - the target for which the files are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - tool files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file1.txt gen/file2.txt
need_tool_files = $(eval $(o_path): $(addprefix $(cb_build)/$(cb_tools_subdir)/,$2))



endif # !cb_checking

# executable file suffix of the generated tools
tool_exe_suffix := $(if $(filter WIN% CYGWIN% MINGW%,$(CBLD_OS)),.exe)

# simplified version of 'need_tool_files'
# $1 - the target for which the tools are needed - must be a simple path relative to virtual $(out_dir), e.g.: gen/file.txt
# $2 - tool executable files, must be simple paths relative to virtual $(out_dir) without extension, e.g.: bin/tool1 bin/tool2
need_tool_exe = $(call need_tool_files,$1,$(addsuffix $(tool_exe_suffix),$2))

# makefile parsing first phase variables
# note: 'o_dir' and 'o_path' change their values in "tool" mode
cb_first_phase_vars += cb_need_built_files need_built_files need_tool_files cb_need_built_dirs need_built_dirs1 \
  need_built_dirs need_tool_dirs1 need_tool_dirs need_tool_exe

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: need
$(call set_global,cb_need_built_files need_built_files need_tool_files cb_need_built_dirs \
  need_built_dirs1 need_built_dirs need_tool_dirs1 need_tool_dirs tool_exe_suffix need_tool_exe,need)
