"=============================================================================
" FILE: autoload/vfiler/event.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

function! vfiler#event#handle(event, bufnr) abort
  call call('s:on_' . a:event, [a:bufnr])
endfunction

function! s:on_BufEnter(bufnr) abort
  call vfiler#action#reload_all()
endfunction

function! s:on_BufDelete(bufnr) abort
  call vfiler#buffer#destroy(a:bufnr)
endfunction

function! s:on_FocusGained(bufnr) abort
  call vfiler#action#reload_all()
endfunction

function! s:on_FocusLost(bufnr) abort
  let element = vfiler#context#get_element(b:context, line('.') - 1)
  call vfiler#context#save_index_cache(b:context, element.path)
endfunction

function! s:on_VimResized(bufnr) abort
  call vfiler#action#redraw_all()
endfunction
