" Basic
syntax on
set number
set relativenumber
set clipboard=unnamedplus

" Turn backup off, since most stuff is in SVN, git etc. anyway...
set nobackup
set nowb
set noswapfile

" Use spaces instead of tabs
set expandtab
set smarttab
set shiftwidth=4
set tabstop=4


" Make backspace behave and wrap on newlines
set backspace=eol,start,indent
set whichwrap+=<,>,h,l


" Remaps
vnoremap <Tab> >gv
vnoremap <S-Tab> <gv

inoremap jk <Esc>
nnoremap r <C-r>




