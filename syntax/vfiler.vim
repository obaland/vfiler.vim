"=============================================================================
" FILE: syntax/vfiler.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================
if exists('b:current_syntax')
  finish
endif

call vfiler#syntax#define()

let b:current_syntax = 'vfiler'
