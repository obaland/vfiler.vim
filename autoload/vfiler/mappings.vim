"=============================================================================
" FILE: autoload/vfiler/mappings.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

function! vfiler#mappings#define(context) abort
  call s:define_default(a:context)
  call s:define_file_operation(a:context)

  if g:vfiler_use_default_mappings
    call s:define_keymap()
  endif
endfunction

" internal functions "{{{

" define default keymappings
function! s:define_default(context) abort "{{{
  if a:context.explorer
    nmap <buffer><silent> <Plug>(vfiler_wrap_action_l)
          \ <Plug>(vfiler_toggle_tree_or_open)
  else
    nmap <buffer><silent> <Plug>(vfiler_wrap_action_l)
          \ <Plug>(vfiler_cd_or_open)
  endif

  nnoremap <buffer><silent><expr> <Plug>(vfiler_loop_cursor_down)
        \ (line('.') == line('$')) ? '2G0zb' : 'j'
  nnoremap <buffer><silent><expr> <Plug>(vfiler_loop_cursor_up)
        \ (line('.') == 2) ? 'G0' : 'k'
  nnoremap <buffer><silent><expr> <Plug>(vfiler_move_cursor_bottom)
        \ 'G0'
  nnoremap <buffer><silent><expr> <Plug>(vfiler_move_cursor_top)
        \ '2G0zb'
  nnoremap <buffer><silent> <Plug>(vfiler_switch_to_directory)
        \ :<C-u>call vfiler#action#switch_to_directory()<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_open_file)
        \ :<C-u>call vfiler#action#open_file()<CR>
  nmap <buffer><silent><expr> <Plug>(vfiler_cd_or_open)
        \ <SID>map_selective(
        \ '<Plug>(vfiler_switch_to_directory)',
        \ '<Plug>(vfiler_open_file)'
        \ )
  nnoremap <buffer><silent> <Plug>(vfiler_yank_full_path)
        \ :<C-u>call vfiler#action#yank_full_path()<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_yank_filename)
        \ :<C-u>call vfiler#action#yank_filename()<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_open_by_tabpage)
        \ :<C-u>call vfiler#action#open_file_by_tabpage()<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_open_by_split)
        \ :<C-u>call vfiler#action#open_file_by_split()<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_open_by_vsplit)
        \ :<C-u>call vfiler#action#open_file_by_vsplit()<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_execute_file)
        \ :<C-u>call vfiler#action#execute_file()<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_toggle_directory_tree)
        \ :<C-u>call vfiler#action#toggle_directory_tree()<CR>
  nmap <buffer><silent><expr> <Plug>(vfiler_toggle_tree_or_open)
        \ <SID>map_selective(
        \ '<Plug>(vfiler_toggle_directory_tree)',
        \ '<Plug>(vfiler_open_file)'
        \ )
  nnoremap <buffer><silent> <Plug>(vfiler_switch_to_parent_directory)
        \ :<C-u>call vfiler#action#switch_to_parent_directory()<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_switch_to_home_directory)
        \ :<C-u>call vfiler#action#switch_to_directory('~/')<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_switch_to_root_directory)
        \ :<C-u>call vfiler#action#switch_to_directory('/')<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_toggle_visible_hidden_files)
        \ :<C-u>call vfiler#action#toggle_visible_hidden_files()<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_toggle_mark_current_line_down)
        \ :<C-u>call vfiler#action#toggle_mark('vfiler#action#move_cursor_down()')<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_toggle_mark_current_line_up)
        \ :<C-u>call vfiler#action#toggle_mark('vfiler#action#move_cursor_up()')<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_toggle_mark_all_lines)
        \ :<C-u>call vfiler#action#toggle_mark_all_lines()<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_clear_mark_all_lines)
        \ :<C-u>call vfiler#action#clear_mark_all_lines()<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_switch_to_buffer)
        \ :<C-u>call vfiler#action#switch_to_buffer()<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_sync_with_current_filer)
        \ :<C-u>call vfiler#action#sync_with_current_filer()<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_switch_to_drive)
        \ :<C-u>call vfiler#action#run_drive_list()<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_select_sort_type)
        \ :<C-u>call vfiler#action#run_sort_list()<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_reload)
        \ :<C-u>call vfiler#action#reload()<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_jump_to_directory)
        \ :<C-u>call vfiler#action#jump_to_directory()<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_toggle_safe_mode)
        \ :<C-u>call vfiler#action#toggle_safe_mode()<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_select_bookmark)
        \ :<C-u>call vfiler#action#run_bookmark()<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_add_bookmark)
        \ :<C-u>call vfiler#action#add_bookmark()<CR>
  nnoremap <buffer><silent> <Plug>(vfiler_quit)
        \ :<C-u>call vfiler#action#quit()<CR>
endfunction "}}}

function! s:define_file_operation(context) abort "{{{
  if a:context.safe_mode
    nnoremap <buffer><silent> <Plug>(vfiler_create_file)
          \ :<C-u>call vfiler#action#disable_operation()<CR>
    nnoremap <buffer><silent> <Plug>(vfiler_mkdir)
          \ :<C-u>call vfiler#action#disable_operation()<CR>
    nnoremap <buffer><silent> <Plug>(vfiler_delete_file)
          \ :<C-u>call vfiler#action#disable_operation()<CR>
    nnoremap <buffer><silent> <Plug>(vfiler_rename_file)
          \ :<C-u>call vfiler#action#disable_operation()<CR>
    nnoremap <buffer><silent> <Plug>(vfiler_copy_file)
          \ :<C-u>call vfiler#action#disable_operation()<CR>
    nnoremap <buffer><silent> <Plug>(vfiler_move_file)
          \ :<C-u>call vfiler#action#disable_operation()<CR>
  else
    nnoremap <buffer><silent> <Plug>(vfiler_create_file)
          \ :<C-u>call vfiler#action#create_file()<CR>
    nnoremap <buffer><silent> <Plug>(vfiler_mkdir)
          \ :<C-u>call vfiler#action#mkdir()<CR>
    nnoremap <buffer><silent> <Plug>(vfiler_delete_file)
          \ :<C-u>call vfiler#action#delete_file()<CR>
    nnoremap <buffer><silent> <Plug>(vfiler_rename_file)
          \ :<C-u>call vfiler#action#rename_file()<CR>
    nnoremap <buffer><silent> <Plug>(vfiler_copy_file)
          \ :<C-u>call vfiler#action#copy_file()<CR>
    nnoremap <buffer><silent> <Plug>(vfiler_move_file)
          \ :<C-u>call vfiler#action#move_file()<CR>
  endif
endfunction "}}}

function! s:define_keymap() abort "{{{
  call vfiler#core#map_key('j',         'vfiler_loop_cursor_down')
  call vfiler#core#map_key('k',         'vfiler_loop_cursor_up')
  call vfiler#core#map_key('l',         'vfiler_wrap_action_l')
  call vfiler#core#map_key('h',         'vfiler_switch_to_parent_directory')
  call vfiler#core#map_key('gg',        'vfiler_move_cursor_top')
  call vfiler#core#map_key('G',         'vfiler_move_cursor_bottom')
  call vfiler#core#map_key('gs',        'vfiler_toggle_safe_mode')
  call vfiler#core#map_key('.',         'vfiler_toggle_visible_hidden_files')
  call vfiler#core#map_key('~',         'vfiler_switch_to_home_directory')
  call vfiler#core#map_key('\',         'vfiler_switch_to_root_directory')
  call vfiler#core#map_key('o',         'vfiler_toggle_tree_or_open')
  call vfiler#core#map_key('t',         'vfiler_open_by_tabpage')
  call vfiler#core#map_key('s',         'vfiler_open_by_split')
  call vfiler#core#map_key('v',         'vfiler_open_by_vsplit')
  call vfiler#core#map_key('x',         'vfiler_execute_file')
  call vfiler#core#map_key('yy',        'vfiler_yank_full_path')
  call vfiler#core#map_key('YY',        'vfiler_yank_filename')
  call vfiler#core#map_key('P',         'vfiler_sync_with_current_filer')
  call vfiler#core#map_key('L',         'vfiler_switch_to_drive')
  call vfiler#core#map_key('S',         'vfiler_select_sort_type')
  call vfiler#core#map_key('b',         'vfiler_select_bookmark')
  call vfiler#core#map_key('B',         'vfiler_add_bookmark')
  call vfiler#core#map_key('q',         'vfiler_quit')
  call vfiler#core#map_key('<Enter>',   'vfiler_cd_or_open')
  call vfiler#core#map_key('<Space>',   'vfiler_toggle_mark_current_line_down')
  call vfiler#core#map_key('<S-Space>', 'vfiler_toggle_mark_current_line_up')
  call vfiler#core#map_key('*',         'vfiler_toggle_mark_all_lines')
  call vfiler#core#map_key('U',         'vfiler_clear_mark_all_lines')
  call vfiler#core#map_key('<Tab>',     'vfiler_switch_to_buffer')
  call vfiler#core#map_key('<BS>',      'vfiler_switch_to_parent_directory')
  call vfiler#core#map_key('<C-l>',     'vfiler_reload')
  call vfiler#core#map_key('<C-j>',     'vfiler_jump_to_directory')

  call vfiler#core#map_key('N',         'vfiler_create_file')
  call vfiler#core#map_key('K',         'vfiler_mkdir')
  call vfiler#core#map_key('d',         'vfiler_delete_file')
  call vfiler#core#map_key('r',         'vfiler_rename_file')
  call vfiler#core#map_key('c',         'vfiler_copy_file')
  call vfiler#core#map_key('m',         'vfiler_move_file')
endfunction "}}}

function! s:map_selective(directory_map, file_map) abort
  let target = vfiler#action#get_current_element()
  return target.isdirectory ? a:directory_map : a:file_map
endfunction

"}}}
