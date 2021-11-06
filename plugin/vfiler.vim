"=============================================================================
" FILE: plugin/vfiler.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

if exists('g:loaded_vfiler')
  finish
endif

" TODO:
if has('nvim') && !has('nvim-0.5.0')
  finish
elseif !has('nvim')
 " vim
  if !has('lua') || v:version < 802
    echomsg 'VFiler requires Vim 8.2 or later with Lua support ("+lua").'
    finish
  endif
endif

let g:loaded_vfiler = 1

" Global options definition.

let g:vfiler_as_default_explorer =
      \ get(g:, 'vfiler_as_default_explorer', 0)
let g:vfiler_visible_hidden_files =
      \ get(g:, 'vfiler_visible_hidden_files', 0)
let g:vfiler_time_format =
      \ get(g:, 'vfiler_time_format', '%Y/%m/%d %H:%M')
let g:vfiler_safe_mode =
      \ get(g:, 'vfiler_safe_mode', 1)
let g:vfiler_auto_cd =
      \ get(g:, 'vfiler_auto_cd', 0)
let g:vfiler_marked_file_icon =
      \ get(g:, 'vfiler_marked_file_icon', '*')
let g:vfiler_tree_closed_icon =
      \ get(g:, 'vfiler_tree_closed_icon', '+')
let g:vfiler_tree_opened_icon =
      \ get(g:, 'vfiler_tree_opened_icon', '-')
let g:vfiler_tree_leaf_icon =
      \ get(g:, 'vfiler_tree_leaf_icon', '|')
let g:vfiler_max_number_of_bookmark =
      \ get(g:, 'vfiler_max_number_of_bookmark', 50)
let g:vfiler_use_default_mappings =
      \ get(g:, 'vfiler_use_default_mappings', 1)
let g:vfiler_display_current_directory_on_top =
      \ get(g:, 'vfiler_display_current_directory_on_top', 1)

" Disable netrw.
if g:vfiler_as_default_explorer
  augroup FileExplorer
    autocmd!
  augroup END
endif

" define commands
command! -nargs=? -complete=customlist,vfiler#complete VFiler call
      \ vfiler#start_command_legacy(<q-args>)
command! -nargs=? -complete=customlist,vfiler#complete VFilerCurrentDir
      \ call vfiler#start_command_legacy(<q-args> . ' ' . getcwd())
command! -nargs=? -complete=customlist,vfiler#complete VFilerBufferDir
      \ call vfiler#start_command_legacy(
      \   <q-args> . ' ' . vfiler#get_buffer_directory_path(bufnr('%'))
      \ )

command! -nargs=? VFilerLua call vfiler#start_command(<q-args>)
