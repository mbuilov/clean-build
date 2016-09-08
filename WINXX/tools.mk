# this file included by $(MTOP)/defs.mk

# syncronize make output for parallel builds
MAKEFLAGS += -O

# max command line length
# for Windows 95 and later    - 127 chars;
# for Windows 2000 and later  - 2047 chars;
# for Windows XP and later    - 8191 chars (max 31 path arguments of 260 chars length each);
# maximum number of args passed via command line
ifndef DEL_ARGS_LIMIT
# for Windows XP and later, assuming that maximum length of each arg is 80 chars
DEL_ARGS_LIMIT := 100
endif

# don't colorize output
TERM_NO_COLOR := 1

# convert slashes
# NOTE: no spaces allowed in paths the $(MAKE) works with
ospath = $(subst /,\,$1)

# absolute paths contain ':', for example c:/agent
# NOTE: assume there are no spaces and ':' in the path to sources
isrelpath = $(if $(word 2,$(subst :, ,$1)),,1)

DEL   = if exist $(ospath) (del /F /Q $(ospath))
RM1   = $(if $(VERBOSE),,@)for %%f in ($(ospath)) do if exist %%f\NUL (rd /S /Q %%f) else if exist %%f (del /F /Q %%f)
RM    = $(call xcmd,RM1,$1,$(DEL_ARGS_LIMIT))
# NOTE! there are races in MKDIR - if make spawns two parallel jobs:
# if not exist aaa
#                        if not exist aaa/bbb
#                        mkdir aaa/bbb
# mkdir aaa - fail
#MKDIR1 = if not exist $1 mkdir $1
# assume MKDIR is called only if directory does not exist
MKDIR = mkdir $(ospath)
SED  := sed.exe -b
SED_EXPR = "$(subst %,%%,$1)"
CAT   = type $(ospath)
open_brace:=(
close_brace:=)
ECHO_LINE = (echo$(if $1, $(subst $(open_brace),^$(open_brace),$(subst $(close_brace),^$(close_brace),$(subst \
             %,%%,$(subst <,^<,$(subst >,^>,$(subst |,^|,$(subst &,^&,$(subst ",^",$(subst ^,^^,$1))))))))),.))
ECHO1 = $(if $(word 2,$1),($(foreach x,$1,$(call ECHO_LINE,$(subst $$(newline),,$(subst $$(space), ,$(subst \
         $$(tab),$(tab),$x)))) &&) rem.),$(call ECHO_LINE,$(subst $$(space), ,$(subst $$(tab),$(tab),$1))))
ECHO  = $(call ECHO1,$(subst $(newline),$$(newline) ,$(subst $(space),$$(space),$(subst $(tab),$$(tab),$1))))
CD    = cd /d $(ospath)
NUL  := NUL
SUPPRESS_CP_OUTPUT := | findstr /v /c:"        1" & if errorlevel 1 (exit /b 0) else (exit /b 1)
CP    = copy /Y /B $(ospath) $(call ospath,$2)$(SUPPRESS_CP_OUTPUT)
TOUCH1 = if not exist $1 (rem. > $1) else (copy /B $1+,, $1$(SUPPRESS_CP_OUTPUT))
TOUCH = $(call TOUCH1,$(ospath))

# delete target if failed to build it and exit shell with error code 1
DEL_ON_FAIL = || ($(foreach x,$1,$(call DEL,$x) &) exit /b 1)

# suffix of built tool executables
TOOL_SUFFIX := .exe

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,DEL_ARGS_LIMIT DEL RM1 RM MKDIR SED SED_EXPR \
  CAT open_brace close_brace ECHO_LINE ECHO1 ECHO CD NUL SUPPRESS_CP_OUTPUT CP TOUCH1 TOUCH DEL_ON_FAIL TOOL_SUFFIX)
