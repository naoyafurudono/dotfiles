" カーソル位置記憶
autocmd BufReadPost *
      \ if line("'\"") > 0 && line ("'\"") <= line("$") |
      \   exe "normal! g'\"" |
      \ endif

set autoindent
set smartindent
set expandtab
set tabstop=2
set shiftwidth=2
nnoremap <expr> S* ':%s/\<' . expand('<cword>') . '\>/'
set clipboard+=unnamedplus
inoremap <silent> jj <ESC>

if has('mac')
	autocmd InsertLeavePre * :call system('im-select com.apple.inputmethod.Kotoeri.RomajiTyping.Roman')
endif
if has('unix')
	autocmd InsertLeavePre * :call system('ibus engine xkb:us::eng')
endif

