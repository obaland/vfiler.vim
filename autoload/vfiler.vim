"=============================================================================
" FILE: autoload/vfiler.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

function! s:parse_command_args(args) abort
  let l:configs = {}
  let l:configs.path = a:args
  return l:configs
endfunction

function! vfiler#start_command_legacy(args) abort
  let configs = vfiler#configs#parse_legacy(a:args)
  let options = configs.options
  call vfiler#start_legacy(configs.path, options)
endfunction

function! vfiler#parse_command_args(args) abort
  return luaeval('require"vfiler".parse_command_args(_A)', a:args)
endfunction

function! vfiler#start_command(args) abort
  call luaeval('require"vfiler".start_command(_A)', a:args)
endfunction

function! vfiler#start(...) abort
  call luaeval('require"vfiler".start(_A)', get(a:000, 0, {}))
endfunction

function! vfiler#do_action(name, ...) abort
  call luaeval(
        \ 'require"vfiler".do_action(_A.name, _A.args)',
        \ {'name': a:name, 'args': a:000}
        \ )
endfunction

function! vfiler#start_legacy(path, options) abort
  let result = vfiler#buffer#open(a:options.buffer_name)
  if result.bufnr > 0
    if empty(vfiler#context#get_context(result.bufnr))
      call vfiler#core#error('Not exists context.')
    endif
    call vfiler#action#switch_to_directory(a:path)
    return
  endif

  " split window
  let open_action = a:options.split ? 'topleft vsplit' : ''
  call vfiler#action#start(a:path, a:options, open_action)
endfunction

function! vfiler#get_status_string() abort
  if empty(getbufvar(bufnr('%'), 'context'))
    return ''
  endif

  " safe mode status
  let status = b:context.safe_mode ? '*safe* | ' : ''

  " current path
  let status .= b:context.path

  return status
endfunction

function! vfiler#get_buffer_directory_path(bufnr) abort
  if vfiler#buffer#exists(a:bufnr)
    let dir = vfiler#context#get_context(a:bufnr).path
  else
    let dir = bufname(a:bufnr)
    let dir = fnamemodify(isdirectory(dir) ? dir : getcwd(), ':p:h')
  endif
  return dir
endfunction

function! vfiler#complete(arglead, cmdline, cursorpos) abort
  " complete option
  if len(a:arglead) > 0 && a:arglead[0] ==# '-'
    let options = vfiler#configs#get_command_options()
    return sort(filter(options, 'stridx(v:val, a:arglead) == 0'))
  endif

  " complete dir
  let condidate_files = glob(a:arglead . '*', 1, 1, 1)
  return sort(map(filter(
        \ condidate_files, 'isdirectory(v:val)'),
        \ "v:val . '/'"))
endfunction
