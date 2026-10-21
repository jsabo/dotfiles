" Plugin installation is explicit: install vim-plug, then run :PlugInstall.
" Editing files never downloads code or installs plugins automatically.
if filereadable(expand('~/.vim/autoload/plug.vim'))
  call plug#begin()
  Plug 'preservim/nerdtree'
  call plug#end()
endif

syntax on
filetype plugin indent on
set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
set backspace=indent,eol,start
set number
set nosmartindent

function! DotfilesTrimWhitespace() abort
  let l:view = winsaveview()
  try
    silent! keeppatterns %s/\s\+$//e
  finally
    call winrestview(l:view)
  endtry
endfunction

augroup dotfiles
  autocmd!
  autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line('$') | execute "normal! g`\"" | endif
  autocmd FileType make setlocal noexpandtab shiftwidth=8 softtabstop=0
  autocmd BufRead,BufNewFile *.mk setfiletype make
  " Only code formats whose trailing spaces are not meaningful. Markdown and
  " all unlisted filetypes remain untouched, preserving hard line breaks.
  autocmd BufWritePre * if index(['sh', 'python', 'go', 'json', 'toml'], &filetype) >= 0 | call DotfilesTrimWhitespace() | endif
augroup END
