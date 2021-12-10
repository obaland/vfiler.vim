"=============================================================================
" FILE: autoload/vfiler/timer.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

function! vfiler#timer#_callback(id) abort
  call luaeval('require("vfiler/async/loop")._callback(_A)', a:id)
endfunction

function! vfiler#timer#start(time) abort
  return timer_start(a:time, 'vfiler#timer#_callback', {'repeat': -1})
endfunction

function! vfiler#timer#stop(id) abort
  call timer_stop(a:id)
endfunction
