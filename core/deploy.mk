
# associate built directories with given tag file (which is updated just after update of the directories) - to be able to create
#  rules for copying built directories specifying them only by their virtual path, without need for specifying tag file
# $1 - tag file   - simple path relative to virtual $(out_dir),  e.g.: gen1/tag1.tag
# $2 - built dirs - simple paths relative to virtual $(out_dir), e.g.: gen2/dir1 gen3/dir2/dir3
# note: it is assumed that directories $2 are built in private namespace of the tag file $1
ifndef cb_checking
assoc_dirs = $(foreach d,$2,$(eval $$d.^d := $$1))
else
# checks:
#  1) path $1 must be simple and relative
#  2) path $1 must not be registered as a name of built directory
#  3) if $1 is empty, $2 must also be empty
#  4) paths $2 must be simple and relative
#  5) must not try to re-associate already associated built directory with another tag file
#  6) must not try to register tag file as a built directory
cb_tag_files:=
# note: do not trace access to 'cb_tag_files' variable - it is incremented via operator +=
assoc_dirs = $(if $(cb_check_virt_path_r),$(if $(filter-out undefined,$(origin $1.^d)),$(error \
  conflict: path '$1' is already registered as a name of built directory),$(eval \
  cb_tag_files += $$1$(newline)$(call set_global1,cb_tag_files))),$(if $2,$(error \
  tag file is empty!)))$(foreach d,$(call cb_check_virt_paths_r,$2),$(if \
  $(filter-out undefined,$(origin $d.^d)),$(if $(call iseq,$($d.^d),$1),,$(error \
  built directory '$d' is already associated with tag file '$($d.^d)')),$(if $(filter $d,$(cb_tag_files)),$(error \
  conflict: tag file '$d' is passed as a path to built directory),$(eval $$d.^d := $$1))))
endif

ifdef priv_prefix

# ---------- deploying files ------------------

# deploy built files - copy them from private modules build directories to "public" place
# $1 - built files,    e.g.: /build/pp/bin-tool.exe/bin/tool.exe /build/pp/gen-tool.cfg/gen/tool.cfg
# $2 - deployed paths, e.g.: /build/bin/tool.exe /build/gen/tool.cfg
# note: assume deployed files are needed _only_ by $(cb_target_makefile)-, so:
#  - set makefile info (target-specific variables) by 'set_makefile_info_r' macro only for the $(cb_target_makefile)-,
#   assume that this makefile info will be properly inherited by targets of copying rules
define cb_deploy_files
cb_needed_dirs += $(patsubst $(cb_build)/%/,%,$(dir $2))
$(subst |, | ,$(subst ||,: ,$(subst / ,$(newline),$(join $(join $(2:=||),$(1:=|)),$(dir $2)) )))$(call \
  set_makefile_info_r,$(cb_target_makefile)-): $2
$(call suppress_targets_r,$2):
	$$(call suppress,COPY,$$@)$$(call copy_files,$$<,$$@)
endef

# deploy built tools - copy them from private modules build directories to "public" place
# $1 - built files,    e.g.: /build/pp/bin-tool.exe/bin/tool.exe /build/pp/gen-tool.cfg/gen/tool.cfg
# $2 - deployed paths, e.g.: /build/bin/tool.exe /build/gen/tool.cfg
# note: deployed tools are may be required for building other targets, so:
#  - set makefile info (target-specific variables) by 'set_makefile_info_r' macro for each deployed tool
define cb_deploy_tool_files
cb_needed_dirs += $(patsubst $(cb_build)/%/,%,$(dir $2))
$(subst |, | ,$(subst ||,: ,$(subst / ,$(newline),$(join $(join $(2:=||),$(1:=|)),$(dir $2)) )))$(cb_target_makefile)-: $2
$(call set_makefile_info_r,$(call suppress_targets_r,$2)):
	$$(call suppress,COPY,$$@)$$(call copy_files,$$<,$$@)
endef

# $1 - deployed files - simple paths relative to virtual $(out_dir), e.g.: bin/tool.exe gen/tool.cfg
# $2 - built files, e.g.: /build/pp/bin-tool.exe/bin/tool.exe /build/pp/gen-tool.cfg/gen/tool.cfg
deploy_files1 = $(if $(is_tool_mode),$(call \
  cb_deploy_tool_files,$2,$(addprefix $(cb_build)/$(cb_tools_subdir)/,$1)),$(call \
  cb_deploy_files,$2,$(addprefix $(cb_build)/$(target_triplet)/,$1)))

# protect new value of 'cb_needed_dirs', do not trace calls to it because it's incremented
ifdef cb_checking
$(eval deploy_files1 = $(value deploy_files1)$(newline)$(call set_global1,cb_needed_dirs))
endif

# deploy files - copy them from private modules build directories to "public" place
# $1 - deployed files - simple paths relative to virtual $(out_dir), e.g.: bin/tool.exe gen/tool.cfg
deploy_files = $(eval $(call deploy_files1,$1,$(o_path)))

