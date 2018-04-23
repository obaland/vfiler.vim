"=============================================================================
" FILE: autoload/vfiler/exbuffer/list.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

let s:min_window_height = 5
let s:max_window_height_ratio = 50

" define keymappings
function! s:define_keymappings(readonly) abort
  nnoremap <buffer><silent><expr> <Plug>(vfiler_exbuffer_list_cursor_down)
        \ (line('.') == line('$')) ? 'gg0' : 'j'
  nnoremap <buffer><silent><expr> <Plug>(vfiler_exbuffer_list_cursor_up)
        \ (line('.') == 1) ? 'G0' : 'k'
  nnoremap <buffer><silent> <Plug>(vfiler_exbuffer_list_exit) :<C-u>call <SID>exit()<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_exbuffer_list_select) :<C-u>call <SID>select()<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_exbuffer_list_select_by_prompt)
        \ :<C-u>call <SID>select_by_prompt()<CR>

  if a:readonly
    nnoremap <buffer><silent> <Plug>(vfiler_exbuffer_list_delete)
          \ :<C-u>call <SID>disable()<CR>
  else
    nnoremap <buffer><silent> <Plug>(vfiler_exbuffer_list_delete)
          \ :<C-u>call <SID>delete()<CR>
  endif

  call vfiler#core#map_key('j',       'vfiler_exbuffer_list_cursor_down')
  call vfiler#core#map_key('k',       'vfiler_exbuffer_list_cursor_up')
  call vfiler#core#map_key('q',       'vfiler_exbuffer_list_exit')
  call vfiler#core#map_key('d',       'vfiler_exbuffer_list_delete')
  call vfiler#core#map_key(':',       'vfiler_exbuffer_list_select_by_prompt')
  call vfiler#core#map_key('<Enter>', 'vfiler_exbuffer_list_select')
endfunction

function! vfiler#exbuffer#list#record_bookmarks(paths) abort
  call vfiler#exbuffer#list#record_data(
        \ 'bookmark', a:paths, g:vfiler_max_number_of_bookmark
        \ )
endfunction

function! vfiler#exbuffer#list#record_data(data_name, contents, max_lines) abort
  let data_path = s:get_data_path(a:data_name)
  let lines = []
  if filereadable(data_path)
    let lines = readfile(data_path)
  endif

  for content in a:contents
    let lines = filter(lines, 'v:val !=# content')
  endfor
  let lines = extend(a:contents, lines)

  " shrink within the max number
  if len(lines) > a:max_lines
    let lines = lines[a:max_lines:]
  endif
  call writefile(lines, data_path)
endfunction

function! vfiler#exbuffer#list#create_options() abort
  return {
        \ 'bufname': '',
        \ 'callback': '',
        \ 'readonly': 1
        \ }
endfunction

function! vfiler#exbuffer#list#run_bookmark(context, options) abort
  call vfiler#exbuffer#list#run_from_data(a:context, 'bookmark', a:options)
endfunction

function! vfiler#exbuffer#list#run_from_data(context, data_name, options) abort
  let data_path = s:get_data_path(a:data_name)
  let lines = []
  if filereadable(data_path)
    let lines = readfile(data_path)
  endif

  let a:options['data_path'] = data_path
  call vfiler#exbuffer#list#run(a:context, lines, a:options)
endfunction

function! vfiler#exbuffer#list#run(context, items, options) abort
  let bufname = a:options.bufname
  let length = len(a:items)
  let winheight = float2nr(
        \ winheight(0) * (s:max_window_height_ratio / 100.0)
        \ )
  let winheight = min([winheight, length + 1])
  let winheight = max([winheight, s:min_window_height])

  silent split

  " Save swapfile option.
  let swapfile_save = &g:swapfile
  try
    set noswapfile
    silent execute 'edit ' . bufname
  finally
    let &g:swapfile = swapfile_save
  endtry

  " set buffer local options
  if exists('&colorcolumn')
    setlocal colorcolumn=
  endif

  setlocal laststatus=2
  setlocal bufhidden=hide
  setlocal buftype=nofile
  setlocal filetype=vfiler_list
  setlocal noswapfile
  setlocal noreadonly
  setlocal nowrap
  setlocal nospell
  setlocal foldcolumn=0
  setlocal nofoldenable
  setlocal nomodifiable
  setlocal nomodified
  setlocal nolist
  setlocal nonumber
  setlocal nobuflisted

  " resizing to the length of list
  call vfiler#core#resize_window_height(winheight)

  " draw list
  call s:draw(a:options.bufname, a:items)

  " define buffer environment
  call s:define_keymappings(a:options.readonly)

  syntax match vfilerExBufferList_Number '^\s*\d\+:\s\+'
  highlight! def link vfilerExBufferList_Number Constant

  " setup parameters
  let b:context = a:context
  let b:items = a:items
  let b:options = a:options
endfunction

" internal functions

function! s:draw(bufname, items) abort
  let length = len(a:items)
  let digit = vfiler#core#digit(length)

  setlocal modifiable
  setlocal noreadonly

  silent %delete _

  try
    for index in range(0, length - 1)
      let lnum = index + 1
      call setline(
            \ lnum,
            \ printf('%' . digit . 'd: %s', lnum, a:items[index])
            \ )
    endfor
  finally
    setlocal nomodifiable
    setlocal readonly
  endtry

  " display status line
  execute printf('setlocal statusline=vfiler/%s\ (%d)', a:bufname, length)
endfunction

function! s:get_data_path(data_name) abort
  let g:vfiler_data_directory_path = get(g:, 'vfiler_data_directory_path', '')
  if empty(g:vfiler_data_directory_path)
    let g:vfiler_data_directory_path = empty($XDG_CACHE_HOME) ?
          \ expand('~/.cache/vfiler') : $XDG_CACHE_HOME . '/vfiler'

    let g:vfiler_data_directory_path = substitute(
          \ fnamemodify(g:vfiler_data_directory_path, ':p'),
          \ '\\', '/', 'g'
          \ )
  endif

  if !isdirectory(g:vfiler_data_directory_path)
    call vfiler#core#mkdir(g:vfiler_data_directory_path, 'p')
  endif
  return g:vfiler_data_directory_path . a:data_name
endfunction

function! s:select(...) abort
  if !vfiler#buffer#exists(b:context.bufnr)
    call vfiler#core#error('Not exists filer buffer.')
    return
  endif

  let item = b:items[get(a:000, 0, line('.')) - 1]
  let context = getbufvar(b:context.bufnr, 'context')
  let callback = b:options.callback

  call s:exit()

  if !empty(callback)
    call call(callback, [context, item])
  endif
endfunction

function! s:delete() abort
  if empty(b:items)
    return
  endif

  let index = line('.') - 1
  call remove(b:items, index)
  call s:draw(b:options.bufname, b:items)
  call cursor(index + 1, 1)

  if !empty(b:options.data_path)
    call writefile(b:items, b:options.data_path)
  endif
endfunction

function! s:select_by_prompt(...) abort
  let length = len(b:items)
  let result = vfiler#core#input(printf('Number? (1 - %d)', length))
  if empty(result)
    return
  endif

  let number = str2nr(result)
  if number < 1 || length < number
    call vfiler#core#warning(
          \ printf('Please input number between 1 and %d.', length)
          \ )
    return
  endif

  call s:select(number)
endfunction

function! s:exit() abort
  " clear prompt message
  echo

  silent execute 'bwipeout ' . bufnr('%')
endfunction

function! s:disable() abort
  call vfiler#core#info('Disable operation.')
endfunction
