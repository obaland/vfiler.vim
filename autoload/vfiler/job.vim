"=============================================================================
" FILE: autoload/job.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

let s:jobs = {}

function! s:on_err(id, job, message) abort
  call luaeval(
        \ 'require("vfiler/libs/async/jobs/job_vim")._on_error(_A.id, _A.message)',
        \ { 'id': a:id, 'message': a:message }
        \ )
endfunction

function! s:on_out(id, job, message) abort
  call luaeval(
        \ 'require("vfiler/libs/async/jobs/job_vim")._on_received(_A.id, _A.message)',
        \ { 'id': a:id, 'message': a:message }
        \ )
endfunction

function! s:on_exit(id, job, code) abort
  call luaeval(
        \ 'require("vfiler/libs/async/jobs/job_vim")._on_completed(_A.id, _A.code)',
        \ { 'id': a:id, 'code': a:code }
        \ )
endfunction

function! vfiler#job#start(id, command) abort
  let l:options = {
        \ 'err_cb': function('s:on_err', [ a:id ]),
        \ 'out_cb': function('s:on_out', [ a:id ]),
        \ 'exit_cb': function('s:on_exit', [ a:id ]),
        \ }
  let s:jobs[a:id] = job_start(a:command, l:options)
endfunction

function! vfiler#job#stop(id) abort
  if !has_key(s:jobs, a:id)
    return
  endif
  call job_stop(s:jobs[a:id])
  call remove(s:jobs, a:id)
endfunction

function! vfiler#job#wait(id, timeout, start) abort
  if !has_key(s:jobs, a:id)
    return -3
  endif
  let l:job = s:jobs[a:id]
  let l:timeout = a:timeout / 1000.0
  try
    while l:timeout < 0 || reltimefloat(reltime(a:start)) < l:timeout
      let l:info = job_info(l:job)
      if l:info.status ==# 'dead'
        return l:info.exitval
      elseif l:info.status ==# 'fail'
        return -3
      endif
      sleep 1m
    endwhile
  catch /^Vim:Interrupt$/
    return -2
  endtry
  return -1
endfunction
