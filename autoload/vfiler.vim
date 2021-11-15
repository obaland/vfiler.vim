"=============================================================================
" FILE: autoload/vfiler.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

function! vfiler#start_command(args) abort
  call luaeval('require"vfiler".start_command(_A)', a:args)
endfunction

function! vfiler#start(...) abort
  call luaeval(
        \ 'require"vfiler".start(_A.dirpath, _A.configs)',
        \ {'dirpath': get(a:000, 0, ''), 'configs': get(a:000, 1, {})}
        \ )
endfunction

function! vfiler#get_status_string() abort
  return luaeval('require"vfiler".get_status_string()')
endfunction

function! vfiler#complete(arglead, cmdline, cursorpos) abort
  return luaeval('require"vfiler".complete(_A)', a:arglead)
endfunction
