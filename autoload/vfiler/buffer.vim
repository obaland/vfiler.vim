"=============================================================================
" FILE: autoload/vfiler/buffer.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

function! vfiler#buffer#create_options() abort
  return {
        \ 'local_options': [],
        \ 'open_action': ''
        \ }
endfunction

function! vfiler#buffer#open(basename, ...) abort
  let bufnr = get(a:000, 0, -1)
  if bufnr > 0
    if !vfiler#buffer#exists(bufnr)
      return s:result(-1)
    endif

    call s:open(bufnr)
    return s:result(bufnr)
  endif

  " open alternate buffer
  let bufnrs = s:get_saved_bufnrs(
        \ s:make_bufname_prefix(a:basename)
        \ )
  for bufnr in bufnrs
    if s:is_valid_bufnr(bufnr)
      call s:open(bufnr)
      return s:result(bufnr)
    endif
  endfor

  return s:result(-1)
endfunction

function! vfiler#buffer#create(basename, ...) abort
  let options = get(a:000, 0, vfiler#buffer#create_options())
  let prefix = s:make_bufname_prefix(a:basename)
  let bufnrs = s:get_filer_bufnrs(prefix)

  if empty(bufnrs)
    let bufname = prefix
  else
    let bufname = s:create_bufname(bufnrs, prefix)
  endif

  call s:create(bufname, options)
  return s:result(bufnr('%'))
endfunction

function! vfiler#buffer#destroy(bufnr)
  if vfiler#buffer#exists(a:bufnr)
    silent execute 'bwipeout ' . a:bufnr
  endif
endfunction

function! vfiler#buffer#exists(bufnr) abort
  let prefix = s:get_buffer_prefix(bufname(a:bufnr))
  if !s:exists_saved_bufnr(a:bufnr)
    return 0
  endif

  return s:is_filer_buffer(prefix, a:bufnr) &&
        \ s:is_valid_bufnr(a:bufnr)
endfunction

" internal functions {{{

let s:bufname_prefix = 'vfiler'

function! s:get_filer_bufnrs(prefix) abort
  return filter(
        \ range(1, bufnr('$')),
        \ 's:is_filer_buffer(a:prefix, v:val)'
        \ )
endfunction

function! s:cleanup_bufnrs(bufnrs) abort
  let valid_bufnrs = []
  for bufnr in a:bufnrs
    if s:is_valid_bufnr(bufnr)
      call add(valid_bufnrs, bufnr)
    else
      silent execute 'bwipeout ' . bufnr
    endif
  endfor

  return valid_bufnrs
endfunction

function! s:result(bufnr) abort
  return {
        \ 'bufnr': a:bufnr,
        \ 'bufname': a:bufnr < 0 ? '' : bufname(a:bufnr)
        \ }
endfunction

function! s:open(bufnr) abort
  let winnr = bufwinnr(a:bufnr)
  if winnr > 0
    call vfiler#core#move_window(winnr)
  else
    silent execute 'buffer ' . a:bufnr
  endif
endfunction

function! s:create(bufname, options) abort
  " split window
  if !empty(a:options.open_action)
    silent execute a:options.open_action
  endif

  " Save swapfile option.
  let swapfile_save = &g:swapfile
  try
    set noswapfile
    silent execute 'edit ' . a:bufname
  finally
    let &g:swapfile = swapfile_save
  endtry

  " set buffer local options
  if exists('&colorcolumn')
    setlocal colorcolumn=
  endif

  setlocal bufhidden=hide
  setlocal buftype=nofile
  setlocal filetype=vfiler
  setlocal noswapfile
  setlocal noreadonly
  setlocal nowrap
  setlocal nospell
  setlocal foldcolumn=0
  setlocal nofoldenable
  setlocal nomodifiable
  setlocal nomodified
  setlocal nolist
  setlocal number

  if has('conceal')
    if &l:conceallevel < 2
      setlocal conceallevel=2
    endif
    setlocal concealcursor=nvc
  endif

  " set additional options
  for option in a:options.local_options
    execute 'setlocal ' . option
  endfor

  let bufnr = bufnr('%')
  call s:save_bufnr(bufnr)
  call s:set_autocommands(bufnr)
endfunction

function! s:set_autocommands(bufnr) abort
 augroup vfiler
    autocmd BufEnter <buffer> call vfiler#event#handle('BufEnter', expand('<abuf>'))
    autocmd BufDelete <buffer> call vfiler#event#handle('BufDelete', expand('<abuf>'))
    autocmd FocusGained <buffer> call vfiler#event#handle('FocusGained', expand('<abuf>'))
    autocmd FocusLost <buffer> call vfiler#event#handle('FocusLost', expand('<abuf>'))
    autocmd VimResized <buffer> call vfiler#event#handle('VimResized', expand('<abuf>'))
  augroup END
endfunction

function! s:is_valid_bufnr(bufnr) abort
  return bufexists(a:bufnr) && bufloaded(a:bufnr)
endfunction

function! s:is_filer_buffer(prefix, bufnr) abort
  let bufname = bufname(a:bufnr)
  return match(bufname, a:prefix) >= 0 &&
        \ getbufvar(bufname, '&filetype') =~# 'vfiler'
endfunction

function! s:make_bufname_prefix(basename) abort
  let bufname = s:bufname_prefix
  if !empty(a:basename)
    let bufname .= ':' . a:basename
  endif
  return bufname
endfunction

function! s:create_bufname(bufnrs, prefix) abort
  let bufnames = map(a:bufnrs, 'bufname(v:val)')
  let bufnames = sort(
        \ filter(bufnames, 'v:val =~# ''' . a:prefix . '\(@\d\+\)*$'''),
        \ 's:compare_buffer_number'
        \ )

  let last_number = s:get_buffer_number(bufnames[-1])
  return a:prefix . '@' . (last_number + 1)
endfunction

function! s:compare_buffer_number(lhs, rhs) abort
  return s:get_buffer_number(a:lhs) - s:get_buffer_number(a:rhs)
endfunction

function! s:get_buffer_prefix(bufname) abort
  let number = matchstr(a:bufname, '@\d\+$')
  return a:bufname[:len(a:bufname) - len(number)]
endfunction

function! s:get_buffer_number(bufname) abort
  let number = matchstr(a:bufname, '@\zs\d\+$')
  return number != '' ? str2nr(number) : 0
endfunction

function! s:save_bufnr(bufnr) abort
  if !exists('t:vfiler')
    let t:vfiler = {}
  endif
  let t:vfiler[a:bufnr] = bufname(a:bufnr)
endfunction

function! s:get_saved_bufnrs(prefix) abort
  if !exists('t:vfiler')
    return []
  endif
  let bufnrs = []
  for bufnr in keys(t:vfiler)
    if t:vfiler[bufnr] =~# a:prefix
      call add(bufnrs, bufnr)
    endif
  endfor
  return map(bufnrs, 'str2nr(v:val)')
endfunction

function! s:exists_saved_bufnr(bufnr) abort
  if !exists('t:vfiler')
    return 0
  endif
  return has_key(t:vfiler, a:bufnr)
endfunction

" }}}

