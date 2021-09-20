let s:suite = themis#suite('vfiler/configs')
let s:assert = themis#helper('assert')

let s:paths = [
      \ {'in': '/test/a/b', 'out': '/test/a/b'},
      \ {'in': '/test/a\ b/c', 'out': '/test/a b/c'},
      \ {'in': 'C:\test\a\b', 'out': 'C:\test\a\b'},
      \ {'in': '"C:\test\a b\c', 'out': 'C:\test\a b\c'},
      \ ]

function s:suite.parse_command_args1()
  for path in s:paths
    let l:args = '-auto-cd ' . path.in
    let l:configs = vfiler#parse_command_args(l:args)
    call s:asserr.same(l:configs.path, path.out)
    call s:assert.true(l:configs.auto_cd)
  endfor
endfunction
