#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# msvc compiler settings, included by $(CLEAN_BUILD_DIR)/compilers/msvc.mk

# Windows tools, such as rc.exe, mc.exe, cl.exe, link.exe, produce excessive output in stdout,
# by default, try to filter this output out by wrapping calls to the tools.
# If not empty, then do not wrap tools
NO_WRAP:=

# Creating a process on Windows costs more time than on Unix,
# so when compiling in parallel, it takes more total time to
# call compiler for each source individually over than
# compiling multiple sources at once, so that compiler itself
# internally may parallel the compilation by using threads.

# By default, compile multiple sources at once.
# Run via $(MAKE) S=1 to compile each source individually (without /MP compiler option)
ifeq (command line,$(origin S))
SEQ_BUILD := $(S:0=)
else
SEQ_BUILD:=
endif

# max number of sources to compile with /MP compiler option
# - with too many sources it's possible to exceed maximum command string length
MCL_MAX_COUNT := 50

# strings to strip off from link.exe output
LINKER_STRIP_STRINGS_en := Generating?code Finished?generating?code
# cp1251 ".Ð¾Ð·Ð´Ð°Ð½Ð¸Ðµ?ÐºÐ¾Ð´Ð° .Ð¾Ð·Ð´Ð°Ð½Ð¸Ðµ?ÐºÐ¾Ð´Ð°?Ð·Ð°Ð²ÐµÑÑÐµÐ½Ð¾"
LINKER_STRIP_STRINGS_ru_cp1251 := .îçäàíèå?êîäà .îçäàíèå?êîäà?çàâåðøåíî
# cp1251 ".Ð¾Ð·Ð´Ð°Ð½Ð¸Ðµ?ÐºÐ¾Ð´Ð° .Ð¾Ð·Ð´Ð°Ð½Ð¸Ðµ?ÐºÐ¾Ð´Ð°?Ð·Ð°Ð²ÐµÑÑÐµÐ½Ð¾" as cp866 converted to cp1251
LINKER_STRIP_STRINGS_ru_cp1251_as_cp866_to_cp1251 := .þ÷ôðýøõ?úþôð .þ÷ôðýøõ?úþôð?÷ðòõ¨°õýþ

# $(SED) expression to match C compiler messages about included files
INCLUDING_FILE_PATTERN_en := Note: including file:
# utf8 "ÐÑÐ¸Ð¼ÐµÑÐ°Ð½Ð¸Ðµ: Ð²ÐºÐ»ÑÑÐµÐ½Ð¸Ðµ ÑÐ°Ð¹Ð»Ð°:"
INCLUDING_FILE_PATTERN_ru_utf8 := ÐÑÐ¸Ð¼ÐµÑÐ°Ð½Ð¸Ðµ: Ð²ÐºÐ»ÑÑÐµÐ½Ð¸Ðµ ÑÐ°Ð¹Ð»Ð°:
INCLUDING_FILE_PATTERN_ru_utf8_bytes := \xd0\x9f\xd1\x80\xd0\xb8\xd0\xbc\xd0\xb5\xd1\x87\xd0\xb0\xd0\xbd\xd0\xb8\xd0\xb5: \xd0\xb2\xd0\xba\xd0\xbb\xd1\x8e\xd1\x87\xd0\xb5\xd0\xbd\xd0\xb8\xd0\xb5 \xd1\x84\xd0\xb0\xd0\xb9\xd0\xbb\xd0\xb0:
# cp1251 "ÐÑÐ¸Ð¼ÐµÑÐ°Ð½Ð¸Ðµ: Ð²ÐºÐ»ÑÑÐµÐ½Ð¸Ðµ ÑÐ°Ð¹Ð»Ð°:"
INCLUDING_FILE_PATTERN_ru_cp1251 := Ïðèìå÷àíèå: âêëþ÷åíèå ôàéëà:
INCLUDING_FILE_PATTERN_ru_cp1251_bytes := \xcf\xf0\xe8\xec\xe5\xf7\xe0\xed\xe8\xe5: \xe2\xea\xeb\xfe\xf7\xe5\xed\xe8\xe5 \xf4\xe0\xe9\xeb\xe0:
# cp866 "ÐÑÐ¸Ð¼ÐµÑÐ°Ð½Ð¸Ðµ: Ð²ÐºÐ»ÑÑÐµÐ½Ð¸Ðµ ÑÐ°Ð¹Ð»Ð°:"
INCLUDING_FILE_PATTERN_ru_cp866 := à¨¬¥ç ­¨¥: ¢ª«îç¥­¨¥ ä ©« :
INCLUDING_FILE_PATTERN_ru_cp866_bytes := \x8f\xe0\xa8\xac\xa5\xe7\xa0\xad\xa8\xa5: \xa2\xaa\xab\xee\xe7\xa5\xad\xa8\xa5 \xe4\xa0\xa9\xab\xa0:

# $(SED) script to generate dependencies file from C compiler output
# $1 - compiler with options (unused)
# $2 - target object file
# $3 - source
# $4 - included header file search pattern: $(INCLUDING_FILE_PATTERN)
# $5 - prefixes of system includes to filter out: $(UDEPS_INCLUDE_FILTER)

# s/\x0d//;                                - fix line endings - remove carriage-return (CR)
# /^$(notdir $3)$$/d;                      - delete compiled source file name printed by cl.exe, start new circle
# /^$4 /!{p;d;}                            - print all lines not started with $4 pattern and space, start new circle
# s/^$4  *//;                              - strip-off leading $4 pattern with spaces
# $(subst ?, ,$(foreach x,$5,\@^$x.*@Id;)) - delete lines started with system include paths, start new circle
# s/ /\\ /g;                               - escape spaces in included file path
# s@.*@&:\n$2: &@;w $2.d                   - make dependencies, then write to generated dep-file (e.g. /build/obj/src.obj.d)

SED_DEPS_SCRIPT = \
-e "s/\x0d//;/^$(notdir $3)$$/d;/^$4 /!{p;d;}" \
-e "s/^$4  *//;$(subst ?, ,$(foreach x,$5,\@^$x.*@Id;))s/ /\\ /g;s@.*@&:\n$2: &@;w $2.d"

