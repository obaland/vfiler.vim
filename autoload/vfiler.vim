"=============================================================================
" FILE: autoload/vfiler.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

function! vfiler#complete(arglead, cmdline, cursorpos) abort
  let list = luaeval(
        \ 'require("vfiler/config").complete(_A)', a:arglead
        \ )
  if len(list) > 0
    return list
  endif
  return map(getcompletion(a:arglead, 'dir'), {-> escape(v:val, ' ')})
endfunction

function! vfiler#start(path) abort
  call luaeval('require("vfiler").start(_A)', a:path)
endfunction

function! vfiler#start_command(args) abort
  call luaeval('require("vfiler").start_command(_A)', a:args)
endfunction

function! vfiler#status(bufnr) abort
  return luaeval('require("vfiler").status(_A)', a:bufnr)
endfunction
