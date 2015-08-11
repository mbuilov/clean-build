# sed -f clean-build/WINXX/parse_analisis.sed test.nativecodeanalysis.xml
/<?xml version='1.0' encoding='UTF-8'?>/d
s@<DEFECTS>@@
s@<DEFECT>@defect:\n@g
s@</DEFECT>@\n@g
s@</PATH>@@g
s@&lt;@<@g
s@&gt;@>@g
s@&amp;@\&@g
s@</MESSAGE>@\n@g
s@</DESCRIPTION>@\n@g
s@</RULECATEGORY>@\n@g
s@<SFA><FILEPATH>[^<]*</FILEPATH><FILENAME>\([^<]*\)</FILENAME><LINE>\([0-9]*\)</LINE><COLUMN>\([0-9]*\)</COLUMN></SFA>@\1:\2:\3\n@g
s@<SFA><FILEPATH>[^<]*</FILEPATH><FILENAME>\([^<]*\)</FILENAME><LINE>\([0-9]*\)</LINE><COLUMN>\([0-9]*\)</COLUMN><KEYEVENT><ID>\([0-9]*\)</ID><KIND>\([^<]*\)</KIND><IMPORTANCE>\([^<]*\)</IMPORTANCE><MESSAGE>\([^\n]*\)\n</KEYEVENT></SFA>@\1:\2:\3 id=\4 kind=\5 importance=\6 msg=\7\n@g
s@<DEFECTCODE>\([0-9]*\)</DEFECTCODE><DESCRIPTION>\([^\n]*\)\n<FUNCTION>\([^<]*\)</FUNCTION><DECORATED>\([^<]*\)</DECORATED><FUNCLINE>\([0-9]*\)</FUNCLINE><PROBABILITY>\([0-9]*\)</PROBABILITY><RANK>\([0-9]*\)</RANK><CATEGORY><RULECATEGORY>\([^\n]*\)\n</CATEGORY><PATH>@code=\1 desc=\2\nfunc=\3 decorated=\4 line=\5 prob=\6 rank=\7 category=\8\n@g
s@</DEFECTS>@@
