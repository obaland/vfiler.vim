"=============================================================================
" FILE: autoload/vfiler.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

function! vfiler#start_command(args) abort
  let configs = vfiler#configs#parse(a:args)
  let options = configs.options
  call vfiler#start(configs.path, options)
endfunction

function! vfiler#start(path, options) abort
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
    let dir = fnamemodify(bufname(a:bufnr), ':p:h')
  endif
  return dir
endfunction

function! vfiler#complete(ArgLead, CmdLine, CursorPos) abort
  let cmdoptions = vfiler#configs#get_command_options()
  echo cmdoptions
endfunction

