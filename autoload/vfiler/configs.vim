"=============================================================================
" FILE: autoload/vfiler/configs.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

let s:default_key_value_options = {
      \ 'buffer_name': '',
      \ 'winwidth': 0
      \ }

let s:default_flag_options = {
      \ 'auto_cd': g:vfiler_auto_cd,
      \ 'explorer': 0,
      \ 'simple': 0,
      \ 'split': 0
      \ }

let s:default_options = {
      \ 'visible_hidden_files': g:vfiler_visible_hidden_files,
      \ 'safe_mode': g:vfiler_safe_mode,
      \ 'display_current_directory_on_top': g:vfiler_display_current_directory_on_top
      \ }

let s:command_options =
      \ map(keys(extend(
      \   copy(s:default_key_value_options),
      \   s:default_flag_options
      \ )), "'-' . substitute(v:val, '_', '-', 'g')")

function! vfiler#configs#get_command_options() abort
  return copy(s:command_options)
endfunction

function! vfiler#configs#create_options() abort
  " combine default options
  let options = copy(s:default_options)
  return extend(
        \ extend(options, s:default_flag_options),
        \ s:default_key_value_options
        \ )
endfunction

function! vfiler#configs#parse(command_args) abort
  let configs = s:parse_command_args(a:command_args)

  " merge options
  let key_value_options = copy(s:default_key_value_options)
  let flag_options = copy(s:default_flag_options)
  for option in keys(configs.options)
    if has_key(key_value_options, option)
      let key_value_options[option] = configs.options[option]
      continue
    endif

    if has_key(flag_options, option)
      let flag_options[option] = 1
    endif
  endfor

  " combine each options
  let options = copy(s:default_options)
  let options = extend(
        \ extend(options, flag_options),
        \ key_value_options
        \ )

  " decide split window width
  if options.split && options.winwidth <= 0
    let options.winwidth = winwidth(0) / 2
  endif

  " set options related to 'explorer' option
  if options.explorer
    let options.split = 1
    let options.simple = 1
    let options.winwidth = 36

    if empty(options.buffer_name)
      let options.buffer_name = 'explorer'
    endif
  endif

  return {
        \ 'path': configs.path,
        \ 'options': options
        \ }
endfunction

" internal functions "{{{

function! s:parse_command_args(args) abort
  let args = a:args

  " split options and path
  let options = {}
  while match(args, '^-') >= 0
    let arg = matchstr(args, '^-\S\+')
    let arg = substitute(arg, '\\\( \)', '\1', 'g')
    let arg_key = substitute(
          \ substitute(arg, '=\zs.*$', '', ''),
          \ '-', '_', 'g'
          \ )
    let option = substitute(arg_key, '=$', '', '')[1:]
    let value = (arg_key =~# '=$') ? arg[len(arg_key):] : ''
    let options[option] = value

    let args = substitute(args, arg . '\s*', '', '')
  endwhile

  " set the rest of argument as path
  let path = empty(args) ? getcwd() : expand(args)
  if !isdirectory(path)
    call vfiler#core#error('Not directory path - ' . path)
    let options.path = getcwd()
  endif

  return {
        \ 'path': path,
        \ 'options': options
        \ }
endfunction

"}}}
