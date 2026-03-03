set autoread
set number
set incsearch
set hlsearch
"set nowrap
"
set nofoldenable    " disable folding

" ファイル名表示
set statusline=%F
" 変更チェック表示
set statusline+=%m
" 読み込み専用かどうか表示
set statusline+=%r
" ヘルプページなら[HELP]と表示
set statusline+=%h
" プレビューウインドウなら[Prevew]と表示
set statusline+=%w
" これ以降は右寄せ表示
set statusline+=%=
" file encoding
set statusline+=[ENC=%{&fileencoding}]
" 現在行数/全行数
set statusline+=[LOW=%l/%L]
" ステータスラインを常に表示(0:表示しない、1:2つ以上ウィンドウがある時だけ表示)
set laststatus=2

set ffs=unix,dos,mac
set encoding=utf-8

" set noswapfile
set nobackup
set viminfo='50,<1000,s100,\"50
set vb t_vb=

set ignorecase
set smartcase
set wrapscan

set autoindent
set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4
set smartindent
set helplang=en

filetype plugin on
filetype indent on

if has("autocmd")
  autocmd FileType html       setlocal sw=2 sts=2 ts=2 et
  autocmd FileType javascript setlocal sw=2 sts=2 ts=2 et
  autocmd FileType typescript setlocal sw=2 sts=2 ts=2 et
  autocmd FileType jsx        setlocal sw=2 sts=2 ts=2 et
  autocmd FileType tsx        setlocal sw=2 sts=2 ts=2 et
endif


set clipboard=unnamed

syntax enable

" https://github.com/junegunn/vim-plug
" curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
"     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
" :PlugInstall
call plug#begin('~/.vim/plugged')
  Plug 'plasticboy/vim-markdown'
  Plug 'kannokanno/previm'
  Plug 'tyru/open-browser.vim'

  Plug 'othree/html5.vim'

  Plug 'editorconfig/editorconfig-vim'

  Plug 'leafgarland/typescript-vim'

  Plug 'fatih/vim-go'

  " run `brew install sqlparse` first
  Plug 'mattn/vim-sqlfmt'

  Plug 'cocopon/iceberg.vim'

  Plug 'pangloss/vim-javascript'    " JavaScript support
  Plug 'leafgarland/typescript-vim' " TypeScript syntax
  Plug 'maxmellon/vim-jsx-pretty'   " JS and JSX syntax
  Plug 'jparise/vim-graphql'        " GraphQL syntax
call plug#end()

colorscheme iceberg
set t_Co=256

au BufRead,BufNewFile *.md set filetype=markdown
let g:previm_open_cmd = 'open -a Safari'


" 全角英数字記号を半角に変換する関数
function! ZenToHan()
  " 全角英数字を半角に変換
  let l:pos = getpos(".")
  %s/[！-～]/\=nr2char(char2nr(submatch(0)) - 65248)/ge
  " 特定の全角記号を半角に変換 (スペース)
  %s/　/ /ge
  call setpos('.', l:pos)
endfunction

" コマンドを定義
command! ZenToHan call ZenToHan()

" オプション: キーマッピングを設定する場合
" ノーマルモードで <Leader>z を押すと変換を実行
nnoremap <Leader>z :call ZenToHan()<CR>
