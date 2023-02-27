if &compatible
  set nocompatible               " Be iMproved
endif

if has('mac')
	set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}
	inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
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
