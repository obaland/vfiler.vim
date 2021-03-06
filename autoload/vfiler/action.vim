"=============================================================================
" FILE: autoload/vfiler/action.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

function! vfiler#action#start(path, options, ...) abort
  let open_action = get(a:000, 0, '')
  call s:create_buffer(a:options, open_action)
  let b:context = vfiler#context#create(a:path, a:options)
  call vfiler#mappings#define(b:context)

  " resize window
  if a:options.winwidth > 0
    call vfiler#core#resize_window_width(a:options.winwidth)
  endif

  " draw
  call vfiler#view#draw(b:context)
  call vfiler#action#move_cursor_top()
endfunction

function! vfiler#action#get_current_element() abort
  let index = s:to_index(b:context, line('.'))
  return vfiler#context#get_element_count(b:context) > 0 ?
        \ vfiler#context#get_element(b:context, index) :
        \ vfiler#element#create(b:context.path, 0)
endfunction

function! vfiler#action#switch_to_directory(...) abort
  let path = get(a:000, 0, vfiler#action#get_current_element().path)
  let path = vfiler#core#normalized_path(
        \ fnamemodify(path, ':p')
        \ )

  if !isdirectory(path)
    call vfiler#core#error('Failed to switch the path - ' . path)
    return
  endif

  call vfiler#context#save_index_cache(b:context, path)
  call vfiler#context#switch(b:context, path)
  call s:draw()
  normal! zb
endfunction

function! vfiler#action#jump_to_directory() abort
  let path = vfiler#core#input('Jump to?', b:context.path, 'dir')
  if empty(path)
    call vfiler#core#info('Cancelled.')
    return
  endif

  let path = vfiler#core#normalized_path(path)
  if !isdirectory(path)
    call vfiler#core#error('Not exists the path - ' . path)
    return
  endif
  call vfiler#action#switch_to_directory(path)
endfunction

function! vfiler#action#sync_with_current_filer() abort
  if b:context.explorer
    " disabled explorer mode
    return
  endif

  " update source buffer
  let lnum = line('.')
  call vfiler#context#update(b:context)

  let source = b:context
  if vfiler#buffer#exists(b:context.alternate_bufnr)
    " open alternate buffer (source -> destination)
    call s:open_alternate_buffer(b:context)
    call vfiler#action#switch_to_directory(source.path)
    call vfiler#action#move_cursor(lnum)
  else
    " create alternate buffer (source -> destination)
    call s:create_alternate_buffer(b:context)
    call s:draw()
    call vfiler#action#move_cursor(lnum)
  endif

  " destination -> source
  call vfiler#core#move_window(bufwinnr(source.bufnr))
  call s:draw()
  call vfiler#action#move_cursor(lnum)
endfunction

function! vfiler#action#toggle_safe_mode() abort
  call vfiler#context#toggle_safe_mode(b:context)
  call vfiler#core#info(
        \ 'Safe mode is ' . (b:context.safe_mode ? 'enabled' : 'disabled')
        \ )
  call vfiler#mappings#define(b:context)
endfunction

function! vfiler#action#reload() abort
  call vfiler#context#save_index_cache(
        \ b:context,
        \ vfiler#action#get_current_element().path
        \ )
  call vfiler#context#update(b:context)
  call s:draw()
endfunction

function! vfiler#action#reload_all() abort
  call s:foreach_filer('vfiler#action#reload')
endfunction

function! vfiler#action#redraw() abort
  call vfiler#context#save_index_cache(
        \ b:context,
        \ vfiler#action#get_current_element().path
        \ )
  call s:draw()
endfunction

function! vfiler#action#redraw_all() abort
  call s:foreach_filer('vfiler#action#redraw')
endfunction

