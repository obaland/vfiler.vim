"=============================================================================
" FILE: autoload/vfiler/async.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

let s:jobs = {}

function! vfiler#async#job_start(id, command, options) abort
  let s:jobs[a:id] = job_start(a:command, a:options)
endfunction

function! vfiler#async#job_status(id) abort
  if !has_key(s:jobs, a:id)
    return 'dead'
  endif
  return job_status(s:jobs[a:id])
endfunction

function! vfiler#async#job_stop(id) abort
  if !has_key(s:jobs, a:id)
    return
  endif
  call job_stop(s:jobs[a:id])
  call remove(s:jobs, a:id)
endfunction
