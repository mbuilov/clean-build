
ifdef cb_checking

# ---------- deploying files ------------------

# deploy built files - copy them from private modules build directories to "public" place
# $1 - built files,    e.g.: /build/pp/bin-tool.exe/bin/tool.exe /build/pp/gen-tool.cfg/gen/tool.cfg
# $2 - deployed paths, e.g.: /build/bin/tool.exe /build/gen/tool.cfg
# note: assume deployed files are needed only by $(cb_target_makefile)-, so:
#  1) set makefile info (target-specific variables) by 'set_makefile_info_r' macro only for the $(cb_target_makefile)-,
#   assume that this makefile info will be properly inherited by targets of copying rules
#  2) create all needed directories prior copying any of deployed files
define cb_deploy_files
cb_needed_dirs += $(patsubst $(cb_build)/%/,%,$(dir $2))
$(subst |,: ,$(subst $(space),$(newline),$(join $(2:=|),$1)))
$(call set_makefile_info_r,$(cb_target_makefile)-): $2 | $(patsubst %/,%,$(dir $2))
$(call suppress_targets_r,$2):
	$$(call suppress,COPY,$$@)$$(call copy_files,$$<,$$@)
endef

# deploy built tools - copy them from private modules build directories to "public" place
# $1 - built files,    e.g.: /build/pp/bin-tool.exe/bin/tool.exe /build/pp/gen-tool.cfg/gen/tool.cfg
# $2 - deployed paths, e.g.: /build/bin/tool.exe /build/gen/tool.cfg
# note: deployed tools are may be required for building other targets, so:
#  1) set makefile info (target-specific variables) by 'set_makefile_info_r' macro for each deployed tool
#  2) create needed directory prior copying for each deployed tool
define cb_deploy_tool_files
cb_needed_dirs += $(patsubst $(cb_build)/%/,%,$(dir $2))
$(subst |, | ,$(subst ||,: ,$(subst / ,$(newline),$(join $(join $(2:=||),$(1:=|)),$(dir $2)) )))$(cb_target_makefile)-: $2
$(call set_makefile_info_r,$(call suppress_targets_r,$2)):
	$$(call suppress,COPY,$$@)$$(call copy_files,$$<,$$@)
endef

# $1 - deployed files - simple paths relative to virtual $(out_dir), e.g.: bin/tool.exe gen/tool.cfg
deploy_files1 = $(if $(is_tool_mode),$(call \
  cb_deploy_tool_files,$(o_path),$(addprefix $(cb_build)/$(cb_tools_subdir)/,$1)),$(call \
  cb_deploy_files,$(o_path),$(addprefix $(cb_build)/$(target_triplet)/,$1)))

# deploy files - copy them from target's private build directory to "public" place
# $1 - deployed files - simple paths relative to virtual $(out_dir), e.g.: bin/tool.exe gen/tool.cfg
deploy_files = $(eval $(deploy_files1))

# ---------- deploying directories ------------

# generate rules for copying directories
# $1 - source dirs,      e.g.: s1 s2
# $2 - destination dirs, e.g.: d1 d2
# result:
#  $(call suppress_more,COPY,d1)$(call copy_all,s1,d1)
#  $(call suppress_more,COPY,d2)$(call copy_all,s2,d2)
cb_gen_dir_copying_rules = $(subst $$(space), ,$(subst $(space),$(newline),$(join \
  $(patsubst %,$$(call$$(space)suppress_more,COPY,%),$2),$(patsubst %,$$(call$$(space)copy_all,%),$(join $(1:=$(comma)),$2)))))

# deploy built directories - copy them from private modules build directories to "public" place
# $1 - built tag file, e.g.: /build/pp/gen1-tag1.tag/gen1/tag1.tag
# $2 - deployed path,  e.g.: /build/gen1/tag1.tag
# $3 - built dirs,     e.g.: /build/pp/gen1-tag1.tag/gen2/dir1 /build/pp/gen1-tag1.tag/gen3/dir2/dir3
# $4 - deployed dirs,  e.g.: /build/gen2/dir1 /build/gen3/dir2/dir3
define cb_deploy_dirs
cb_needed_dirs += $(patsubst $(cb_build)/%,%,$(patsubst %/,%,$(dir $2)) $4)
$(cb_target_makefile)-: $2
$(call set_makefile_info_r,$(call suppress_targets_r,$2)): $1 | $(patsubst %/,%,$(dir $2)) $4
	$$(call cb_gen_dir_copying_rules,$3,$4)
	$$(call suppress,COPY,$$@)$$(call copy_files,$$<,$$@)
endef

# $1 - deployed tag file - simple path relative to virtual $(out_dir),  e.g.: gen1/tag1.tag
# $2 - deployed dirs     - simple paths relative to virtual $(out_dir), e.g.: gen2/dir1 gen3/dir2/dir3
deploy_dirs1 = $(foreach d,$2,$d.^d := $$1$(newline))$(call cb_deploy_dirs,$(o_path),$(addprefix \
  $(cb_build)/$(if $(is_tool_mode),$(cb_tools_subdir),$(target_triplet))/,$1),$(addprefix $(o_dir)/,$2),$(addprefix \
  $(cb_build)/$(if $(is_tool_mode),$(cb_tools_subdir),$(target_triplet))/,$2))

# 1) deploy dirs - copy them from target's private build directory to "public" place
# 2) associate each deployed directory with given tag file (which is updated just after update of the directories)
# $1 - deployed tag file - simple path relative to virtual $(out_dir),  e.g.: gen1/tag1.tag
# $2 - deployed dirs     - simple paths relative to virtual $(out_dir), e.g.: gen2/dir1 gen3/dir2/dir3
deploy_dirs = $(foreach d,$(call cb_check_virt_paths_r,$2),$(if $(filter-out undefined,$(origin $d.^d)),$(error \
  generated directory '$d' is already associated with tag file '$($d.^d)')))$(eval $(deploy_dirs1))

else # !cb_checking

# files are built directly in "public" place, no need to copy there files from private modules build directories
deploy_files:=

# associate each deployed directory with given tag file (which is updated just after update of the directories)
# $1 - deployed tag file - simple path relative to virtual $(out_dir),  e.g.: gen1/tag1.tag
# $2 - deployed dirs     - simple paths relative to virtual $(out_dir), e.g.: gen2/dir1 gen3/dir2/dir3
deploy_dirs = $(foreach d,$2,$(eval $$d.^d := $$1))

endif # !cb_checking

# makefile parsing first phase variables
cb_first_phase_vars += cb_deploy_files cb_deploy_tool_files deploy_files1 deploy_files cb_deploy_dirs deploy_dirs1 deploy_dirs

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: deploy
$(call set_global,cb_deploy_files cb_deploy_tool_files deploy_files1 deploy_files cb_gen_dir_copying_rules cb_deploy_dirs \
  deploy_dirs1 deploy_dirs,deploy)
