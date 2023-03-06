if &compatible
  set nocompatible               " Be iMproved
endif

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

if has('mac')
	autocmd InsertLeavePre * :call system('im-select com.apple.inputmethod.Kotoeri.RomajiTyping.Roman')
endif
if has('unix')
	autocmd InsertLeavePre * :call system('ibus engine xkb:us::eng')
endif

set clipboard+=unnamedplus
