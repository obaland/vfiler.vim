"=============================================================================
" FILE: autoload/vfiler.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

function! vfiler#start(args) abort
  call luaeval('require"vfiler".start_command(_A)', a:args)
endfunction

function! vfiler#get_status_string() abort
  return luaeval('require"vfiler".get_status_string()')
endfunction

function! vfiler#complete(arglead, cmdline, cursorpos) abort
  return luaeval('require"vfiler".complete(_A)', a:arglead)
endfunction
