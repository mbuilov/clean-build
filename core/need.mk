
ifdef priv_prefix

# ---------- needed files ---------------------

# $1 - absolute path to the target for which built files are needed
# $2 - absolute paths to needed files
# $3 - absolute paths to destination files
# note: a rule for creating target $1 may be defined elsewhere, so do not set current makefile info for it here,
#  instead call 'set_makefile_info_r' for each copied file
define cb_need_files
cb_needed_dirs += $(patsubst $(cb_build)/%/,%,$(dir $3))
$(subst |, | ,$(subst ||,: ,$(subst / ,$(newline),$(join $(join $(3:=||),$(2:=|)),$(dir $3)) )))$1: $3
$(call set_makefile_info_r,$(call suppress_targets_r,$3)):
	$$(call suppress,COPY,$$@)$$(call copy_files,$$<,$$@)
endef

# protect new value of 'cb_needed_dirs', do not trace calls to it because it's incremented
ifdef cb_checking
$(call define_append,cb_need_files,$(newline)$(call set_global1,cb_needed_dirs))
endif

# define rules for copying needed built files to target's private namespace
# $1 - the target for which the files are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file1.txt gen/file2.txt
# note: built files are not deployed to "public" place by default (only via explicit 'deploy_files'), copy them from private places
ifdef cb_checking
need_built_files = $(cb_check_virt_path)$(eval $(call cb_need_files,$(o_path),$(call o_path,$2),$(addprefix $(o_dir)/,$2)))
else
need_built_files = $(eval $(call cb_need_files,$(o_path),$(call o_path,$2),$(addprefix $(o_dir)/,$2)))
endif

# define rules for copying needed (previously deployed via 'deploy_files') tool files to target's private namespace
# $1 - the target for which the files are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - tool files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file1.txt gen/file2.txt
# note: tool files should be deployed to "public" place, so copy them from there
ifdef cb_checking
need_tool_files = $(cb_check_virt_path)$(eval $(call cb_need_files,$(o_path),$(addprefix \
  $(cb_build)/$(cb_tools_subdir)/,$(call cb_check_virt_paths_r,$2)),$(addprefix $(o_dir)/,$2)))
else
need_tool_files = $(eval $(call cb_need_files,$(o_path),$(addprefix \
  $(cb_build)/$(cb_tools_subdir)/,$2),$(addprefix $(o_dir)/,$2)))
endif

# ---------- needed directories ---------------

# copy built dirs from tag file's private namespace directory
# $1 - needed tag file, e.g.: gen/g1.tag
# $2 - absolute path to namespace directory of the target for which the dirs are needed, e.g.: /build/pp/bin-test.exe/
# $3 - needed directories, e.g.: gen/g1
define cb_need_built_dirs
$(call set_makefile_info_r,$(call suppress_targets_r,$2$1)): $(o_path) | $(patsubst %/,%,$(dir $2$1)) $(addprefix $2,$3)
	$$(call cb_gen_dir_copying_rules,$(addprefix $(o_dir)/,$3),$(addprefix $2,$3))
	$$(call suppress,COPY,$$@)$$(call copy_files,$$<,$$@)
endef

# copy built dirs from "public" place
..................
# $1 - needed tag file, e.g.: gen/g1.tag
# $2 - absolute path to namespace directory of the target for which the dirs are needed, e.g.: /build/pp/bin-test.exe/
# $3 - needed directories, e.g.: gen/g1
define cb_need_built_dirs
$(call set_makefile_info_r,$(call suppress_targets_r,$2$1)): $(o_path) | $(patsubst %/,%,$(dir $2$1)) $(addprefix $2,$3)
	$$(call cb_gen_dir_copying_rules,$(addprefix $(o_dir)/,$3),$(addprefix $2,$3))
	$$(call suppress,COPY,$$@)$$(call copy_files,$$<,$$@)
endef

