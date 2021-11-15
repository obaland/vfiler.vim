"=============================================================================
" FILE: plugin/vfiler.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

if exists('g:loaded_vfiler')
  finish
endif

if has('nvim') && !has('nvim-0.5.0')
  echomsg 'VFiler requires Neovim 0.5.0 or later.'
  finish
elseif !has('nvim')
  if !has('lua') || v:version < 802
    echomsg 'VFiler requires Vim 8.2 or later with Lua support ("+lua").'
    finish
  endif
endif

let g:loaded_vfiler = 1

" Syntax highlights
highlight def link vfilerDirectory         Directory
highlight def link vfilerExecutable        PreProc
highlight def link vfilerFile              None
highlight def link vfilerHeader            Statement
highlight def link vfilerHidden            Comment
highlight def link vfilerLink              Constant
highlight def link vfilerNothing           Directory
highlight def link vfilerSelected          Title
highlight def link vfilerSize              Statement
highlight def link vfilerTime              None
highlight def link vfilerTimeToday         PreProc
highlight def link vfilerTimeWeek          Type

" define commands
command! -nargs=? -complete=customlist,vfiler#complete VFiler
      \ call vfiler#start_command(<q-args>)
