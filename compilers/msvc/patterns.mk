#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# string patterns to match localized output of msvc compiler tools, such as link.exe and cl.exe

# included by $(cb_dir)/compilers/msvc/cmn.mk

# Note: encoding of this file should be latin1, because pattern values - just bytes
# Note: comments are in utf-8, to view them in vim, run the command: :e ++enc=utf-8

# =============================================================
# strings to strip off from the output of link.exe (regular expression of findstr.exe)
# NOTE: spaces in a string must be replaced with ?
linker_strip_strings_en := Generating?code Finished?generating?code

# ".–æ–∑–¥–∞–Ω–∏–µ?–∫–æ–¥–∞ .–æ–∑–¥–∞–Ω–∏–µ?–∫–æ–¥–∞?–∑–∞–≤–µ—Ä—à–µ–Ω–æ" (utf-8) -> cp1251
linker_strip_strings_ru_cp1251 := .ÓÁ‰‡ÌËÂ?ÍÓ‰‡ .ÓÁ‰‡ÌËÂ?ÍÓ‰‡?Á‡‚Â¯ÂÌÓ

# ".–æ–∑–¥–∞–Ω–∏–µ?–∫–æ–¥–∞ .–æ–∑–¥–∞–Ω–∏–µ?–∫–æ–¥–∞?–∑–∞–≤–µ—Ä—à–µ–Ω–æ" (utf-8) -> cp1251 -> cp866
linker_strip_strings_ru_cp1251_cp866 := .˛˜Ù˝¯ı?˙˛Ù .˛˜Ù˝¯ı?˙˛Ù?˜Úı®∞ı˝˛

# =============================================================
# $(SED) pattern to match cl.exe messages about included files (used for dependencies auto-generation)
# NOTE: /showIncludes compiler option is available only for Visual Studio .NET and later
# sample makefile for getting the pattern:
#  V := C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\include\varargs.h
#  X := $(wordlist 2,999999,$(shell cl.exe /nologo /showIncludes /FI "$V" /TC /c "$V" /E 2>&1 >NUL))
#  P := $(subst ?, ,$(firstword $(subst $(subst $(space),?,$V), ,$(subst $(space),?,$X))))
cl_including_file_pattern_en := Note: including file:

# "–ü—Ä–∏–º–µ—á–∞–Ω–∏–µ: –≤–∫–ª—é—á–µ–Ω–∏–µ —Ñ–∞–π–ª–∞:" (utf-8)
cl_including_file_pattern_ru_utf8 := –ü—Ä–∏–º–µ—á–∞–Ω–∏–µ: –≤–∫–ª—é—á–µ–Ω–∏–µ —Ñ–∞–π–ª–∞:
cl_including_file_pattern_ru_utf8_bytes := \xd0\x9f\xd1\x80\xd0\xb8\xd0\xbc\xd0\xb5\xd1\x87\xd0\xb0\xd0\xbd\xd0\xb8\xd0\xb5: \xd0\xb2\xd0\xba\xd0\xbb\xd1\x8e\xd1\x87\xd0\xb5\xd0\xbd\xd0\xb8\xd0\xb5 \xd1\x84\xd0\xb0\xd0\xb9\xd0\xbb\xd0\xb0:

# "–ü—Ä–∏–º–µ—á–∞–Ω–∏–µ: –≤–∫–ª—é—á–µ–Ω–∏–µ —Ñ–∞–π–ª–∞:" (utf-8) -> cp1251
cl_including_file_pattern_ru_cp1251 := œËÏÂ˜‡ÌËÂ: ‚ÍÎ˛˜ÂÌËÂ Ù‡ÈÎ‡:
cl_including_file_pattern_ru_cp1251_bytes := \xcf\xf0\xe8\xec\xe5\xf7\xe0\xed\xe8\xe5: \xe2\xea\xeb\xfe\xf7\xe5\xed\xe8\xe5 \xf4\xe0\xe9\xeb\xe0:

# "–ü—Ä–∏–º–µ—á–∞–Ω–∏–µ: –≤–∫–ª—é—á–µ–Ω–∏–µ —Ñ–∞–π–ª–∞:" (utf-8) -> cp866
cl_including_file_pattern_ru_cp866 := è‡®¨•Á†≠®•: ¢™´ÓÁ•≠®• ‰†©´†:
cl_including_file_pattern_ru_cp866_bytes := \x8f\xe0\xa8\xac\xa5\xe7\xa0\xad\xa8\xa5: \xa2\xaa\xab\xee\xe7\xa5\xad\xa8\xa5 \xe4\xa0\xa9\xab\xa0:

# protect macros from modifications in target makefiles, do not trace calls to them
$(call set_global, \
  linker_strip_strings_en \
  linker_strip_strings_ru_cp1251 \
  linker_strip_strings_ru_cp1251_cp866 \
  cl_including_file_pattern_en \
  cl_including_file_pattern_ru_utf8 \
  cl_including_file_pattern_ru_utf8_bytes \
  cl_including_file_pattern_ru_cp1251 \
  cl_including_file_pattern_ru_cp1251_bytes \
  cl_including_file_pattern_ru_cp866 \
  cl_including_file_pattern_ru_cp866_bytes \
)
