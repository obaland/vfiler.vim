"=============================================================================
" FILE: autoload/extensions/bookmark.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

function! vfiler#extensions#bookmark#complete(arglead, cmdline, cursorpos)
  return luaeval('require("vfiler/extensions/bookmark").complete(_A)', a:arglead)
endfunction
