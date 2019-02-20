" auto install vim-plug if not installed
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin()
Plug 'scrooloose/nerdtree'	" directory tree explorer
call plug#end()

" Jump to the last position when reopening a file
if has("autocmd")
  au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
    \| exe "normal! g'\"" | endif
endif

syntax on

" enable filetype detection:
filetype on
filetype plugin on

set tabstop     =2  " tabstop:          Width of tab character
set softtabstop =2  " softtabstop:      Fine tunes the amount of white space to be added
set shiftwidth  =2  " shiftwidth        Determines the amount of whitespace to add in normal mode
set expandtab       " expandtab:        When on uses space instead of tabs
set backspace=indent,eol,start
set number
set nosmartindent

"filetype indent on " file type based indentation
" in makefiles, don't expand tabs to spaces, since actual tab characters are
" needed, and have indentation at 8 chars to be sure that all indents are tabs
" (despite the mappings later):
autocmd FileType make set noexpandtab shiftwidth=8 softtabstop=0
autocmd Bufenter *.mk set syntax=make
autocmd BufWritePre * %s/\s\+$//e
