"=============================================================================
" FILE: autoload/vfiler/popup.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

function! vfiler#popup#filter(winid, key) abort
  return luaeval(
        \ 'require("vfiler/extensions/views/popup")._filter(_A.winid, _A.key)',
        \ {'winid': a:winid, 'key': a:key}
        \ )
endfunction
