syn match makeTrailSpaces   / *$/
syn match makeDollar        /\$(/he=s+1 containedin=makeIdent
syn match makeDDollar       /\$\$(/he=s+2 containedin=makeIdent
syn match makeBraces        /\$(/hs=s+1 containedin=makeDollar
syn match makeBraces        /\$\$(/hs=s+2 containedin=makeDDollar
syn match makeIdentLetters  /[_a-zA-Z0-9]*/ contained containedin=makeMacroRef
syn match makeVarDelayedRef /\$\$[^$({,]/ containedin=makeIdent,makeDefine,makeMacroRef
syn match makeMacroRef      /\$([$_a-zA-Z0-9]*)/hs=s+2,me=e-1 containedin=makeBraces
syn match makeNewlineKw     /\$(newline)/hs=s+2,me=e-1 containedin=makeBraces
syn region makeIdent	    start="\$(" skip="\\)\|\\\\" matchgroup=makeBraces end=")" containedin=makeIdent
syn region makeIdent	    start="\$\$(" skip="\\)\|\\\\" matchgroup=makeBraces end=")" containedin=makeIdent
syn match makeVarRef        /$[^$({,]/ containedin=makeIdent,makeDefine,makeMacroRef
syn match makePercent       /%/ containedin=makeIdent
syn match makeAssignSimple  /:=/ containedin=makeIdent,makeDefine
syn match makeAppend        /+=/ containedin=makeIdent,makeDefine
syn match makeComma         /,/ containedin=makeIdent,makeDefine
syn match makeTab           /\t/ containedin=makeIdent,makeDefine,makeCommands
syn match makeStatement     /\$(\(subst\|abspath\|addprefix\|addsuffix\|and\|basename\|call\|dir\|error\|eval\|filter-out\|filter\|findstring\|firstword\|flavor\|foreach\|if\|info\|join\|lastword\|notdir\|or\|origin\|patsubst\|realpath\|shell\|sort\|strip\|suffix\|value\|warning\|wildcard\|word\|wordlist\|words\)\>/hs=s+2 contained containedin=makeBraces
