"=============================================================================
" FILE: autoload/vfiler/context.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

function! vfiler#context#create(path, options) abort
  let context = {
        \ 'max_level': 0,
        \ 'path': a:path,
        \ 'sort_type': 'filename',
        \ 'sort_order': 0,
        \ 'bufnr': bufnr('%'),
        \ 'alternate_bufnr': -1,
        \ 'caches': s:create_caches()
        \ }

  " apply options
  let default_options = vfiler#configs#create_options()
  for option in keys(default_options)
    let context[option] = a:options[option]
  endfor
  call vfiler#context#switch(context, a:path)
  return context
endfunction

function! vfiler#context#create_alternate(source) abort
  let alternate = vfiler#context#create(a:source.path, a:source)

  " link each bufnr
  let alternate.alternate_bufnr = a:source.bufnr
  let a:source.alternate_bufnr = alternate.bufnr

  return alternate
endfunction

function! vfiler#context#is_active(context) abort
  return bufwinnr(a:context.bufnr) > 0
endfunction

function! vfiler#context#is_active_alternate(source) abort
  return bufwinnr(a:source.alternate_bufnr) > 0
endfunction

function! vfiler#context#get_context(bufnr) abort
  return getbufvar(a:bufnr, 'context')
endfunction

function! vfiler#context#get_alternate_context(source) abort
  return vfiler#context#get_context(a:source.alternate_bufnr)
endfunction

function! vfiler#context#update(context) abort
  let elements = s:update_elements_all_levels(
        \ a:context, a:context.path, a:context.elements
        \ )
  let view_elements = s:to_view_elements(elements)

  let a:context.elements = elements
  let a:context.view_elements = view_elements
endfunction

function! vfiler#context#switch(context, path) abort
  let a:context.path = a:path
  let a:context.elements = s:create_elements(a:context, a:path)
  let a:context.view_elements = a:context.elements
  call s:post_switch_path(a:context)
  return a:context
endfunction

function! vfiler#context#get_element_count(context) abort
  return len(a:context.view_elements)
endfunction

function! vfiler#context#get_element(context, index) abort
  return a:context.view_elements[a:index]
endfunction

function! vfiler#context#get_marked_elements(context) abort
  return filter(copy(a:context.view_elements), 'v:val.selected')
endfunction

