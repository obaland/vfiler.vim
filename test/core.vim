let s:suite = themis#suite('vfiler/configs')
let s:assert = themis#helper('assert')

function! s:truncate(str, width, sep, footer_width) abort
  return luaeval(
        \ 'require"vfiler/core".string.truncate(_A.str, _A.width, _A.sep, _A.fwidth)',
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
