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

function! vfiler#core#info(message) abort
  echo '[vfiler]: ' . a:message
endfunction

function! vfiler#core#error(message) abort
  echohl ErrorMsg | echom '[vfiler]: ' . a:message | echohl None
endfunction

function! vfiler#core#warning(message) abort
  echohl WarningMsg | echom '[vfiler]: ' . a:message | echohl None
endfunction

function! vfiler#core#yank(content) abort
  " for register
  let @" = a:content

  " for clipboard
  if has('clipboard') || has('xterm_clipboard')
    let @+ = a:content
  endif
endfunction