function! vfiler#action#switch_to_buffer() abort
  if b:context.split && !empty(s:get_notfiler_winnrs())
    " leave filer buffer
    call vfiler#action#reload()
    call vfiler#core#move_window(0)
    return
  endif

  if b:context.explorer
    " disabled explorer mode
    return
  endif

  if vfiler#buffer#exists(b:context.alternate_bufnr)
    " open alternate buffer (source -> destination)
    call vfiler#action#reload()

    call s:open_alternate_buffer(b:context)
    call vfiler#action#reload()
  else
    " create alternate buffer (source -> destination)
    let element = vfiler#action#get_current_element()
    call vfiler#context#save_index_cache(b:context, element.path)
    call vfiler#context#update(b:context)

    call s:create_alternate_buffer(b:context)
    call s:foreach_filer('s:draw')
    call vfiler#action#move_cursor(line('.'))
  endif
endfunction

function! vfiler#action#add_bookmark() abort
  let elements = vfiler#context#get_marked_elements(b:context)
  if empty(elements) && line('.') > 1
    call add(elements, vfiler#action#get_current_element())
  endif

  let message = (len(elements) == 1) ?
        \ printf('Add to bookmark - %s (y/N)?', elements[0].path) :
        \ printf('Add to bookmark - %d selected paths (y/N)?', len(elements))
  if vfiler#core#getchar(message) !=? 'y'
    call vfiler#core#info('Cancelled.')
    return
  endif
  
  let paths = []
  for element in elements
    call vfiler#core#info('Add bookmark - ' . element.path)
    call add(paths, element.path)
    let element.selected = 0
  endfor
  call vfiler#exbuffer#list#record_bookmarks(paths)

  if !empty(paths)
    call vfiler#context#save_index_cache(
          \ b:context, vfiler#action#get_current_element().path
          \ )
    call s:draw()
  endif
endfunction

function! vfiler#action#run_drive_list() abort
  let detect_drives = s:get_detect_drives()
  if !empty(detect_drives)
    let options = vfiler#exbuffer#list#create_options()
    let options.bufname = 'select_drive'
    let options.callback = 'vfiler#action#on_selected_drive_callback'
    call vfiler#exbuffer#list#run(b:context, detect_drives, options)
  endif
endfunction

function! vfiler#action#on_selected_drive_callback(context, selected_line) abort
  if !isdirectory(a:selected_line)
    return
  endif
  call vfiler#action#switch_to_directory(a:selected_line)
endfunction

let s:sort_types = [
      \ 'filename  - ascending',
      \ 'extension - ascending',
      \ 'size      - ascending',
      \ 'time      - ascending',
      \ 'Filename  - descending',
      \ 'Extension - descending',
      \ 'Size      - descending',
      \ 'Time      - descending'
      \ ]

function! vfiler#action#run_sort_list() abort
  let options = vfiler#exbuffer#list#create_options()
  let options.bufname = 'select_sort'
  let options.callback = 'vfiler#action#on_selected_sort_callback'
  call vfiler#exbuffer#list#run(b:context, s:sort_types, options)
endfunction

function! vfiler#action#on_selected_sort_callback(context, selected_line) abort
  let splitted = split(a:selected_line, '\s\+-\s\+')
  let type = tolower(splitted[0])
  let order_str = tolower(splitted[1])

  if order_str ==# 'ascending'
    let order = 0
  elseif order_str ==# 'descending'
    let order = 1
  else
    call vfiler#core#error('Illegal sort order (' . order_str . ')')
    return
  endif

  let current = vfiler#action#get_current_element()
  call vfiler#context#save_index_cache(a:context, current.path)
  if vfiler#context#change_sort(a:context, type, order)
    call s:draw()
  endif
endfunction

function! vfiler#action#on_selected_path_callback(context, selected_line) abort
  let path = a:selected_line
  if isdirectory(path)
    call vfiler#action#switch_to_directory(path)
    return
  endif

  if !filereadable(path)
    call vfiler#core#error('Cannot open file. - ' . path)
    return
  endif

  " for file, select how to open
  let answer = vfiler#core#getchar('Do you wanto to (o[open]/s[plit]/v[split]/t[ab]/C[ancel])?')
  if answer ==? 'o'
    call vfiler#action#open_file(path)
  elseif answer ==? 's'
    call vfiler#action#open_file_by_split(path)
  elseif answer ==? 'v'
    call vfiler#action#open_file_by_vsplit(path)
  elseif answer ==? 't'
    call vfiler#action#open_file_by_tabpage(path)
  else
    call vfiler#core#info('Cancelled.')
  endif