# $1 - absolute path to the target for which the dirs are needed,                        e.g.: /build/pp/bin-test.exe/bin/test.exe
# $2 - absolute path to namespace directory of the target for which the dirs are needed, e.g.: /build/pp/bin-test.exe/
# $3 - needed directories, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1 gen/gen2/g3
# $4 - 'cb_need_built_dirs'/'cb_need_tool_dirs'
# $5 - sorted list of needed tag files, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1.tag gen/gen2/g3.tag
# $6 - join of tag files and needed directories, e.g.: gen/g1.tag|gen/g1 gen/gen2/g3.tag|gen/gen2/g3
define cb_need_dirs2
cb_needed_dirs += $(patsubst $(cb_build)/%/,%,$(dir $(addprefix $2,$5))) $(addprefix $(patsubst $(cb_build)/%,%,$2),$3)
$(foreach t,$5,$(call $3,$t,$2,$(patsubst $t|%,%,$(filter $t|%,$6)))$(newline))$1: $(addprefix $2,$5)
endef

# protect new value of 'cb_needed_dirs', do not trace calls to it because it's incremented
ifdef cb_checking
$(call define_append,cb_need_dirs2,$(newline)$(call set_global1,cb_needed_dirs))
endif

# $1 - the target for which the dirs are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed directories, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1 gen/gen2/g3
# $3 - 'cb_need_built_dirs'/'cb_need_tool_dirs'
# $4 - needed tag files, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1.tag gen/gen2/g3.tag
ifdef cb_checking
cb_need_dirs1 = $(call cb_need_dirs2,$(o_path),$(o_dir)/,$2,$3,$(call cb_check_virt_paths_r,$(sort $4)),$(join $(4:=|),$2))
else
cb_need_dirs1 = $(call cb_need_dirs2,$(o_path),$(o_dir)/,$2,$3,$(sort $4),$(join $(4:=|),$2))
endif

# $1 - the target for which the dirs are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed directories, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1 gen/gen2/g3
# $3 - 'cb_need_built_dirs'/'cb_need_tool_dirs'
ifdef cb_checking
cb_need_dirs = $(eval $(call cb_need_dirs1,$(cb_check_virt_path_r),$(call cb_check_virt_paths_r,$2),$3,$(foreach d,$2,$($d.^d))))
else
cb_need_dirs = $(eval $(call cb_need_dirs1,$1,$2,$3,$(foreach d,$2,$($d.^d))))
endif

# define rules for copying needed (previously associated via 'assoc_dirs'/'deploy_dirs') built directories to target's private namespace
# $1 - the target for which the dirs are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed directories, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1 gen/gen2/g3
# note: built directories are not deployed to "public" place by default (only via explicit 'deploy_dirs'), copy them from private places
# note: multiple directories may be associated with a single tag file
need_built_dirs = $(call cb_need_dirs,$1,$2,cb_need_built_dirs)

# define rules for copying needed (previously deployed via 'deploy_dirs') tool directories to target's private namespace
# $1 - the target for which the dirs are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed directories, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1 gen/gen2/g3
# note: tool directories should be deployed to "public" place, so copy them from there
# note: multiple directories may be associated with a single tag file
need_tool_dirs = $(call cb_need_dirs,$1,$2,cb_need_tool_dirs)












# $1 - absolute path to the target for which the dirs are needed
# $2 - absolute paths to needed tag files
# $3 - absolute paths to destination tag files
# $4 - absolute paths to needed dirs
# $5 - absolute paths to destination dirs
# note: assume built dirs are needed in target's private namespace only by the target, so
#  1) create all needed directories prior copying
# note: a rule for creating target $1 may be defined elsewhere, so do not set current makefile info for it here,
#  instead call 'set_makefile_info_r' for each copied file
# note: 'cb_gen_dir_copying_rules' - defined in $(cb_build)/core/deploy.mk
define cb_need_built_dirs
cb_needed_dirs += $(patsubst $(cb_build)/%/,%,$(dir $3)) $(patsubst $(cb_build)/%,%,$5)
$1: $3 | $(patsubst %/,%,$(dir $3)) $5
$(subst |,: ,$(subst $(space),$(newline),$(join $(3:=|),$2)))
$(call set_makefile_info_r,$(call suppress_targets_r,$3)):
	$$(call cb_gen_dir_copying_rules,$$(src_dirs),$$(dst_dirs))
	$$(call suppress,COPY,$$@)$$(call copy_files,$$<,$$@)
$(foreach d,$3,
$d: src_dirs := $(patsubst $d|%,%,$(filter $d|%,$6))
$d: dst_dirs := $(patsubst $d|%,%,$(filter $d|%,$7)))

endef