# ---------- deploying directories ------------

# generate rules for copying directories
# $1 - source dirs,      e.g.: /build/s1 /build/s2
# $2 - destination dirs, e.g.: /build/d1 /build/d2
# result:
#  $(call suppress_more,COPY,/build/d1)$(call copy_all,/build/s1,/build/d1)
#  $(call suppress_more,COPY,/build/d2)$(call copy_all,/build/s2,/build/d2)
cb_gen_dir_copying_rules = $(subst $$(space), ,$(subst $(space),$(newline),$(join \
  $(patsubst %,$$(call$$(space)suppress_more,COPY,%),$2),$(patsubst %,$$(call$$(space)copy_all,%),$(join $(1:=$(comma)),$2)))))

# deploy built directories - copy them from tag file's private build directory to "public" place
# $1 - built tag file, e.g.: /build/pp/gen1-tag1.tag/gen1/tag1.tag
# $2 - deployed path,  e.g.: /build/gen1/tag1.tag
# $3 - built dirs,     e.g.: /build/pp/gen1-tag1.tag/gen2/dir1 /build/pp/gen1-tag1.tag/gen3/dir2/dir3
# $4 - deployed dirs,  e.g.: /build/gen2/dir1 /build/gen3/dir2/dir3
define cb_deploy_dirs
cb_needed_dirs += $(patsubst $(cb_build)/%/,%,$(dir $2)) $(patsubst $(cb_build)/%,%,$4)
$(cb_target_makefile)-: $2
$(call set_makefile_info_r,$(call suppress_targets_r,$2)): $1 | $(patsubst %/,%,$(dir $2)) $4
	$$(call cb_gen_dir_copying_rules,$3,$4)
	$$(call suppress,COPY,$$@)$$(call copy_files,$$<,$$@)
endef

# $1 - deployed tag file - simple path relative to virtual $(out_dir),  e.g.: gen1/tag1.tag
# $2 - deployed dirs     - simple paths relative to virtual $(out_dir), e.g.: gen2/dir1 gen3/dir2/dir3
# $3 - destination directory: $(cb_build)/$(if $(is_tool_mode),$(cb_tools_subdir),$(target_triplet))
# note: it is assumed that directories $2 are built in private namespace of the tag file $1
deploy_dirs1 = $(call cb_deploy_dirs,$(o_path),$(addprefix $3/,$1),$(addprefix $(o_dir)/,$2),$(addprefix $3/,$2))

# protect new value of 'cb_needed_dirs', do not trace calls to it because it's incremented
ifdef cb_checking
$(eval deploy_dirs1 = $(value deploy_dirs1)$(newline)$(call set_global1,cb_needed_dirs))
endif

# 1) associate each deployed directory with given tag file (which is updated just after update of the directories)
# 2) deploy associated built dirs - copy them from tag file's private build directory to "public" place
# $1 - deployed tag file - simple path relative to virtual $(out_dir),  e.g.: gen1/tag1.tag
# $2 - deployed dirs     - simple paths relative to virtual $(out_dir), e.g.: gen2/dir1 gen3/dir2/dir3
deploy_dirs = $(assoc_dirs)$(eval $(call deploy_dirs1,$1,$2,$(cb_build)/$(if $(is_tool_mode),$(cb_tools_subdir),$(target_triplet))))

else # !priv_prefix

# files are built directly in "public" place, no need to copy there them from private modules build directories
ifndef cb_checking
deploy_files:=
else
# check parameters:
# $1 - deployed files - simple paths relative to virtual $(out_dir), e.g.: bin/tool.exe gen/tool.cfg
deploy_files = $(cb_check_virt_paths)
endif

# directories are built directly in "public" place, no need to copy there them from private modules build directories, so
#  - just associate each deployed directory with given tag file (which is updated just after update of the directories)
# $1 - deployed tag file - simple path relative to virtual $(out_dir),  e.g.: gen1/tag1.tag
# $2 - deployed dirs     - simple paths relative to virtual $(out_dir), e.g.: gen2/dir1 gen3/dir2/dir3
deploy_dirs = $(assoc_dirs)

endif # !priv_prefix

# makefile parsing first phase variables
cb_first_phase_vars += assoc_dirs cb_tag_files cb_deploy_files cb_deploy_tool_files deploy_files1 deploy_files cb_deploy_dirs \
  deploy_dirs1 deploy_dirs

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: assoc_dirs
$(call set_global,assoc_dirs,assoc_dirs)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: do not trace access to 'cb_tag_files' variable - it is incremented via operator +=
$(call set_global,cb_tag_files)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: deploy
$(call set_global,cb_deploy_files cb_deploy_tool_files deploy_files1 deploy_files cb_gen_dir_copying_rules cb_deploy_dirs \
  deploy_dirs1 deploy_dirs,deploy)
