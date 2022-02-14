"=============================================================================
" FILE: autoload/vfiler/core.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

function! vfiler#core#replace_keycode(str) abort
  return eval('"\' . a:str . '"')
endfunction

function! vfiler#core#clear_undo() abort
  let l:undolevels = &undolevels
  setlocal undolevels=-1
  call execute("normal! I \<BS>\<Esc>", 'silent')
  call execute('setlocal undolevels=' . l:undolevels, 'silent')
  unlet l:undolevels
endfunction
