"=============================================================================
" FILE: autoload/vfiler/exbuffer/rename.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

let s:max_window_height = 20

" define keymappings
function! s:define_keymappings() abort
  nnoremap <buffer><silent> <Plug>(vfiler_exbuffer_rename_exit) :<C-u>call <SID>exit()<CR>

  call vfiler#core#map_key('q', 'vfiler_exbuffer_rename_exit')
endfunction

function! vfiler#exbuffer#rename#run(context, elements) abort
  " setup rename file list
  let names = map(
        \ copy(a:elements), "fnamemodify(v:val.path, ':t')"
        \ )

  silent vsplit

  " Save swapfile option.
  let swapfile_save = &g:swapfile
  try
    set noswapfile
    silent edit rename
  finally
    let &g:swapfile = swapfile_save
  endtry

  " set buffer local options
  setlocal laststatus=2
  setlocal bufhidden=hide
  setlocal buftype=acwrite
  setlocal filetype=vfiler_rename
  setlocal noswapfile
  setlocal noreadonly
  setlocal nowrap
  setlocal nospell
  setlocal foldcolumn=0
  setlocal nofoldenable
  setlocal nolist
  setlocal nobuflisted
  setlocal modifiable
  setlocal noreadonly

  " keep parameters
  let b:context = copy(a:context)
  let b:elements = a:elements

  " draw rename targets
  call setline(1, names)

  " clear undo
	let old_undolevels = &undolevels
	setlocal undolevels=-1
	silent execute "normal! I \<BS>\<Esc>"
	execute 'setlocal undolevels=' . old_undolevels
	unlet old_undolevels

  setlocal nomodified

  call s:define_keymappings()
  call s:define_syntexes(names)
  call s:define_autocommands()
endfunction

" internal functions

function! s:exit() abort
  " clear prompt message
  echo

  silent execute 'bwipeout ' . bufnr('%')
endfunction

function! s:define_syntexes(names) abort
  syntax match vfilerExBufferRename_Renamed '^.\+$'

  for lnum in range(1, len(a:names))
    execute printf('syntax match vfilerExBufferRename_NotRenamed ''^\%%%dl%s$''',
          \ lnum, a:names[lnum - 1]
          \ )
  endfor

  highlight! default link vfilerExBufferRename_Renamed Special
  highlight! default link vfilerExBufferRename_NotRenamed Normal
endfunction

function! s:define_autocommands() abort
  augroup vfiler_rename
    autocmd! * <buffer>
    autocmd BufWriteCmd <buffer> call s:execute()
    autocmd InsertLeave,CursorMoved <buffer> call s:check_buffer()
  augroup END
endfunction

function! s:execute() abort
  if !s:check_buffer()
    return
  endif

  setlocal nomodified
  if !vfiler#buffer#exists(b:context.bufnr)
    call vfiler#core#error('Not exists filer buffer.')
    return
  endif

  call vfiler#action#on_rename_file_callback(
        \ getbufvar(b:context.bufnr, 'context'),
        \ b:elements,
        \ getline(1, line('$'))
        \ )

  " return rename buffer window
  let winnr = winbufnr(bufnr('%'))
  call vfiler#core#move_window(winnr)
endfunction

function! s:check_buffer() abort
  let line_len = line('$')
  let element_len = len(b:elements)
  if line_len < element_len
    call vfiler#core#warning('Invalid rename buffer! - Too few lines.')
    return 0
  elseif line_len > element_len
    call vfiler#core#warning('Invalid rename buffer! - Too many lines.')
    return 0
  endif

  for lnum in range(1, line_len)
    if empty(getline(lnum))
      call vfiler#core#warning('Invalid rename buffer! - blank line (' . lnum . ')')
      return 0
    endif
  endfor

  return 1
endfunction
