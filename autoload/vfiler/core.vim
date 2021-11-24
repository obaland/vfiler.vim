"=============================================================================
" FILE: autoload/vfiler/core.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

function! vfiler#core#clear_undo() abort
  let l:undolevels = &undolevels
  setlocal undolevels=-1
  silent execute "normal! I \<BS>\<Esc>"
  execute 'setlocal undolevels=' . l:undolevels
  unlet l:undolevels
endfunction
