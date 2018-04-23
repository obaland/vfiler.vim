"=============================================================================
" FILE: autoload/vfiler/element.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

let s:element_parent_directory_word = '../'

function! vfiler#element#create(path, level) abort
  return {
        \ 'selected': 0,
        \ 'opened': 0,
        \ 'path': fnamemodify(a:path, ':p'),
        \ 'level': a:level,
        \ 'type': s:get_type(a:path),
        \ 'size': getfsize(a:path),
        \ 'time': getftime(a:path),
        \ 'name': fnamemodify(a:path, ':t'),
        \ 'isdirectory': isdirectory(a:path),
        \ 'children': []
        \ }
endfunction

function! vfiler#element#create_parent_directory(current_path) abort
  let element = vfiler#element#create(a:current_path, 0)
  let element.name = s:element_parent_directory_word
  return element
endfunction

function! vfiler#element#rename(element, name) abort
  let parent_path = vfiler#core#get_parent_directory_path(a:element.path)
  let a:element.path = vfiler#core#normalized_path(
        \ parent_path . a:name, a:element.isdirectory
        \ )
  let a:element.name = a:name
endfunction

function! vfiler#element#parent_directory_word() abort
  return s:element_parent_directory_word
endfunction

function! s:get_type(path) abort
  let type = getftype(a:path)
  if type ==# 'dir'
    return 'D'
  elseif type ==# 'file'
    return 'F'
  elseif type ==# 'link'
    return 'L'
  else
    call vfiler#core#error('Unknown file type (' . type ')')
  endif
  return ''
endfunction
