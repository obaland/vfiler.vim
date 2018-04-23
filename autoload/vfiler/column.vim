"=============================================================================
" FILE: autoload/vfiler/column.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

let s:time_width = strwidth(strftime(g:vfiler_time_format, 0))
let s:size_width = strwidth('000.0U')
let s:type_width = strwidth('[X]')

let s:icon_width = max([
      \   strwidth(g:vfiler_tree_opened_icon),
      \   strwidth(g:vfiler_tree_closed_icon)
      \ ])

" mark + offset
let s:line_start_offset = s:icon_width + 1
" leaf icon + icon + offset
let s:nest_offset = strwidth(g:vfiler_tree_leaf_icon) + s:icon_width + 1

" minimum file name: X..X/
let s:min_name_width = 8

let s:default_attributes = [
      \ {'type': 'time', 'width': s:time_width, 'offset': 1},
      \ {'type': 'size', 'width': s:size_width, 'offset': 1},
      \ {'type': 'type', 'width': s:type_width, 'offset': 1}
      \ ]

function! vfiler#column#create(context) abort
  " calculate window width
  let wwidth = winwidth(0)
  if &l:number || (exists('&relativenumber') && &l:relativenumber)
    let wwidth -= &l:numberwidth
  endif
  let wwidth -= &l:foldcolumn
  let wwidth -= 1 " offset for window right edge

  " load columns cache
  let cached_colums = vfiler#context#load_columns_cache(a:context, wwidth)
  if !empty(cached_colums)
    return cached_colums
  endif

  let columns = s:create_columns(
        \ a:context,
        \ deepcopy(s:default_attributes),
        \ wwidth
        \ )
  call vfiler#context#save_columns_cache(a:context, wwidth, columns)
  return columns
endfunction

" internal functions "{{{

function! s:create_columns(context, attributes, wwidth) abort
  " simple mode column (only name)
  if a:context.simple
    return [s:create_name_column(
          \ a:wwidth - s:line_start_offset, s:line_start_offset
          \ )]
  endif

  let columns = []
  let rest_width = a:wwidth

  for attribute in a:attributes
    let column = s:create_column(
          \ attribute, rest_width - attribute.width
          \ )
    call insert(columns, column, 0)
    let rest_width -= attribute.width + attribute.offset
  endfor

  let name_width = rest_width - s:line_start_offset
  let max_level_name_width = name_width - (a:context.max_level + s:nest_offset)
  if max_level_name_width < s:min_name_width
    call remove(a:attributes, 0)
    if !empty(a:attributes)
      " recursive call
      return s:create_columns(a:context, a:attributes, a:wwidth)
    endif
  endif

  " add name column
  return insert(
        \ columns,
        \ s:create_name_column(name_width, s:line_start_offset)
        \ )
endfunction

function! s:create_column(attribute, start_pos) abort
  return {
        \ 'type': a:attribute.type,
        \ 'width': a:attribute.width,
        \ 'start': a:start_pos,
        \ 'offset': a:attribute.offset,
        \ 'offset_str': repeat(' ', a:attribute.offset)
        \ }
endfunction

function! s:create_name_column(width, start_pos) abort
  return {
        \ 'type': 'name',
        \ 'width': a:width,
        \ 'start': a:start_pos,
        \ 'offset': 1,
        \ 'offset_str': ' '
        \ }
endfunction

"}}}
