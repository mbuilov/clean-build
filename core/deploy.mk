#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define macros:
#  'assoc_dirs'   - associate built directories with given tag file
#  'deploy_files' - deploy files - link them from private modules build directories to "public" place
#  'deploy_dirs'  - associate each deployed directory with given tag file and
#                   deploy dirs - link them from tag file's private build directory to "public" place

ifndef cb_checking

# associate built directories with given tag file (which is updated just after update of the directories) - to be able to create
#  rules for linking built directories specifying them only by their virtual path, without need for specifying tag file
# $1 - tag file   - simple path relative to virtual $(out_dir),  e.g.: gen1/tag1.tag
# $2 - built dirs - simple paths relative to virtual $(out_dir), e.g.: gen2/dir1 gen3/dir2/dir3
# note: it is assumed that directories $2 are built in private namespace of the tag file $1
assoc_dirs = $(if $(is_tool_mode),$(foreach \
  d,$2,$(eval $$d/.^d := $$1)),$(foreach \
  d,$2,$(eval $$d.^d := $$1)))

else # cb_checking

# note: these lists contain simple relative paths like 1/2/3
cb_tag_files:=
cb_tag_files_t:=
# note: 'cb_assoc_dirs' and 'cb_assoc_dirs_t' lists will not contain duplicates
cb_assoc_dirs:=
cb_assoc_dirs_t:=

# checks:
#  1) path $1 must be simple and relative
#  2) path $1 must not be registered as a name of built directory
#  3) if $1 is empty, $2 must also be empty
#  4) paths $2 must be simple and relative
#  5) must not try to re-associate already associated built directory with another tag file
#  6) must not try to register tag file as a built directory
#  7) must not try to build parent directories of other built directories, e.g. cannot build '1/2' if '1/2/3' is built
#  8) $(cb_dir)/core/all.mk also checks that 'cb_needed_dirs' list does not contain any of $(cb_assoc_dirs) or $(cb_assoc_dirs_t) or
#    their child sub-directories, except directories built in private namespaces of associated tag files

# $1 - tag file   - simple path relative to virtual $(out_dir),  e.g.: gen1/tag1.tag
# $2 - built dirs - simple paths relative to virtual $(out_dir), e.g.: gen2/dir1 gen3/dir2/dir3
# $3 - 'cb_tag_files'/'cb_tag_files_t'
# $4 - 'cb_assoc_dirs'/'cb_assoc_dirs_t'
# $5 - /.^d or .^d
# note: do not trace access to 'cb_tag_files'/'cb_assoc_dirs' variables - they are incremented via operator +=
assoc_dirs1 = $(if $(cb_check_vpath_r),$(if $(filter-out undefined,$(origin $1$5)),$(error \
  conflict: path '$1' is already registered as a name of built directory),$(eval \
  $$3 += $$1$(newline)$(call set_global1,$3))),$(if $2,$(error \
  tag file is empty!)))$(foreach d,$(call cb_check_vpaths_r,$2),$(if \
  $(filter-out undefined,$(origin $d$5)),$(if $(call iseq,$($d$5),$1),,$(error \
  built directory '$d' is already associated with another tag file '$($d$5)')),$(if $(filter $d,$($3)),$(error \
  conflict: tag file '$d' is passed as a path to built directory),$(if $(filter $d/%,$($4)),$(error \
  building parent directory '$d' of other built directories: '$(filter $d/%,$($4))'),$(eval \
  $$d$$5 := $$1$(newline)$$4 += $$d)))))$(call set_global,$4)

# associate built directories with given tag file (which is updated just after update of the directories) - to be able to create
#  rules for linking built directories specifying them only by their virtual path, without need for specifying tag file
# $1 - tag file   - simple path relative to virtual $(out_dir),  e.g.: gen1/tag1.tag
# $2 - built dirs - simple paths relative to virtual $(out_dir), e.g.: gen2/dir1 gen3/dir2/dir3
# note: it is assumed that directories $2 are built in private namespace of the tag file $1
assoc_dirs = $(if $(is_tool_mode),$(call \
  assoc_dirs1,$1,$2,cb_tag_files_t,cb_assoc_dirs_t,/.^d),$(call \
  assoc_dirs1,$1,$2,cb_tag_files,cb_assoc_dirs,.^d))

endif # cb_checking

ifdef cb_namespaces

# ---------- deploying files ------------------

