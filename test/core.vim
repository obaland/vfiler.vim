let s:suite = themis#suite('vfiler/configs')
let s:assert = themis#helper('assert')

"-----------------------------------------------------------------------------
" string
"-----------------------------------------------------------------------------

function! s:truncate(str, width, sep, footer_width) abort
  return luaeval(
        \ 'require("vfiler/core").string.truncate(_A.str, _A.width, _A.sep, _A.fwidth)',
        \ {'str': a:str, 'width': a:width, 'sep': a:sep, 'fwidth': a:footer_width}
        \ )
endfunction

function s:suite.truncate1()
  let l:string1 = 'abcdefghijklmnopqrstuvwxyz'
  let l:string2 = 'あいうえおかきくけこさしすせそたちつてと'

  let l:actual = s:truncate(l:string1, 26, '..', 0)
  call s:assert.equals(l:actual, 'abcdefghijklmnopqrstuvwxyz')

  let l:actual = s:truncate(l:string1, 27, '..', 0)
  call s:assert.equals(l:actual, 'abcdefghijklmnopqrstuvwxyz')

  let l:actual = s:truncate(l:string1, 25, '..', 0)
  call s:assert.equals(l:actual, 'abcdefghijklmnopqrstuvw..')

  let l:actual = s:truncate(l:string2, 40, '..', 0)
  call s:assert.equals(l:actual, 'あいうえおかきくけこさしすせそたちつてと')

  let l:actual = s:truncate(l:string2, 41, '..', 0)
  call s:assert.equals(l:actual, 'あいうえおかきくけこさしすせそたちつてと')

  let l:actual = s:truncate(l:string2, 39, '..', 0)
  call s:assert.equals(l:actual, 'あいうえおかきくけこさしすせそたちつ..')
endfunction

function s:suite.truncate2()
  let l:string1 = 'abcdefghijklmnopqrstuvwxyz'
  let l:string2 = 'あいうえおかきくけこさしすせそたちつてと'

  let l:actual = s:truncate(l:string1, 26, '..', 13)
  call s:assert.equals(l:actual, 'abcdefghijklmnopqrstuvwxyz')

  let l:actual = s:truncate(l:string1, 27, '..', 13)
  call s:assert.equals(l:actual, 'abcdefghijklmnopqrstuvwxyz')

  let l:actual = s:truncate(l:string1, 25, '..', 12)
  call s:assert.equals(l:actual, 'abcdefghijk..opqrstuvwxyz')

  let l:actual = s:truncate(l:string2, 40, '..', 20)
  call s:assert.equals(l:actual, 'あいうえおかきくけこさしすせそたちつてと')

  let l:actual = s:truncate(l:string2, 41, '..', 20)
  call s:assert.equals(l:actual, 'あいうえおかきくけこさしすせそたちつてと')

  let l:actual = s:truncate(l:string2, 39, '..', 18)
  call s:assert.equals(l:actual, 'あいうえおかきくけ..しすせそたちつてと')
endfunction

"-----------------------------------------------------------------------------
" path
"-----------------------------------------------------------------------------

function! s:path_join(path, name)
  return luaeval(
        \ 'require("vfiler/core").path.join(_A.path, _A.name)',
        \ {'path': a:path, 'name': a:name }
        \ )
endfunction

function s:suite.path_join()
  let l:list = [
        \ {'path': '/', 'name': 'home/test', 'expected': '/home/test' },
        \ {'path': 'C:\', 'name': 'home/test', 'expected': 'C:/home/test' },
        \ {'path': 'C:', 'name': '/test\foo/bar', 'expected': 'C:/test/foo/bar' },
        \ {'path': '/home', 'name': 'test/foo/bar', 'expected': '/home/test/foo/bar' },
        \ {'path': '/home', 'name': 'test/foo/bar/', 'expected': '/home/test/foo/bar/' },
        \ ]

  for item in l:list
    let l:actual = s:path_join(item.path, item.name)
    call s:assert.equals(l:actual, item.expected)
  endfor
endfunction

"-----------------------------------------------------------------------------
" math
"-----------------------------------------------------------------------------

function! s:math_within(v, min, max)
  return luaeval(
        \ 'require("vfiler/core").math.within(_A.v, _A.min, _A.max)',
        \ {'v': a:v, 'min': a:min, 'max': a:max }
        \ )
endfunction

function! s:suite.math_within()
  let l:list = [
        \ {'v': 10, 'min':  5, 'max': 20, 'expected': 10},
        \ {'v':  4, 'min':  5, 'max': 20, 'expected':  5},
        \ {'v': 21, 'min':  5, 'max': 20, 'expected': 20},
        \ {'v': -4, 'min': -5, 'max': 20, 'expected': -4},
        \ {'v': -6, 'min': -5, 'max': 20, 'expected': -5},
        \ {'v': -6, 'min': -8, 'max': -5, 'expected': -6},
        \ {'v': -9, 'min': -8, 'max': -5, 'expected': -8},
        \ {'v': -4, 'min': -8, 'max': -5, 'expected': -5},
        \ ]

  for item in l:list
    let l:actual = s:math_within(item.v, item.min, item.max)
    call s:assert.equals(l:actual, item.expected)
  endfor
endfunction
