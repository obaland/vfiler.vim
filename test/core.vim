let s:suite = themis#suite('vfiler/configs')
let s:assert = themis#helper('assert')

function s:trancate(str, width, sep, footer_width)
  return luaevel(
        \ 'require"vfiler/core".trancate(_A.str, _A.width, _A.sep, _A.footer_width)',
        \ 
endfunction

function s:suite.trancate()
endfunction
