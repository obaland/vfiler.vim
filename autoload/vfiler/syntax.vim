"=============================================================================
" FILE: autoload/vfiler/syntax.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

let s:attribute_mark = {
      \ 'leaf': '/E',
      \ 'normal': '/N',
      \ 'selected': '/S',
      \ 'directory': '/D',
      \ 'link': '/L',
      \ 'hidden': '/H',
      \ 'today': '/T',
      \ 'week': '/W'
      \ }

let s:region_mark = {
      \ 'icon_start': '(/',
      \ 'icon_end': '/)',
      \ 'name_start': '{/',
      \ 'name_end': '/}',
      \ 'type_start': '</',
      \ 'type_end': '/>',
      \ 'size_start': '#/',
      \ 'size_end': '/#',
      \ 'time_start': '!/',
      \ 'time_end': '/!'
      \ }

function! vfiler#syntax#define() abort
  let r = s:region_mark
  let a = s:attribute_mark

  " define syntax leaf
  let leaf_pattern = printf('%s\s\+%s', a.leaf, g:vfiler_tree_leaf_icon)
  call s:define_syntax_match('vfilerLeaf', leaf_pattern)

  " define syntax icon
  let syntaxes = [
        \ ['vfilerSelected_Icon',   r.icon_start, r.icon_end, a.selected],
        \ ['vfilerDirectory_Icon',  r.icon_start, r.icon_end, a.directory],
        \ ['vfilerSelected_Name',   r.name_start, r.name_end, a.selected],
        \ ['vfilerFile_Name',       r.name_start, r.name_end, a.normal],
        \ ['vfilerDirectory_Name',  r.name_start, r.name_end, a.directory],
        \ ['vfilerLink_Name',       r.name_start, r.name_end, a.link],
        \ ['vfilerHidden_Name',     r.name_start, r.name_end, a.hidden],
        \ ['vfilerFile_Type',       r.type_start, r.type_end, a.normal],
        \ ['vfilerDirectory_Type',  r.type_start, r.type_end, a.directory],
        \ ['vfilerLink_Type',       r.type_start, r.type_end, a.link],
        \ ['vfilerHidden_Type',     r.type_start, r.type_end, a.hidden],
        \ ['vfilerSize',            r.size_start, r.size_end, ''],
        \ ['vfilerTime',            r.time_start, r.time_end, a.normal],
        \ ['vfilerTimeToday',       r.time_start, r.time_end, a.today],
        \ ['vfilerTimeWeek',        r.time_start, r.time_end, a.week]
        \ ]
  for [group, start, end, mark] in syntaxes
    call s:define_syntax_match(
          \ group, s:generate_interpose_pattern(start, end, mark)
          \ )
  endfor

  " define parent directory special word
  syntax match vfilerDirectory_SpecialWord '^\.\./'

  " define ignore marks
  let ignores = []
  call extend(ignores, values(s:attribute_mark))
  call extend(ignores, values(s:region_mark))

  let ignore_pattern = '\%(' . join(ignores, '\|') . '\)'
  execute 'syntax match vfilerMark_Ignore ''' .
        \ ignore_pattern . ''' conceal contained'

  " highlight links
  highlight! link vfilerFile_Name vfilerFile

  highlight! link vfilerSelected_Icon vfilerSelected
  highlight! link vfilerSelected_Name vfilerSelected

  highlight! link vfilerLeaf vfilerDirectory
  highlight! link vfilerDirectory_Icon vfilerDirectory
  highlight! link vfilerDirectory_Name vfilerDirectory
  highlight! link vfilerDirectory_Type vfilerDirectory
  highlight! link vfilerDirectory_SpecialWord vfilerDirectory

  highlight! link vfilerLink_Name vfilerLink
  highlight! link vfilerLink_Type vfilerLink

  highlight! link vfilerHidden_Name vfilerHidden
  highlight! link vfilerHidden_Type vfilerHidden

  highlight! link vfilerMark_Ignore Ignore
endfunction

function! vfiler#syntax#append_mark_to_leaf(element, str_leaf) abort
  return s:attribute_mark.leaf . a:str_leaf
endfunction

function! vfiler#syntax#append_mark_to_icon(element, str_icon) abort
  let mark = ''
  if a:element.selected
    let mark = s:attribute_mark.selected
  elseif a:element.isdirectory
    let mark = s:attribute_mark.directory
  else
    return a:str_icon
  endif
  return s:interpose_to_mark(
        \ a:str_icon, s:region_mark.icon_start, s:region_mark.icon_end, mark
        \ )
endfunction

function! vfiler#syntax#append_mark_to_name(element, str_name) abort
  let mark = s:attribute_mark.normal
  let type = a:element.type

  if a:element.selected
    let mark = s:attribute_mark.selected
  elseif match(a:str_name, '^\.') >= 0
    " hidden file
    let mark = s:attribute_mark.hidden
  elseif type ==# 'D'
    let mark = s:attribute_mark.directory
  elseif type ==# 'L'
    let mark = s:attribute_mark.link
  endif
  return s:interpose_to_mark(
        \ a:str_name, s:region_mark.name_start, s:region_mark.name_end, mark
        \ )
endfunction

function! vfiler#syntax#append_mark_to_type(element, str_type) abort
  let mark = s:attribute_mark.normal
  let type = a:element.type

  if match(a:element.name, '^\.') >= 0
    " hidden file
    let mark = s:attribute_mark.hidden
  elseif type ==# 'D'
    let mark = s:attribute_mark.directory
  elseif type ==# 'L'
    let mark = s:attribute_mark.link
  endif
  return s:interpose_to_mark(
        \ a:str_type, s:region_mark.type_start, s:region_mark.type_end, mark
        \ )
endfunction

function! vfiler#syntax#append_mark_to_size(element, str_size) abort
  return s:interpose_to_mark(
        \ a:str_size, s:region_mark.size_start, s:region_mark.size_end
        \ )
endfunction

function! vfiler#syntax#append_mark_to_time(element, str_time) abort
  let mark = s:attribute_mark.normal
  let subtime = localtime() - a:element.time

  if subtime < 86400
    " 1day = 60 * 60 * 24 = 86400
    let mark = s:attribute_mark.today
  elseif subtime < 604800
    " 1week = 86400 * 7 = 604800
    let mark = s:attribute_mark.week
  endif
  return s:interpose_to_mark(
        \ a:str_time, s:region_mark.time_start, s:region_mark.time_end, mark
        \ )
endfunction

function! s:get_type_region_mark(element) abort
  let type = a:element.type 
  if match(a:element.name, '^\.') >= 0
    " hidden file
    let end = s:syntax_type_mark_end_hidden
  elseif type ==# 'D'
    let mark = s:syntax_name_mark_directory
  elseif type ==# 'L'
    let mark = s:syntax_name_mark_link
  endif
  return a:str_name . mark
endfunction

function! s:interpose_to_mark(content, start, end, ...) abort
  let prefix_mark = get(a:000, 0, '')
  return prefix_mark . a:start . a:content . a:end
endfunction

function! s:generate_interpose_pattern(start, end, mark) abort
  return s:interpose_to_mark('.\+', a:start, a:end, a:mark)
endfunction

function! s:define_syntax_match(syntax, pattern) abort
  execute printf(
        \ 'syntax match %s ''%s'' contains=vfilerMark_Ignore',
        \ a:syntax, a:pattern
        \ )
endfunction