# deploy built files - link them from private modules build directories to "public" place
# $1 - built files,    e.g.: /build/p/tt/bin-tool.exe@-/tt/bin/tool.exe /build/p/tt/gen-tool.cfg@-/tt/gen/tool.cfg
# $2 - deployed paths, e.g.: /build/tt/bin/tool.exe /build/tt/gen/tool.cfg
# note: assume deployed files are needed _only_ by $(cb_target_makefile)-, so:
#  - set makefile info (target-specific variables) by 'set_makefile_info_r' macro only for the $(cb_target_makefile)-,
#   assume that this makefile info will be properly inherited by targets of linking rules
define cb_deploy_files
cb_needed_dirs += $(patsubst $(cb_build)/%/,%,$(dir $2))
$(subst |, | ,$(subst ||,: ,$(subst / ,$(newline),$(join $(join $(2:=||),$(1:=|)),$(dir $2)) )))$(call \
  set_makefile_info_r,$(cb_target_makefile)-): $2
$(call suppress_targets_r,$2):
	$$(call suppress,LN,$$@)$$(call simlink_files,$$<,$$@)
endef

# deploy built tools - link them from private modules build directories to "public" place
# $1 - built files,    e.g.: /build/p/tt/bin-tool.exe@-/tt/bin/tool.exe /build/p/tt/gen-tool.cfg@-/tt/gen/tool.cfg
# $2 - deployed paths, e.g.: /build/tt/bin/tool.exe /build/tt/gen/tool.cfg
# note: deployed tools are may be required for building other targets, so:
#  - set makefile info (target-specific variables) by 'set_makefile_info_r' macro for each deployed tool
define cb_deploy_tool_files
cb_needed_dirs += $(patsubst $(cb_build)/%/,%,$(dir $2))
$(subst |, | ,$(subst ||,: ,$(subst / ,$(newline),$(join $(join $(2:=||),$(1:=|)),$(dir $2)) )))$(cb_target_makefile)-: $2
$(call set_makefile_info_r,$(call suppress_targets_r,$2)):
	$$(call suppress,LN,$$@)$$(call simlink_files,$$<,$$@)
endef

# $1 - deployed files - simple paths relative to virtual $(out_dir), e.g.: bin/tool.exe gen/tool.cfg
# $2 - built files, e.g.: /build/p/tt/bin-tool.exe@-/tt/bin/tool.exe /build/p/tt/gen-tool.cfg@-/tt/gen/tool.cfg
deploy_files1 = $(if $(is_tool_mode),$(call \
  cb_deploy_tool_files,$2,$(addprefix $(cb_build)/$(cb_tools_subdir)/,$1)),$(call \
  cb_deploy_files,$2,$(addprefix $(cb_build)/$(target_triplet)/,$1)))

# protect new value of 'cb_needed_dirs', do not trace calls to it because it's incremented
ifdef cb_checking
$(eval deploy_files1 = $(value deploy_files1)$(newline)$(call set_global1,cb_needed_dirs))
endif

# deploy files - link them from private modules build directories to "public" place
# $1 - deployed files - simple paths relative to virtual $(out_dir), e.g.: bin/tool.exe gen/tool.cfg
deploy_files = $(eval $(call deploy_files1,$1,$(o_path)))

# ---------- deploying directories ------------

# generate rules for linking directories
# $1 - source dirs,      e.g.: /build/tt/s1/1 /build/tt/s2/2
# $2 - destination dirs, e.g.: /build/dd/s1/1 /build/dd/s2/2
# result:
#  $(call suppress_more,LN,/build/dd/s1/1)$(call simlink_dir,/build/tt/s1/1,/build/dd/s1)
#  $(call suppress_more,LN,/build/dd/s2/2)$(call simlink_dir,/build/tt/s2/2,/build/dd/s2)
cb_gen_dir_linking_rules = $(subst $$(space), ,$(subst $(space),$(newline),$(join $(patsubst \
  %,$$(call$$(space)suppress_more,LN,%),$2),$(patsubst \
  %,$$(call$$(space)simlink_dir,%),$(join $(1:=,),$(patsubst %/,%,$(dir $2)))))))

# deploy built directories - link them from tag file's private build directory to "public" place
# $1 - built tag file, e.g.: /build/p/tt/gen1-tag1.tag@-/tt/gen1/tag1.tag
# $2 - deployed path,  e.g.: /build/tt/gen1/tag1.tag
# $3 - built dirs,     e.g.: /build/p/tt/gen1-tag1.tag@-/tt/gen2/dir1 /build/p/tt/gen1-tag1.tag@-/tt/gen3/dir2/dir3
# $4 - deployed dirs,  e.g.: /build/tt/gen2/dir1 /build/tt/gen3/dir2/dir3
define cb_deploy_dirs
cb_needed_dirs += $(patsubst $(cb_build)/%/,%,$(dir $2 $4))
$(cb_target_makefile)-: $2
$(call set_makefile_info_r,$(call suppress_targets_r,$2)): $1 | $(patsubst %/,%,$(dir $2 $4))
	$$(call cb_gen_dir_linking_rules,$3,$4)
	$$(call suppress,LN,$$@)$$(call simlink_files,$$<,$$@)
