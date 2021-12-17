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

function! s:parse_options(args)
  let args = a:args
lua<<EOF
  options, dirpath = require('vfiler/config').parse_options(vim.eval('args'))
EOF
  return luaeval('vim.dict(options)')
endfunction

function! s:parse_path(args)
  let args = a:args
lua<<EOF
  options, dirpath = require('vfiler/config').parse_options(vim.eval('args'))
EOF
  return luaeval('dirpath')
endfunction

function s:suite.parse_command_args_basic()
  for path in s:paths
    let l:args = '-auto-cd ' . path.in
    let l:message = 'args:' . l:args

    let l:dirpath = s:parse_path(l:args)
    call s:assert.not_equals(l:dirpath, v:null, l:message)

    let l:options = s:parse_options(l:args)
    call s:assert.not_equals(l:options, v:null, l:message)

    call s:assert.same(l:dirpath, path.out, l:message)
    call s:assert.true(l:options.auto_cd, l:message)
  endfor
endfunction

function s:suite.parse_command_args_empty()
  let l:options = s:parse_options('')
  call s:assert.not_equals(l:options, v:null)
endfunction

function s:suite.parse_command_args_path_duplicated()
  for path in s:paths
    let l:args = path.in . ' ' . path.in
    let l:message = 'args:' . l:args

    let l:options = s:parse_options(l:args)
    call s:assert.equals(l:options, {}, l:message)
  endfor
endfunction

function s:suite.parse_command_args_option()
  let l:args = '-name="Test Name" -columns=indent,name,size'
  let l:message = 'args:' . l:args

  let l:options = s:parse_options(l:args)
  call s:assert.equals(l:options.name, 'Test Name', l:message)
  call s:assert.equals(l:options.columns, 'indent,name,size', l:message)
endfunction

function s:suite.parse_command_args_illegal_option()
  let l:args = '-name'
  let l:message = 'args:' . l:args

  let l:options = s:parse_options(l:args)
  call s:assert.equals(l:options, {}, l:message)

  let l:args = '-name='
  let l:message = 'args:' . l:args

  let l:options = s:parse_options(l:args)
  call s:assert.equals(l:options, {}, l:message)
endfunction

function s:suite.parse_command_args_flag_option()
  let l:args = '-auto-cd -listed'
  let l:message = 'args:' . l:args

  let l:options = s:parse_options(l:args)
  call s:assert.true(l:options.auto_cd, l:message)
  call s:assert.true(l:options.listed, l:message)

  let l:args = '-no-auto-cd -no-listed'
  let l:message = 'args:' . l:args

  let l:options = s:parse_options(l:args)
  call s:assert.false(l:options.auto_cd, l:message)
  call s:assert.false(l:options.listed, l:message)
endfunction

function s:suite.parse_command_args_illegal_flag_option()
  let l:args = '-auo-cd'
  let l:message = 'args:' . l:args

  let l:options = s:parse_options(l:args)
  call s:assert.equals(l:options, {}, l:message)

  let l:args = '-auto-cd=test'
  let l:message = 'args:' . l:args

  let l:options = s:parse_options(l:args)
  call s:assert.equals(l:options, {}, l:message)
endfunction
