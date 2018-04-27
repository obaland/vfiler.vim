"=============================================================================
" FILE: syntax/vfiler.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================
if exists('b:current_syntax')
  finish
endif

call vfiler#syntax#define()

highlight! def link vfilerFile              Normal
highlight! def link vfilerDirectory         Directory
highlight! def link vfilerCurrentDirectory  Statement
highlight! def link vfilerLink              Constant
highlight! def link vfilerHidden            Comment
highlight! def link vfilerSelected          Title
highlight! def link vfilerNothing           Directory

highlight! def link vfilerSize              Statement

highlight! def link vfilerTime              Normal
highlight! def link vfilerTimeToday         Special
highlight! def link vfilerTimeWeek          Type

let b:current_syntax = 'vfiler'
