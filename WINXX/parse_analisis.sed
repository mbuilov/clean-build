# sed -f clean-build/WINXX/parse_analisis.sed test.nativecodeanalysis.xml

/<?xml version="1.0" encoding="UTF-8"?>/d

/<DEFECTS>/d
/<\/DEFECTS>/d

/<DEFECT>/{
s@.*@defect: @
:m
 N;s/\n[^<]*//
 /<\/DEFECT>/!b m
}

s/&lt;/</g
s/&gt;/>/g
s/&amp;/\&/g

s@<PATH>@@g

s@</[A-Z]*>@\n@g

s@<SFA><FILEPATH>[^\n]*\n<FILENAME>\([^\n]*\)\n<LINE>\([^\n]*\)\n<COLUMN>\([^\n]*\)\n<KEYEVENT><ID>\([^\n]*\)\n<KIND>\([^\n]*\)\n<IMPORTANCE>\([^\n]*\)\n<MESSAGE>\([^\n]*\)\n@\1:\2:\3 (id=\4 kind=\5 importance=\6): \7\n@g

s@<SFA><FILEPATH>[^\n]*\n<FILENAME>\([^\n]*\)\n<LINE>\([^\n]*\)\n<COLUMN>\([^\n]*\)\n\n@\1:\2:\3\n@g

s@<DEFECTCODE>\([^\n]*\)\n<DESCRIPTION>\([^\n]*\)\n<FUNCTION>\([^\n]*\)\n<DECORATED>\([^\n]*\)\n<FUNCLINE>\([^\n]*\)\n<PROBABILITY>\([^\n]*\)\n<RANK>\([^\n]*\)\n<CATEGORY><RULECATEGORY>\([^\n]*\)\n@error \1: \2\n\3 (\4) at line \5 [prob=\6 rank=\7 category=\8]\n@g
