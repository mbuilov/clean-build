syn match makeIdentLetters  /[_a-zA-Z0-9]*/ contained
syn match makeVarRef        /$[^$({,]/ containedin=makeIdent,makeDefine
syn match makeVarDelayedRef /$$[^$({,]/ containedin=makeIdent,makeDefine
syn match makePercent       /%/ containedin=makeIdent
syn match makeMacroRef      /([%$_a-zA-Z0-9]*)/ms=s+1,me=e-1 containedin=makeIdent contains=makeIdentLetters,makeVarRef,makeVarDelayedRef,makePercent
syn match makeAssignSimple  /:=/ containedin=makeIdent,makeDefine
syn match makeAppend        /+=/ containedin=makeIdent,makeDefine
syn match makeComma         /,/ containedin=makeIdent,makeDefine
syn match makeTab           /\t/ containedin=makeIdent,makeDefine,makeCommands
syn match makeNewlineKw     /(newline)/ms=s+1,me=e-1 containedin=makeIdent
