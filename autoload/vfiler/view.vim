"=============================================================================
" FILE: autoload/vfiler/view.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

function! vfiler#view#draw(context) abort
  let wwidth = s:get_wwidth()
  let columns = vfiler#column#create(a:context, wwidth)
  let elements = b:context.view_elements

  " first element is current directory
  let current_path = vfiler#core#truncate_skipping(
        \ fnamemodify(elements[0].path, ':p'),
        \ wwidth, wwidth, '<'
        \ )

  let lines = [current_path]
  for index in range(1, len(elements) - 1)
    call add(lines, s:print_line(elements[index], columns))
  endfor

  let saved_view = winsaveview()

  setlocal modifiable
  setlocal noreadonly

  silent %delete _

  try
    call setline(1, lines)
  finally
    setlocal nomodifiable
    setlocal readonly
  endtry

  call winrestview(saved_view)
endfunction

function! vfiler#view#draw_line(context, index) abort
  let wwidth = s:get_wwidth()
  let columns = vfiler#column#create(a:context, wwidth)
  let line = s:print_line(
        \ vfiler#context#get_element(a:context, a:index),
        \ columns
        \ )

  setlocal modifiable
  setlocal noreadonly

  try
    call setline(a:index + 1, line)
  finally
    setlocal nomodifiable
    setlocal readonly
  endtry
endfunction

" internal functions "{{{

function! s:get_wwidth() abort
  " calculate window width
  let wwidth = winwidth(0)
  if &l:number || (exists('&relativenumber') && &l:relativenumber)
    let wwidth -= &l:numberwidth
  endif
  let wwidth -= &l:foldcolumn

  " offset for window right edge
  return wwidth - 1
endfunction

function! s:print_line(element, columns) abort
  " print header
  let line = s:print_leaf(a:element) . s:print_icon(a:element)

  for column in a:columns
    let line .= column.offset_str .
          \ call(function('s:print_' . column.type), [a:element, column])
  endfor
  return line
endfunction

function! s:print_leaf(...) abort
  let element = a:1
  if element.level == 0
    return ''
  endif

  " nest offset
  return vfiler#syntax#append_mark_to_leaf(
        \ element, s:padding(element.level) . g:vfiler_tree_leaf_icon
        \ )
endfunction

function! s:print_icon(...) abort
  let element = a:1

  let icon = ' '
  if element.selected
    let icon = g:vfiler_marked_file_icon
  elseif element.isdirectory
    let icon = element.opened ? g:vfiler_tree_opened_icon : g:vfiler_tree_closed_icon
  endif
  return vfiler#syntax#append_mark_to_icon(element, icon)
endfunction

function! s:print_name(...) abort
  let element = a:1
  let column = a:2
  let name = element.name . (element.isdirectory ? '/' : '')

  let cwidth = column.width
  if element.level > 0
    let cwidth -= element.level + strwidth(g:vfiler_tree_leaf_icon)
  endif

  if cwidth < strwidth(name)
    let name = vfiler#core#truncate_skipping(
          \ name, cwidth, cwidth / 2, '..'
          \ )
  endif

  let padding = s:padding(cwidth - strwidth(name))
  return vfiler#syntax#append_mark_to_name(element, name) . padding
endfunction

function! s:print_type(...) abort
  let element = a:1
  return vfiler#syntax#append_mark_to_type(element, '[' . element.type . ']')
endfunction

function! s:print_size(...) abort
  let element = a:1
  let column = a:2
  let size = element.size

  if element.isdirectory
    return s:padding(column.width)
  endif

  " size unit:
  "   'B'->bytes
  "   'K'->Kiro bytes
  "   'M'->Mega bytes
  "   'T'->Tera bytes
  let units = ['K', 'M', 'G', 'T']
  let unit = 'B'

  for current_unit in units
    if trunc(size) < 1000
      break
    endif
    let size = size / 1024.0
    let unit = current_unit
  endfor

  let int = float2nr(size)
  let float = float2nr((size - int) * 100)

  if float == 0
    let value = printf('%5d', int)
  elseif int < 100
    let value = printf('%2d.%02d', int, float)
  else
    let value = printf('%3d.%01d', int, float / 10)
  endif
  return vfiler#syntax#append_mark_to_size(element, value . unit)
endfunction

function! s:print_time(...) abort
  let element = a:1
  let time = element.time
  return vfiler#syntax#append_mark_to_time(
        \ element, strftime(g:vfiler_time_format, time)
        \ )
endfunction

function! s:padding(count) abort
  return repeat(' ', a:count)
endfunction

"}}}