endef

# $1 - deployed tag file - simple path relative to virtual $(out_dir),  e.g.: gen1/tag1.tag
# $2 - deployed dirs     - simple paths relative to virtual $(out_dir), e.g.: gen2/dir1 gen3/dir2/dir3
# $3 - destination directory: $(cb_build)/$(if $(is_tool_mode),$(cb_tools_subdir),$(target_triplet))
# note: it is assumed that directories $2 are built in private namespace of the tag file $1
deploy_dirs1 = $(call cb_deploy_dirs,$(o_path),$3/$1,$(addprefix $(o_dir)/,$2),$(addprefix $3/,$2))

# protect new value of 'cb_needed_dirs', do not trace calls to it because it's incremented
ifdef cb_checking
$(eval deploy_dirs1 = $(value deploy_dirs1)$(newline)$(call set_global1,cb_needed_dirs))
endif

# 1) associate each deployed directory with given tag file (which is updated just after update of the directories)
# 2) deploy associated built dirs - link them from tag file's private build directory to "public" place
# $1 - deployed tag file - simple path relative to virtual $(out_dir),  e.g.: gen1/tag1.tag
# $2 - deployed dirs     - simple paths relative to virtual $(out_dir), e.g.: gen2/dir1 gen3/dir2/dir3
deploy_dirs = $(assoc_dirs)$(eval $(call deploy_dirs1,$1,$2,$(cb_build)/$(if $(is_tool_mode),$(cb_tools_subdir),$(target_triplet))))

else # !cb_namespaces

# files are built directly in "public" place, no need to link there them from private modules build directories
ifndef cb_checking
deploy_files:=
else
# check parameters:
# $1 - deployed files - simple paths relative to virtual $(out_dir), e.g.: bin/tool.exe gen/tool.cfg
deploy_files = $(cb_check_vpaths)
endif

# directories are built directly in "public" place, no need to link there them from private modules build directories, so
#  - just associate each deployed directory with given tag file (which is updated just after update of the directories)
# $1 - deployed tag file - simple path relative to virtual $(out_dir),  e.g.: gen1/tag1.tag
# $2 - deployed dirs     - simple paths relative to virtual $(out_dir), e.g.: gen2/dir1 gen3/dir2/dir3
deploy_dirs = $(assoc_dirs)

endif # !cb_namespaces

# $1 - tag file   - simple path relative to virtual $(out_dir),  e.g.: gen1/tag1.tag
# $2 - built dirs - simple paths relative to virtual $(out_dir), e.g.: gen2/dir1 gen3/dir2/dir3
assoc_dirs_r   = $(assoc_dirs)$1

# $1 - deployed files - simple paths relative to virtual $(out_dir), e.g.: bin/tool.exe gen/tool.cfg
deploy_files_r = $(deploy_files)$1

# $1 - deployed tag file - simple path relative to virtual $(out_dir),  e.g.: gen1/tag1.tag
# $2 - deployed dirs     - simple paths relative to virtual $(out_dir), e.g.: gen2/dir1 gen3/dir2/dir3
deploy_dirs_r  = $(deploy_dirs)$1

# makefile parsing first phase variables
cb_first_phase_vars += assoc_dirs cb_tag_files cb_deploy_files cb_deploy_tool_files deploy_files1 deploy_files \
  cb_deploy_dirs deploy_dirs1 deploy_dirs assoc_dirs_r deploy_files_r deploy_dirs_r

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: assoc_dirs
$(call set_global,assoc_dirs assoc_dirs1 assoc_dirs_r,assoc_dirs)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: do not trace access to these variables - they are incremented via operator +=
$(call set_global,cb_tag_files cb_tag_files_t cb_assoc_dirs cb_assoc_dirs_t)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: deploy
$(call set_global,cb_deploy_files cb_deploy_tool_files deploy_files1 deploy_files cb_gen_dir_linking_rules cb_deploy_dirs \
  deploy_dirs1 deploy_dirs deploy_files_r deploy_dirs_r,deploy)