endfunction

function! vfiler#action#run_bookmark() abort
  let options = vfiler#exbuffer#list#create_options()
  let options.bufname = 'bookmark'
  let options.readonly = 0
  let options.callback = 'vfiler#action#on_selected_bookmark_callback'
  call vfiler#exbuffer#list#run_bookmark(b:context, options)
endfunction

function! vfiler#action#on_selected_bookmark_callback(context, selected_line) abort
  call vfiler#action#on_selected_path_callback(a:context, a:selected_line)

  " update MRU
  call vfiler#exbuffer#list#record_bookmarks([a:selected_line])
endfunction

function! vfiler#action#toggle_directory_tree(...) abort
  let lnum = get(a:000, 0, line('.'))
  let target = vfiler#context#get_element(
        \ b:context, s:to_index(b:context, lnum)
        \ )

  if target.isdirectory && target.opened
    call vfiler#action#unexpand_directory_tree(lnum)
  else
    call vfiler#action#expand_directory_tree(lnum)
  endif
endfunction

function! vfiler#action#unexpand_directory_tree(...) abort
  let index = s:to_index(
        \ b:context, get(a:000, 0, line('.'))
        \ )
  let current = vfiler#context#get_element(b:context, index)

  let parent = vfiler#context#unexpand_directory_tree(b:context, index)
  if !empty(parent)
    call vfiler#context#save_index_cache(b:context, parent.path)
    call s:draw()
  endif
endfunction

function! vfiler#action#expand_directory_tree(...) abort
  let index = s:to_index(
        \ b:context, get(a:000, 0, line('.'))
        \ )
  let target = vfiler#context#get_element(b:context, index)
  if !target.isdirectory
    return
  endif

  call vfiler#context#save_index_cache(b:context, target.path)
  call vfiler#context#expand_directory_tree(b:context, index)
  call s:draw()
  call vfiler#action#move_cursor_down()
endfunction

function! vfiler#action#switch_to_parent_directory() abort
  let element = vfiler#action#get_current_element()
  if element.level > 0 || element.opened
    call vfiler#action#unexpand_directory_tree()
    return
  endif

  " save cached before switch
  call vfiler#context#save_index_cache(b:context, element.path)

  let prev_path = b:context.path
  let dest_path = fnamemodify(b:context.path, ':h')

  call vfiler#context#switch(b:context, dest_path)
  call vfiler#context#save_index_cache(b:context, prev_path)
  call s:draw()
endfunction

function! vfiler#action#toggle_visible_hidden_files() abort
  let element = vfiler#action#get_current_element()
  call vfiler#context#save_index_cache(b:context, element.path)
  call vfiler#context#toggle_visible_hidden_files(b:context)
  call s:draw()
endfunction

function! vfiler#action#toggle_mark(...) abort
  let cursor_func = get(a:000, 0, '')
  let lnum = line('.')
  let index = s:to_index(b:context, lnum)

  let element = vfiler#context#toggle_mark(b:context, index)
  call vfiler#view#draw_line(b:context, element, lnum)
  if !empty(cursor_func)
    execute 'call ' . cursor_func
  endif
endfunction

function! vfiler#action#toggle_mark_all_lines() abort
  let element = vfiler#action#get_current_element()
  call vfiler#context#save_index_cache(b:context, element.path)
  call vfiler#context#toggle_mark_all(b:context)
  call s:draw()
endfunction

function! vfiler#action#clear_mark_all_lines() abort
  let element = vfiler#action#get_current_element()
  call vfiler#context#save_index_cache(b:context, element.path)
  call vfiler#context#clear_mark_all(b:context)
  call s:draw()
endfunction

