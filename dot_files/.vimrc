
" PLUGIN PACKAGES
" -----------------------------------------------
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'vim-airline/vim-airline'
Plugin 'sickill/vim-monokai'
call vundle#end()

" airline
set laststatus=2
let g:airline#extensions#tabline#enabled = 1 
let g:airline#extensions#tabline#buffer_nr_show = 1


" VIM SETTING
" -----------------------------------------------
set nocompatible
set t_ut=
set autoindent
set clipboard=unnamed
set enc=UTF-8
set expandtab
set fileencoding=UTF-8
set history=1000
set hlsearch
set ignorecase
set incsearch
set mouse=a
set nobackup
set noswapfile
set nowrapscan
set number
set ruler
set shiftwidth=2
set showcmd
set smartindent
set tabstop=4
set title
set ttymouse=xterm2
set wmnu
set fileencodings=utf-8

syntax on
color monokai

" key mapping
command WQ wq
command Wq wq
command W w
command Q q
command WA wa
command Wa wa

let mapleader="."
noremap <leader>/ :bn<CR>
noremap <leader>, :bp<CR>
