let s:suite = themis#suite('vfiler/configs')
let s:assert = themis#helper('assert')

if has('win32') || has('win64')
let s:paths = [
      \ {'in': 'C:\test\a\b', 'out': 'C:\test\a\b'},
      \ {'in': '"C:\test\a b\c"', 'out': 'C:\test\a b\c'},
      \ ]
else
let s:paths = [
      \ {'in': '/test/a/b', 'out': '/test/a/b'},
      \ {'in': '/test/a\ b/c', 'out': '/test/a b/c'},
      \ ]
endif

function s:suite.parse_command_args_basic()
  for path in s:paths
    let l:args = '-auto-cd ' . path.in
    let l:configs = vfiler#parse_command_args(l:args)
    let l:message = 'args:' . l:args
    call s:assert.not_equals(l:configs, v:null, l:message)
    call s:assert.same(l:configs.path, path.out, l:message)
    call s:assert.true(l:configs.auto_cd, l:message)
  endfor
endfunction

function s:suite.parse_command_args_empty()
  let l:configs = vfiler#parse_command_args('')
  call s:assert.not_equals(l:configs, v:null)
endfunction

function s:suite.parse_command_args_path_duplicated()
  for path in s:paths
    let l:args = path.in . ' ' . path.in
    let l:configs = vfiler#parse_command_args(l:args)
    let l:message = 'args:' . l:args
    call s:assert.equals(l:configs, v:null, l:message)
  endfor
endfunction

function s:suite.parse_command_args_option()
  let l:args = '-name="Test Name"'
  let l:configs = vfiler#parse_command_args(l:args)
  let l:message = 'args:' . l:args
  call s:assert.equals(l:configs.name, 'Test Name', l:message)
endfunction

function s:suite.parse_command_args_illegal_option()
  let l:args = '-name'
  let l:configs = vfiler#parse_command_args(l:args)
  let l:message = 'args:' . l:args
  call s:assert.equals(l:configs, v:null, l:message)

  let l:args = '-name='
  let l:configs = vfiler#parse_command_args(l:args)
  let l:message = 'args:' . l:args
  call s:assert.equals(l:configs, v:null, l:message)
endfunction

function s:suite.parse_command_args_flag_option()
  let l:args = '-auto-cd -listed'
  let l:configs = vfiler#parse_command_args(l:args)
  let l:message = 'args:' . l:args
  call s:assert.true(l:configs.auto_cd, l:message)
  call s:assert.true(l:configs.listed, l:message)

  let l:args = '-no-auto-cd -no-listed'
  let l:configs = vfiler#parse_command_args(l:args)
  let l:message = 'args:' . l:args
  call s:assert.false(l:configs.auto_cd, l:message)
  call s:assert.false(l:configs.listed, l:message)
endfunction

function s:suite.parse_command_args_illegal_flag_option()
  let l:args = '-auo-cd'
  let l:configs = vfiler#parse_command_args(l:args)
  let l:message = 'args:' . l:args
  call s:assert.equals(l:configs, v:null, l:message)

  let l:args = '-auto-cd=test'
  let l:configs = vfiler#parse_command_args(l:args)
  let l:message = 'args:' . l:args
  call s:assert.equals(l:configs, v:null, l:message)
endfunction