function! vfiler#context#change_sort(context, type, order) abort
  if (a:context.sort_type ==# a:type) &&
        \ (a:context.sort_order == a:order)
    " no change
    return 0
  endif

  let a:context.sort_type = a:type
  let a:context.sort_order = a:order
  call vfiler#context#update(b:context)
  return 1
endfunction

function! vfiler#context#toggle_safe_mode(context) abort
  let a:context.safe_mode = !a:context.safe_mode
  return a:context.safe_mode
endfunction

function! vfiler#context#expand_directory_tree(context, index) abort
  let target = a:context.view_elements[a:index]
  if !target.isdirectory || target.opened
    return
  endif

  let level = target.level + 1
  let elements = s:create_elements(
        \ a:context, target.path, level
        \ )

  " link children elements
  let a:context.view_elements[a:index].children = elements
  call extend(a:context.view_elements, elements, a:index + 1)

  let target.opened = 1
  let a:context.max_level = max([a:context.max_level, level])

  return elements
endfunction

function! vfiler#context#unexpand_directory_tree(context, index) abort
  let elements = a:context.view_elements
  let target = elements[a:index]

  " find parent
  let level = target.level
  let parent_index = -1
  if target.isdirectory && target.opened
    let parent_index = a:index
  else
    let level = max([level - 1, 0])
    for i in range(a:index, 0, -1)
      let element = elements[i]
      if element.level == level && element.opened
        let parent_index = i
        break
      endif
    endfor
  endif

  if parent_index < 0
    return {}
  endif

  let parent = elements[parent_index]
  let parent.opened = 0

  if empty(parent.children)
    return parent
  endif

  " find next same level
  let next_index = -1
  let last_index = len(elements) - 1
  if a:index == last_index
    let next_index = a:index
  else
    for i in range(a:index + 1, last_index)
      if elements[i].level <= level
        let next_index = i
        break
      endif
    endfor

    if next_index < 0
      let next_index = last_index
    endif
  endif

  " clear children elements
  let parent.children = []
  call remove(elements, parent_index + 1, next_index - 1)

  " update max level
  let a:context.max_level = s:get_max_level(a:context.view_elements)

  return parent
endfunction

function! vfiler#context#save_columns_cache(context, winwidth, columns)
  let caches = b:context.caches
  let caches.winwidth = a:winwidth
  let caches.max_level = a:context.max_level
  let caches.simple = a:context.simple
  let caches.columns = deepcopy(a:columns)
endfunction

function! vfiler#context#load_columns_cache(context, winwidth)
  let caches = b:context.caches
  if (caches.winwidth != a:winwidth) ||
        \ (caches.max_level != b:context.max_level) ||
        \ (caches.simple != b:context.simple)
    return {}
  endif
  return caches.columns
endfunction

function! vfiler#context#save_index_cache(context, path)
  let current_path = a:context.path
  let a:context.caches.index[current_path] = a:path
endfunction

function! vfiler#context#load_index_cache(context)
  let current_path = a:context.path
  if !has_key(a:context.caches.index, current_path)
    return -1
  endif

  " exclude special element
  let path = a:context.caches.index[current_path]
  let elements = a:context.view_elements
  for index in range(0, len(elements) - 1)
    if elements[index].path ==# path
      return index
    endif
  endfor
  return -1
endfunction

function! vfiler#context#toggle_visible_hidden_files(context) abort
  let a:context.visible_hidden_files = !a:context.visible_hidden_files
  call vfiler#context#update(a:context)
  return a:context
endfunction

function! vfiler#context#toggle_mark(context, index) abort
  " exclude special element
  if a:index == 0
    return
  endif
  let element = a:context.view_elements[a:index]
  let element.selected = !element.selected
endfunction

function! vfiler#context#toggle_mark_all(context) abort
  let elements = a:context.view_elements

  for index in range(0, len(elements) - 1)
    let element = elements[index]
    let element.selected = !element.selected
  endfor
endfunction

function! vfiler#context#clear_mark_all(context) abort
  for element in b:context.view_elements
    let element.selected = 0
  endfor
endfunction

" internal functions "{{{

function! s:post_switch_path(context) abort
  " perform auto cd
  if a:context.auto_cd
    silent execute 'lcd ' . a:context.path
  endif
endfunction

function! s:create_caches() abort
  return {
        \ 'winwidth': -1,
        \ 'max_level': -1,
        \ 'simple': -1,
        \ 'columns': [],
        \ 'index': {}
        \ }
endfunction

function! s:create_elements(context, path, ...) abort
  let level = get(a:000, 0, 0)

  let target = fnamemodify(a:path, ':p')
  let paths = glob(target . '*', 1, 1)
  if a:context.visible_hidden_files
    let hidden_paths = glob(target . '.*', 1, 1)
    call extend(
          \ paths,
          \ filter(hidden_paths, 'match(v:val, ''\(/\|\\\)\.\.\?$'') < 0')
          \ )
  endif

  let elements = s:sort(
        \ a:context,
        \ map(paths, 'vfiler#element#create(v:val, level)')
        \ )

  " TODO:
  " if top level add special element (current directory path)
  "if level == 0
  "  call insert(elements, vfiler#element#create(a:path, 0))
  "endif

  return elements
endfunction

function! s:to_view_elements(elements) abort
  let view_elements = []
  for element in a:elements
    call add(view_elements, element)
    if !empty(element.children)
      " recursive children
      call extend(view_elements, s:to_view_elements(element.children))
    endif
  endfor
  return view_elements
endfunction

function! s:update_elements_all_levels(context, path, old_elements, ...) abort
  let level = get(a:000, 0, 0)
  let elements = s:create_elements(a:context, a:path, level)

  for old in a:old_elements
    let match_index = -1
    for index in range(0, len(elements) - 1)
      if elements[index].path ==# old.path
        let match_index = index
        break
      endif
    endfor

    if match_index < 0
      continue
    endif

    let new = copy(old)
    if new.opened && !empty(old.children)
      " recursive children update
      let new.children = s:update_elements_all_levels(
            \ a:context, new.path, old.children, level + 1
            \ )
    endif
    let elements[match_index] = new
  endfor
  return elements
endfunction

function! s:get_max_level(view_elements) abort
  let level = 0
  for element in a:view_elements
    if element.level > level
      let level = element.level
    endif
  endfor
  return level
endfunction

" compare functions for sort "{{{

function! s:sort(context, elements) abort
  " sort by directory and file
  let directories = []
  let files = []
  for element in a:elements
    if element.isdirectory
      call add(directories, element)
    else
      call add(files, element)
    endif
  endfor

  let type = a:context.sort_type
  let order = a:context.sort_order

  " sort directories
  if len(directories) > 1
    let func = (type ==# 'time') ?
          \ s:_decide_compare_function('time', order) :
          \ s:_decide_compare_function('filename', order)
    let directories = sort(directories, func)
  endif

  " sort files
  if len(files) > 1
    let files = sort(files, s:_decide_compare_function(type, order))
  endif

  " combine sorted elements
  return extend(directories, files)
endfunction

function! s:_decide_compare_function(sort_type, sort_order) abort
  return 's:compare_' . a:sort_type . (a:sort_order ? '_desc' : '_asc')
endfunction

function! s:compare_filename_asc(lhs, rhs) abort
  return s:_compare_string(a:lhs.name, a:rhs.name)
endfunction

function! s:compare_filename_desc(lhs, rhs) abort
  return s:compare_filename_asc(a:lhs, a:rhs) * -1
endfunction

function! s:compare_extension_asc(lhs, rhs) abort
  let ext_l = fnamemodify(a:lhs.name, ':e')
  let ext_r = fnamemodify(a:rhs.name, ':e')

  let compare = s:_compare_string(ext_l, ext_r)
  if compare != 0
    return compare
  endif
  return s:_compare_string(a:lhs.name, a:rhs.name)
endfunction

function! s:compare_extension_desc(lhs, rhs) abort
  return s:compare_extension_asc(a:lhs, a:rhs) * -1
endfunction

function! s:compare_size_asc(lhs, rhs) abort
  let compare = a:lhs.size - a:rhs.size
  if compare != 0
    return compare
  endif
  return s:_compare_string(a:lhs.name, a:rhs.name)
endfunction

function! s:compare_size_desc(lhs, rhs) abort
  return s:compare_size_asc(a:lhs, a:rhs) * -1
endfunction

function! s:compare_time_asc(lhs, rhs) abort
  let compare = a:lhs.time - a:rhs.time
  if compare != 0
    return compare
  endif
  return s:_compare_string(a:lhs.name, a:rhs.name)
endfunction

function! s:compare_time_desc(lhs, rhs) abort
  return s:compare_time_asc(a:lhs, a:rhs) * -1
endfunction

function! s:_compare_string(lhs, rhs) abort
  let word_l = s:_get_words(a:lhs)
  let word_r = s:_get_words(a:rhs)
  let len_l = len(word_l)
  let len_r = len(word_r)

  for i in range(0, min([len_l, len_r]) - 1)
    if word_l[i] >? word_r[i]
      return 1
    elseif word_l[i] <? word_r[i]
      return -1
    endif
  endfor

  return len_l - len_r
endfunction

function! s:_get_words(name) abort
  let words = []
  for split in split(a:name, '\d\+\zs\ze')
    let words += split(split, '\D\zs\ze\d\+')
  endfor

  return map(words, "v:val =~ '^\\d\\+$' ? str2nr(v:val) : v:val")
endfunction

"}}}

"}}}