# $1 - the target for which the dirs are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed directories, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1 gen/gen2/g3
# $3 - needed tag files, must be simple paths relative to virtual $(out_dir), e.g.: gen/g1.tag gen/gen2/g3.tag
need_built_dirs1 = $(call cb_need_built_dirs,$(o_path),$(call o_path,$3),$(addprefix \
  $(o_dir)/,$3),$(call o_path,$2),$(addprefix $(o_dir)/,$2))


# $1 - absolute path to the target for which the dirs are needed
# $2 - absolute paths to needed dirs
# $3 - absolute paths to destination dirs
# $4 - absolute paths to destination tag files
# $5 - unique absolute paths to needed tag files
# $6 - unique absolute paths to destination tag files
define cb_need_built_dirs
cb_needed_dirs += $(patsubst $(cb_build)/%/,%,$(dir $6)) $(patsubst $(cb_build)/%,%,$3)
$(subst |, | ,$(subst ||,: ,$(subst / ,$(newline),$(join $(join $(6:=||),$(5:=|)),$(dir $6)) )))$1: $6



$(filter $6,f1|d1 f2|d2)

$6: $5 | $(dir $6) $(join $(4:=|),$3)

$(subst |, | ,$(subst ||,: ,$(subst / ,$(newline),$(join $(join $(2:=||),$(1:=|)),$(dir $2)) )))$(cb_target_makefile)-: $2

$1: $6 | $(patsubst %/,%,$(dir $6)) $3
$(subst |,: ,$(subst $(space),$(newline),$(join $(3:=|),$2)))
$(call set_makefile_info_r,$(call suppress_targets_r,$3)):
	$$(call cb_gen_dir_copying_rules,$$(src_dirs),$$(dst_dirs))
	$$(call suppress,COPY,$$@)$$(call copy_files,$$<,$$@)
$(foreach d,$3,
$d: src_dirs := $(patsubst $d|%,%,$(filter $d|%,$6))
$d: dst_dirs := $(patsubst $d|%,%,$(filter $d|%,$7)))
endef

# $1 - absolute path to the target for which the dirs are needed
# $2 - absolute paths to destination dirs
# $3 - unique tag files
# $4 - absolute paths to needed tag files
...
# $2 - absolute paths to needed dirs
# $4 - absolute paths to destination tag files
need_built_dirs2 = $(call cb_need_built_dirs,$1,$2,$3,$4,$(call o_path,$5),$(addprefix $(o_dir)/,$5))

# note: it is assumed that needed directories are built in private namespaces of the tag files







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

else # !priv_prefix

# files are built directly in "public" place, no need to copy them from private places

# define dependency on needed built files for the target
# $1 - the target for which the files are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - needed files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file1.txt gen/file2.txt
need_built_files = $(eval $(o_path): $(call o_path,$2))

# define dependency on needed tool files for the target
# $1 - the target for which the files are needed - must be a simple path relative to virtual $(out_dir), e.g.: bin/test.exe
# $2 - tool files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file1.txt gen/file2.txt
need_tool_files = $(eval $(o_path): $(addprefix $(cb_build)/$(cb_tools_subdir)/,$2))



endif # !priv_prefix

# executable file suffix of the generated tools
tool_exe_suffix := $(if $(filter WIN% CYGWIN% MINGW%,$(CBLD_OS)),.exe)

# simplified version of 'need_tool_files'
# $1 - the target for which the tools are needed - must be a simple path relative to virtual $(out_dir), e.g.: gen/file.txt
# $2 - tool executable files, must be simple paths relative to virtual $(out_dir) without extension, e.g.: bin/tool1 bin/tool2
need_tool_exe = $(call need_tool_files,$1,$(addsuffix $(tool_exe_suffix),$2))

# makefile parsing first phase variables
# note: 'o_dir' and 'o_path' change their values in "tool" mode
cb_first_phase_vars += cb_need_files need_built_files need_tool_files cb_need_built_dirs need_built_dirs1 \
  need_built_dirs need_tool_dirs1 need_tool_dirs need_tool_exe

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: need
$(call set_global,cb_need_files need_built_files need_tool_files cb_need_built_dirs \
  need_built_dirs1 need_built_dirs need_tool_dirs1 need_tool_dirs tool_exe_suffix need_tool_exe,need)
