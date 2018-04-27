"=============================================================================
" FILE: autoload/vfiler/element.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

function! vfiler#element#create(path, level) abort
  let element = {
        \ 'selected': 0,
        \ 'opened': 0,
        \ 'path': vfiler#core#normalized_path(a:path),
        \ 'level': a:level,
        \ 'type': s:get_type(a:path),
        \ 'size': getfsize(a:path),
        \ 'time': getftime(a:path),
        \ 'isdirectory': isdirectory(a:path),
        \ 'children': []
        \ }

  " set element name
  let element.name = element.isdirectory ?
        \ fnamemodify(a:path, ':t') : fnamemodify(a:path, ':p:t')

  return element
endfunction

function! vfiler#element#rename(element, name) abort
  let parent_path = fnamemodify(a:element.path, ':h')
  let a:element.path = vfiler#core#normalized_path(
        \ fnamemodify(parent_path, ':p') . a:name
        \ )
  let a:element.name = a:name
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
    call vfiler#core#error('Unknown file type (' . type . ')')
  endif
  return ''
endfunction
