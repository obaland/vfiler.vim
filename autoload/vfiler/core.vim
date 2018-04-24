"=============================================================================
" FILE: autoload/vfiler/core.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

let s:Vital = vital#vfiler#new()
let s:String = s:Vital.import('Data.String')
let s:SystemFile = s:Vital.import('System.File')

function! vfiler#core#is_windows() abort
  return has('win32') || has('win64')
endfunction

function! vfiler#core#is_mac() abort
  return !vfiler#core#is_windows() && !has('win32unix')
      \ && (has('mac') || has('macunix') || has('gui_macvim')
      \     || (!executable('xdg-open') && system('uname') =~? '^darwin'))
endfunction

function! vfiler#core#swap(a, b) abort
  let tmp = a:a
  let a:a = a:b
  let a:b = tmp
endfunction

function! vfiler#core#digit(value) abort
  let value = a:value
  let digit = 1
  while (value / (10 * digit)) > 0
    let digit += 1
    let value = value / 10
  endwhile
  return digit
endfunction

function! vfiler#core#input(prompt, ...) abort
  let prompt = '[vfiler] ' . a:prompt . ': '
  let text = get(a:000, 0, '')
  let completion = get(a:000, 1, '')

  if empty(completion)
    let content = input(prompt, text)
  else
    let content = input(prompt, text, completion)
  endif
  redraw
  return content
endfunction

function! vfiler#core#getchar(prompt) abort
  let prompt = '[vfiler] ' . a:prompt . ': '
  echohl Question | echon prompt | echohl None
  let char = getchar()
  redraw
  return nr2char(char)
endfunction

function! vfiler#core#info(message) abort
  echo '[vfiler]: ' . a:message
endfunction

function! vfiler#core#error(message) abort
  echohl ErrorMsg | echom '[vfiler] ERROR: ' . a:message | echohl None
endfunction

function! vfiler#core#warning(message) abort
  echohl WarningMsg | echom '[vfiler] WARNING: ' . a:message | echohl None
endfunction

function! vfiler#core#normalized_path(path, is_directory) abort
  let path = fnamemodify(
        \ substitute(a:path, '\\', '/', 'g'), ':p'
        \ )
  if a:is_directory
    let path .= '/'
  endif
  return path
endfunction

function! vfiler#core#get_parent_directory_path(path) abort
  let mods = ':h'
  if match(a:path, '/$') >= 0
    let mods .= ':h'
  endif

  let parent = fnamemodify(a:path, mods)
  if match(parent, '/$') < 0
    let parent .= '/'
  endif
  return parent
endfunction

function! vfiler#core#get_root_directory_path(path) abort
  if vfiler#core#is_windows() && a:path =~ '^//'
    " For UNC path.
    let path = matchstr(a:path, '^//[^/]*/[^/]*')
  elseif vfiler#core#is_windows()
    let path = matchstr(fnamemodify(a:path, ':p'), '^\a\+:[/\\]')
  else
    let path = '/'
  endif
  return path
endfunction

function! vfiler#core#yank(content) abort
  " for register
  let @" = a:content

  " for clipboard
  if has('clipboard') || has('xterm_clipboard')
    let @+ = a:content
  endif
endfunction

function! vfiler#core#execute_file(path) abort
  call s:SystemFile.open(a:path)
endfunction

function! vfiler#core#create_file(path) abort
  if vfiler#core#is_windows()
    call system('type nul > ' . a:path)
  else
    call system('touch ' . a:path)
  endif
endfunction

function! vfiler#core#mkdir(path, ...) abort
  call mkdir(a:path, get(a:000, 0, ''))
endfunction

function! vfiler#core#rename_file(from, to) abort
  return rename(a:from, a:to) == 0
endfunction

function! vfiler#core#delete_file(path) abort
  return delete(a:path, 'rf') == 0
endfunction

function! vfiler#core#copy_file(src, dest) abort
  if isdirectory(a:src)
    return s:SystemFile.copy_dir(a:src, a:dest) != 0
  else
    return s:SystemFile.copy(a:src, a:dest) != 0
  endif
endfunction

function! vfiler#core#truncate_skipping(str, max, footer_width, separator) abort
  return call(
        \ s:String.truncate_skipping,
        \ [a:str, a:max, a:footer_width, a:separator]
        \ )
endfunction

function! vfiler#core#move_window(winnr) abort
  let command = (a:winnr > 0) ? (a:winnr . 'wincmd w') : 'wincmd w'
  noautocmd execute command
endfunction

function! vfiler#core#resize_window_height(height) abort
  silent execute 'resize ' . a:height
endfunction

function! vfiler#core#resize_window_width(width) abort
  silent execute 'vertical resize ' . a:width
endfunction

function! vfiler#core#map_key(key, name) abort
  execute printf('nmap <buffer><nowait> %s <Plug>(%s)', a:key, a:name)
endfunction

" internal functions "{{{

"}}}