function! vfiler#action#open_file(...) abort
  let path = get(a:000, 0, vfiler#action#get_current_element().path)
  if !b:context.explorer
    call vfiler#action#open_file_by_action('edit', path)
    return
  endif

  let winnr = s:choose_window(s:get_notfiler_winnrs())
  if winnr <= 0
    call vfiler#action#open_file_by_action('belowright vsplit', path)
  else
    call vfiler#action#open_file_by_action(winnr . 'wincmd w|edit', path)
  endif
endfunction

function! vfiler#action#open_file_by_tabpage(...) abort
  let path = get(a:000, 0, vfiler#action#get_current_element().path)
  call vfiler#action#open_file_by_action('tabnew', path)
endfunction

function! vfiler#action#open_file_by_split(...) abort
  let path = get(a:000, 0, vfiler#action#get_current_element().path)
  call vfiler#action#open_file_by_action('belowright split', path)
endfunction

function! vfiler#action#open_file_by_vsplit(...) abort
  let path = get(a:000, 0, vfiler#action#get_current_element().path)
  call vfiler#action#open_file_by_action('belowright vsplit', path)
endfunction

function! vfiler#action#execute_file() abort
  let path = get(a:000, 0, vfiler#action#get_current_element().path)
  call vfiler#core#execute_file(path)
endfunction

function! vfiler#action#open_file_by_action(action, ...) abort
  let path = get(a:000, 0, vfiler#action#get_current_element().path)
  if isdirectory(path)
    call vfiler#action#start(path, b:context, a:action)
    return
  endif

  execute a:action . ' ' . path
  call vfiler#action#redraw_all()
endfunction

function! vfiler#action#yank_full_path() abort
  let selected = vfiler#context#get_marked_elements(b:context)

  if empty(selected)
    let path = vfiler#action#get_current_element().path
    call vfiler#core#yank(path)
    call vfiler#core#info('Yanked file path - ' . path)
  else
    let paths = join(map(selected, "v:val.path"), "\n")
    call vfiler#core#yank(paths)
    call vfiler#core#info('Yanked file paths')
  endif
endfunction

function! vfiler#action#yank_filename() abort
  let selected = vfiler#context#get_marked_elements(b:context)

  if empty(selected)
    let name = fnamemodify(vfiler#action#get_current_element().path, ':t')
    call vfiler#core#yank(name)
    call vfiler#core#info('Yanked filename - ' . name)
  else
    let names = join(map(selected, "fnamemodify(v:val.path, ':t')"), "\n")
    call vfiler#core#yank(names)
    call vfiler#core#info('Yanked filenames')
  endif
endfunction

function! vfiler#action#quit() abort
  let bufnr = b:context.bufnr
  unlet b:context

  if vfiler#buffer#exists(bufnr)
    call vfiler#buffer#destroy(bufnr)
  else
    close!
  endif
endfunction

function! vfiler#action#get_file_offset() abort
  return b:context.offset + 1
endfunction

function! vfiler#action#move_cursor(lnum) abort
  call cursor(a:lnum, 1)
endfunction

function! vfiler#action#move_cursor_top() abort
  call vfiler#action#move_cursor(s:to_lnum(b:context, 0))
endfunction

function! vfiler#action#move_cursor_bottom() abort
  call vfiler#action#move_cursor(line('$'))
endfunction

function! vfiler#action#move_cursor_up() abort
  let lnum = line('.')
  call vfiler#action#move_cursor(
        \ s:to_index(b:context, lnum) <= 0 ? lnum : lnum - 1
        \ )
endfunction

function! vfiler#action#move_cursor_down() abort
  let lnum = line('.')
  call vfiler#action#move_cursor(
        \ lnum == line('$') ? lnum : lnum + 1
        \ )
endfunction

" file operation actions "{{{

function! vfiler#action#disable_operation() abort
  call vfiler#core#warning('In safe mode, this operation is disabled.')
endfunction

function! vfiler#action#create_file() abort
  call s:operate_file_creation(
        \ 'New file names? (comma separated)',
        \ 'vfiler#core#create_file'
        \ )
endfunction

function! vfiler#action#mkdir() abort
  call s:operate_file_creation(
        \ 'New directory names? (comma separated)',
        \ 'vfiler#core#mkdir'
        \ )
endfunction

function! vfiler#action#copy_file() abort
  call s:operate_file_control('vfiler#core#copy_file')
endfunction

function! vfiler#action#move_file() abort
  call s:operate_file_control('vfiler#core#rename_file')
endfunction

function! vfiler#action#delete_file() abort
  let targets = vfiler#context#get_marked_elements(b:context)
  let num_targets = len(targets)
  if num_targets <= 0
    call vfiler#action#toggle_mark()
    return
  endif

  let message = (num_targets == 1) ?
        \ printf('Delete - %s (y/N)?', targets[0].name) :
        \ printf('Delete - %d selected files (y/N)?', num_targets)
  if vfiler#core#getchar(message) !=? 'y'
    call vfiler#core#info('Cancelled.')
    return
  endif

  let num_deleted = 0
  for element in sort(targets, 's:compare_delete_order')
    if vfiler#core#delete_file(element.path)
      let num_deleted += 1
    else
      call vfiler#core#error('Cannot delete file - ' . element.name)
    endif
  endfor

  if num_targets == num_deleted
    let message = (num_targets == 1) ?
          \ printf('Deleted - %s', targets[0].name) :
          \ printf('Deleted - %d files', num_targets)
    call vfiler#core#info(message)
  endif

  if num_deleted > 0
    let lnum = line('.')
    call vfiler#action#reload_all()
    call vfiler#action#move_cursor(lnum)
  endif
endfunction

function! s:compare_delete_order(lhs, rhs) abort
  return a:lhs.level - a:rhs.level
endfunction

function! vfiler#action#rename_file() abort
  let marked_elements = vfiler#context#get_marked_elements(b:context)
  if empty(marked_elements)
    call vfiler#action#rename_one_file()
    return
  endif

  " multiple rename files
  call vfiler#context#save_index_cache(
        \ b:context, vfiler#action#get_current_element().path
        \ )
  call vfiler#exbuffer#rename#run(
        \ b:context, marked_elements
        \ )
  call s:foreach_filer('s:draw')
endfunction

function! vfiler#action#on_rename_file_callback(context, from_elements, to_names) abort
  call s:rename_files(a:context, a:from_elements, a:to_names)
endfunction

function! vfiler#action#rename_one_file() abort
  let current = vfiler#action#get_current_element()
  let from_name = current.name

  " rename one file
  let to_name = vfiler#core#input(
        \ 'New file name - ' . from_name, from_name, 'file')
  if empty(to_name)
    call vfiler#core#info('Cancelled.')
    return
  endif

  call s:rename_files(b:context, [current], [to_name])
  call vfiler#action#reload_all()
endfunction

"}}}

" internal functions "{{{

function! s:to_index(context, lnum) abort
  return a:lnum - vfiler#action#get_file_offset()
endfunction

function! s:to_lnum(context, index) abort
  return a:index + vfiler#action#get_file_offset()
endfunction

function! s:foreach_filer(function, ...) abort
  let current_winnr = winnr()
  try
    for winnr in s:get_filer_winnrs()
      call vfiler#core#move_window(winnr)
      call call(a:function, a:000)
    endfor
  finally
    call vfiler#core#move_window(current_winnr)
  endtry
endfunction

function! s:draw() abort
  call vfiler#view#draw(b:context)
  call s:restore_cursor(b:context)

  " in explorer mode, automatically adjust screen width
  if b:context.explorer && (b:context.winwidth != winwidth(0))
    call vfiler#core#resize_window_width(b:context.winwidth)
  endif
endfunction

function! s:open_alternate_buffer(context) abort
  let bufnr = a:context.alternate_bufnr
  if bufwinnr(bufnr) < 0
    silent belowright vsplit
    call vfiler#buffer#open(a:context.buffer_name, bufnr)
  else
    call vfiler#core#move_window(bufwinnr(bufnr))
  endif
endfunction

function! s:create_alternate_buffer(context) abort
  let source = a:context
  call s:create_buffer(source, 'belowright vsplit')
  let b:context = vfiler#context#create_alternate(source)
  call vfiler#mappings#define(b:context)
endfunction

function! s:create_buffer(context, open_action) abort
  let bufoptions = vfiler#buffer#create_options()
  let bufoptions.open_action = a:open_action
  if a:context.explorer
    let bufoptions.local_options = [
          \ 'nobuflisted', 'winfixwidth'
          \ ]
  endif
  call vfiler#buffer#create(a:context.buffer_name, bufoptions)
endfunction

function! s:restore_cursor(context) abort
  " restore cursor
  let index = vfiler#context#load_index_cache(a:context)
  if index < 0
    call vfiler#action#move_cursor_top()
  else
    call vfiler#action#move_cursor(s:to_lnum(a:context, index))
  endif
endfunction

function! s:get_detect_drives() abort
  let detect_drives = get(g:, 'vfiler_detect_drives', [])
  if empty(detect_drives)
    if vfiler#core#is_windows()
      let detect_drives = [
            \ 'A:/', 'B:/', 'C:/', 'D:/', 'E:/', 'F:/', 'G:/',
            \ 'H:/', 'I:/', 'J:/', 'K:/', 'L:/', 'M:/', 'N:/',
            \ 'O:/', 'P:/', 'Q:/', 'R:/', 'S:/', 'T:/', 'U:/',
            \ 'V:/', 'W:/', 'X:/', 'Y:/', 'Z:/'
            \ ]
    endif
  endif

  return filter(detect_drives, 'isdirectory(v:val)')
endfunction

function! s:operate_file_creation(message, create_func) abort
  let filestr = vfiler#core#input(a:message, '', 'file')
  if empty(filestr)
    call vfiler#core#info('Cancelled.')
    return
  endif

  let current = vfiler#action#get_current_element()
  let parent_path = current.level == 0 ?
        \ b:context.path : fnamemodify(current.path, ':h')
  let parent_path = fnamemodify(parent_path, ':p')

  let newfiles = []
  for file in split(filestr, '\s*,\s*') 
    let path = vfiler#core#normalized_path(parent_path . file)
    if filereadable(path)
      call vfiler#core#error('Skipped, file already exists. - ' . file)
    else
      call call(a:create_func, [path])
      call add(newfiles, file)
    endif
  endfor

  let num_newfiles = len(newfiles)
  if num_newfiles > 0
    let message = (num_newfiles == 1) ?
          \ printf('Created - %s', newfiles[0]) :
          \ printf('Created - %d files', num_newfiles)
    call vfiler#core#info(message)

    let lnum = line('.')
    call vfiler#action#reload_all()
    call vfiler#action#move_cursor(lnum)
  endif
endfunction

function! s:operate_file_control(control_func) abort
  let targets = vfiler#context#get_marked_elements(b:context)
  if empty(targets)
    call vfiler#action#toggle_mark()
    return
  endif

  if vfiler#context#is_active_alternate(b:context)
    let alternate = vfiler#context#get_alternate_context(b:context)
    let dest_dir = alternate.path
  else
    let dest_dir = vfiler#core#input('Destination directory?', '', 'dir')
    if empty(dest_dir)
      call vfiler#core#info('Cancelled.')
      return
    endif

    if !isdirectory(dest_dir)
      call vfiler#core#error('Invalid directory path - ' . dest_dir)
      return
    endif
  endif
  let dest_dir = fnamemodify(dest_dir, ':p')

  " control files
  let num_controled = 0
  for element in targets
    let src = element.path
    let dest = dest_dir . element.name
    let element.selected = 0

    if filereadable(dest) || isdirectory(dest)
      call vfiler#core#warning('File already exists.')
      call vfiler#core#warning('dest: ' . dest)
      call vfiler#core#warning('src : ' . src)

      echom ''
      if vfiler#core#getchar('Do you want to overwrite (y/N)?') !=? 'y'
        call vfiler#core#info('Skipped.')
        continue
      endif
    endif

    if call(a:control_func, [src, dest])
      let num_controled += 1
    else
      call vfiler#core#error(
            \ printf('Failed - %s -> %s', src, dest)
            \ )
    endif
  endfor

  if num_controled == len(targets)
    call vfiler#core#info('Done.')
  endif

  if num_controled > 0
    let lnum = line('.')
    call vfiler#action#reload_all()
    call vfiler#action#move_cursor(lnum)
  endif
endfunction

function! s:choose_window(winnrs) abort
  let num_winnrs = len(a:winnrs)
  if num_winnrs <= 0
    return -1
  elseif num_winnrs == 1
    return a:winnrs[0]
  endif

  let keys = [
        \ 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l',
        \ 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p',
        \ '1', '2', '3', '4', '5', '6', '7', '8', '9', '0'
        \ ]
  let wintable = {}
  for winnr in a:winnrs
    let key = keys[winnr - 1]
    let wintable[key] = winnr
  endfor

  let save_statuslines = map(
        \ a:winnrs,
        \ "[v:val, getbufvar(winbufnr(v:val), '&statusline')]"
        \ )
  let save_laststatus = &laststatus
  let save_winnr = winnr()

  try
    let &laststatus = 2

    " set key to statusline
    for key in keys(wintable)
      let winnr = wintable[key]
      call vfiler#core#move_window(winnr)
      let &l:statusline = repeat(' ', winwidth(0) / 2 - 1) . key
      redraw
    endfor

    let key = ''
    while !has_key(wintable, key)
      let key = vfiler#core#getchar('choose ? >')
    endwhile

  finally
    echo ''
    let &laststatus = save_laststatus

    for [winnr, statusline] in save_statuslines
      call vfiler#core#move_window(winnr)
      let &l:statusline = statusline
      redraw
    endfor

    call vfiler#core#move_window(save_winnr)
  endtry

  return wintable[key]
endfunction

function! s:get_filer_winnrs() abort
  return filter(
        \ range(1, winnr('$')),
        \ 's:is_filer_window(v:val)'
        \ )
endfunction

function! s:get_notfiler_winnrs() abort
  return filter(
        \ range(1, winnr('$')),
        \ '!s:is_filer_window(v:val)'
        \ )
endfunction

function! s:is_filer_window(winnr) abort
  return getwinvar(a:winnr, '&filetype') ==# 'vfiler' &&
        \ !empty(vfiler#context#get_context(winbufnr(a:winnr)))
endfunction

function! s:rename_files(context, from_elements, to_names) abort
  let num_elements = len(a:from_elements)
  if num_elements != len(a:to_names)
    call vfiler#core#error('Number to rename is a mismatch.')
  endif

  let renames = []
  let base_path = fnamemodify(a:context.path, ':p')

  for index in range(0, num_elements - 1)
    let element = a:from_elements[index]
    let from_name = element.name
    let to_name = a:to_names[index]

    " clear mark
    let element.selected = 0

    if from_name ==# to_name
      continue
    endif

    let from_path = base_path . from_name
    let to_path = base_path . to_name

    " double check
    if filereadable(to_path)
      call vfiler#core#warning('File already exists. - ' . fnamemodify(to_path, ':t'))
      echom ''

      if vfiler#core#getchar('Do you want to overwrite (y/N)?') !=? 'y'
        call vfiler#core#info("Skipped.")
        continue
      endif
    endif

    if vfiler#core#rename_file(from_path, to_path)
      let rename = {
            \ 'from': from_name, 'to': to_name
            \ }
      call add(renames, rename)
      call vfiler#element#rename(element, to_name)
    else
      call vfiler#core#error(
            \ printf('Cannot rename file %s -> %s', from_path, to_path)
            \ )
    endif
  endfor

  let num_renames = len(renames)
  if num_renames > 0
    let message = num_renames == 1 ?
          \ printf('Renamed - %s -> %s', renames[0].from, renames[0].to) :
          \ printf('Renamed - %d files', num_renames)
    call vfiler#core#info(message)
  endif
endfunction

"}}}
