# this file included by WINXX/make_header.mk

# syncronize make output for parallel builds
MAKEFLAGS += -O

OSTYPE := WINDOWS

# max command line length
# for Windows 95 and later    - 127 chars;
# for Windows 2000 and later  - 2047 chars;
# for Windows XP and later    - 8191 chars (max 31 path arguments of 260 chars length each);
# maximum number of args passed via command line
ifeq ($(LIM),)
# for Windows XP and later, assuming that maximum length of each arg is 80 chars
LIM := 100
endif

# don't colorize output
COLORIZE = $1

# convert slashes
# NOTE: no spaces allowed in paths the $(MAKE) works with
ospath = $(subst /,\,$1)

# absolute paths contain ':', for example c:/agent
# NOTE: assume there are no spaces and ':' in the path to sources
isrelpath = $(if $(word 2,$(subst :, ,$1)),,1)

DEL   = (if exist $(ospath) del /F /Q $(ospath))
RM1   = $(if $(VERBOSE:1=),@)for %%f in ($(ospath)) do if exist %%f\NUL (rd /S /Q %%f) else if exist %%f (del /F /Q %%f)
RM    = $(call xcmd,RM1,$1,$(LIM))
# NOTE! there are races in MKDIR - if make spawns two parallel jobs:
# if not exist aaa
#                        if not exist aaa/bbb
#                        mkdir aaa/bbb
# mkdir aaa - fail
MKDIR1 = if not exist $1 mkdir $1
MKDIR = $(call MKDIR1,$(ospath))
SED  := sed.exe -b
SED_EXPR = "$1"
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
SUPPRESS_CP_OUTPUT := | findstr /v /b /c:"        1" & if errorlevel 1 (cmd /c exit 0) else (cmd /c exit 1)
CP    = copy /Y /B $(ospath) $(call ospath,$2)$(SUPPRESS_CP_OUTPUT)
TOUCH1 = if not exist $1 (rem. > $1) else (copy /B $1+,, $1$(SUPPRESS_CP_OUTPUT))
TOUCH = $(call TOUCH1,$(ospath))

# delete target if failed to build it and exit shell with some error code
DEL_ON_FAIL = || ($(DEL) & cmd /c exit 1)

TOOL_SUFFIX := .exe
