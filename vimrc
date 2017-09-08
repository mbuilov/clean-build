colorscheme elflord
set nocompatible
set hlsearch
syntax on
set ruler
set showcmd
set backspace=indent,eol,start
" set expandtab
" set incsearch
set shiftwidth=4
set tabstop=4
set autoindent
highlight MatchParen cterm=bold ctermbg=blue
au BufNewFile,BufRead *.zul set filetype=xml
"map ^[[1;5A ^Y
"map ^[[1;5B ^E

" Tell vim to remember certain things when we exit
"  '10  :  marks will be remembered for up to 10 previously edited files
"  "100 :  will save up to 100 lines for each register
"  :20  :  up to 20 lines of command-line history will be remembered
"  %    :  saves and restores the buffer list
"  n... :  where to save the viminfo files
set viminfo='10,\"100,:20,%,n~/.viminfo
au BufReadPost * if line("'\"") > 0|if line("'\"") <= line("$")|exe("norm '\"")|else|exe "norm $"|endif|endif

function! ResCur()
  if line("'\"") <= line("$")
    normal! g`"
    return 1
  endif
endfunction

augroup resCur
  autocmd!
  autocmd BufWinEnter * call ResCur()
augroup END

hi Search ctermfg=white ctermbg=blue
hi String ctermbg=darkblue ctermfg=cyan
hi cSpecial ctermbg=darkblue ctermfg=magenta cterm=none
hi cCharacter ctermbg=darkblue ctermfg=magenta
hi Conditional ctermfg=magenta cterm=none
hi cUserType ctermfg=darkgreen
hi Repeat ctermfg=cyan
hi cUnOper ctermfg=cyan cterm=none
hi trailingSpaces ctermbg=blue
hi cDbgPrint ctermfg=lightblue cterm=bold
hi cInclude ctermfg=lightblue cterm=none
hi cAssert ctermfg=lightred cterm=none
"hi cFunction ctermfg=darkyellow
hi cFunction ctermfg=172 cterm=none
hi cConstant ctermfg=darkmagenta
hi Number ctermfg=169 cterm=bold
hi cUserLabel ctermfg=red cterm=bold
hi cGoto ctermfg=red cterm=bold
hi cLabel ctermfg=cyan cterm=bold
hi cStructObject ctermfg=cyan
hi cStructObjectPtr ctermfg=cyan
"hi bracket ctermfg=darkcyan
hi bracket ctermfg=darkcyan
hi opcolons ctermfg=yellow cterm=bold
"hi endcolon ctermfg=lightred cterm=none
hi endcolon ctermfg=red cterm=bold
hi assignment ctermfg=white cterm=bold
hi bodyBracket ctermfg=darkcyan cterm=none
hi mccTag ctermfg=white
hi MatchParen ctermbg=blue ctermfg=yellow guibg=lightblue
hi __attribute__ ctermfg=cyan cterm=bold
hi _Ms_annotation_unknown_ ctermfg=red cterm=bold
hi _Ms_annotation_ ctermfg=cyan cterm=bold
hi A_Annotation ctermfg=magenta cterm=bold
hi CMN_Types ctermfg=darkmagenta cterm=bold

hi makeTrailSpaces ctermbg=blue
hi makeDefine ctermfg=lightgreen
hi makeExport ctermfg=blue cterm=bold
hi makeInclude ctermfg=magenta cterm=bold
hi makePreCondit ctermfg=red cterm=bold
hi makeIdent ctermfg=cyan
hi makeTarget ctermfg=white cterm=bold
hi makeVarRef ctermfg=darkmagenta cterm=bold
hi makeVarDelayedRef ctermfg=lightmagenta
hi makeDDollar ctermfg=lightmagenta
hi makePercent ctermfg=red
hi makeAssignSimple ctermfg=white
hi makeAppend ctermfg=white
hi makeComma ctermfg=yellow cterm=bold
hi makeTab ctermbg=darkblue
hi makeDefineTarget ctermfg=white
hi makeNewlineKw ctermfg=darkblue cterm=bold
hi makeIdentLetters ctermfg=darkyellow
hi makeDollar ctermfg=red
hi makeBraces ctermfg=green

map <C-Up> <C-Y>
map <C-Down> <C-E>
imap <C-Up> <C-O><C-Y>
imap <C-Down> <C-O><C-E>
imap <C-N> <C-O>n
map <F2> :w
imap <F2> <C-O><F2>
imap  OCdbi
map  db
imap [3;5~ OCdwi
map [3;5~ dw
map [1;5C w
map [1;5D b

set tags=./tags,tags;

set colorcolumn=140

set nocscopeverbose
source ~/cscope_maps.vim
au FileType * set fo-=c fo-=r fo-=o

let Tlist_Use_Right_Window = 1
let Tlist_WinWidth = 97

set ul=100000
set undoreload=1000000
