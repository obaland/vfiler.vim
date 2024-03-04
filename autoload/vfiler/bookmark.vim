"=============================================================================
" FILE: autoload/bookmark.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

function! vfiler#bookmark#complete(arglead, cmdline, cursorpos) abort
  return luaeval(
        \ 'require("vfiler/extensions/bookmark").complete(_A)',
        \ a:arglead
        \ )
endfunction
