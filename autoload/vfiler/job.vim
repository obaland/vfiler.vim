"=============================================================================
" FILE: autoload/vfiler/job.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

let s:jobs = {}

function! vfiler#job#start(id, command) abort
  let options = {
        \ 'out_cb': function('vfiler#job#out_cb', [a:id]),
        \ 'err_cb': function('vfiler#job#err_cb', [a:id]),
        \ 'close_cb': function('vfiler#job#close_cb', [a:id]),
        \ }
  let s:jobs[a:id] = job_start(a:command, options)
endfunction

function! vfiler#job#status(id) abort
  if !has_key(s:jobs, a:id)
    return 'dead'
  endif
  return job_status(s:jobs[a:id])
endfunction

function! vfiler#job#stop(id) abort
  if !has_key(s:jobs, a:id)
    return
  endif
  call job_stop(s:jobs[a:id])
  call remove(s:jobs, a:id)
endfunction

function! vfiler#job#out_cb(id, channel, message) abort
  call luaeval('require("vfiler/async/job")._out_cb(_A.id, _A.message)',
        \ {'id': a:id, 'message': a:message}
        \ )
endfunction

function! vfiler#job#err_cb(id, channel, message) abort
  call luaeval('require("vfiler/async/job")._err_cb(_A.id, _A.message)',
        \ {'id': a:id, 'message': a:message}
        \ )
endfunction

function! vfiler#job#close_cb(id, channel) abort
  call luaeval('require("vfiler/async/job")._close_cb(_A)', a:id)
endfunction
