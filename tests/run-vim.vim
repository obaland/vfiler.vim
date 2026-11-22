if v:version < 802 || !has('lua') || !has('job')
  echoerr 'test-vim requires Vim 8.2 or later with +lua and +job.'
  cquit 1
endif

let s:runner = expand('<sfile>:p')
let s:root = fnamemodify(s:runner, ':h:h')

if exists('$VFILER_TEST_VIM_SPEC')
  execute 'set runtimepath^=' . fnameescape(s:root)
lua << EOF
local root = vim.eval('s:root')
package.path =
  root .. '/?.lua;' .. root .. '/lua/?.lua;' .. root .. '/lua/?/init.lua;' .. package.path

local ok, err = xpcall(function()
  local path = vim.eval('$VFILER_TEST_VIM_SPEC')
  if vim.eval('$VFILER_TEST_VIM_SHARED') ~= '1' then
    dofile(path)
    return
  end

  local result = require('tests/helper/spec').run(path)
  for _, issue in ipairs(result.errors) do
    io.stderr:write(issue.name, ': ', issue.message, '\n')
  end
  for _, failure in ipairs(result.failures) do
    for _, issue in ipairs(failure.issues) do
      io.stderr:write(failure.name, ' [', issue.phase, ']: ', issue.message, '\n')
    end
  end
  assert(result.passed > 0 and #result.errors == 0 and #result.failures == 0,
    ('%d passed, %d failed, %d errors'):format(
      result.passed, #result.failures, #result.errors
    ))
  io.stdout:write(('%d tests passed\n'):format(result.passed))
end, debug.traceback)
if not ok then
  io.stderr:write(err, '\n')
  io.stderr:flush()
  vim.command('cquit 1')
end
EOF
  qa!
endif

function! s:write(stream, message) abort
  call luaeval('io[_A.stream]:write(_A.message, "\n") and io[_A.stream]:flush() and 0',
        \ {'stream': a:stream, 'message': a:message})
endfunction

function! s:run_spec(path, shared) abort
  let l:stdout = tempname()
  let l:stderr = tempname()
  let l:job = job_start(
        \ [v:progpath, '-Nu', 'NONE', '-i', 'NONE', '-n', '-es', '-V1', '-S', s:runner, '-c', 'cquit 1'],
        \ {'env': {'VFILER_TEST_VIM_SPEC': a:path,
        \          'VFILER_TEST_VIM_SHARED': a:shared ? '1' : '0'},
        \  'in_io': 'null', 'out_io': 'file', 'out_name': l:stdout,
        \  'err_io': 'file', 'err_name': l:stderr})
  try
    let l:start = reltime()
    while job_status(l:job) ==# 'run'
      if reltimefloat(reltime(l:start)) >= 50.0
        call s:write('stderr', 'TIMEOUT ' . a:path)
        return 0
      endif
      sleep 10m
    endwhile
    for [l:stream, l:file] in [['stdout', l:stdout], ['stderr', l:stderr]]
      if filereadable(l:file)
        for l:line in readfile(l:file)
          call s:write(l:stream, l:line)
        endfor
      endif
    endfor
    return job_status(l:job) ==# 'dead' && job_info(l:job).exitval == 0
  finally
    if job_status(l:job) ==# 'run'
      call job_stop(l:job, 'kill')
    endif
    call delete(l:stdout)
    call delete(l:stderr)
  endtry
endfunction

let s:shared = [
      \ s:root . '/tests/vfiler/columns_spec.lua',
      \ s:root . '/tests/vfiler/sort_spec.lua',
      \ ]
let s:specs = sort(s:shared + glob(s:root . '/tests/vim/*_spec.lua', 1, 1))
if empty(s:specs)
  call s:write('stderr', 'No spec files found under tests/vim.')
  cquit 1
endif

let s:failed = 0
for s:path in s:specs
  let s:passed = s:run_spec(s:path, index(s:shared, s:path) >= 0)
  let s:failed += !s:passed
  call s:write('stdout', (s:passed ? 'PASS ' : 'FAIL ') .
        \ fnamemodify(s:path, ':~:.'))
endfor
call s:write('stdout', printf('Vim total: %d passed, %d failed',
      \ len(s:specs) - s:failed, s:failed))
if s:failed
  cquit 1
endif
qa!
