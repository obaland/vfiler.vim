"=============================================================================
" FILE: autoload/vfiler/popup.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

let s:keymappings = {}

function! vfiler#popup#map(winid, keys, funcstr) abort
  let l:bufnr = winbufnr(a:winid)
  let l:mappings = {}
  for l:key in a:keys
    let l:escaped = l:key
    " for special keys, escape the key string
    if l:key =~ '^<.\+>$'
      let l:escaped = eval('"\' . l:key . '"')
    end
    let l:mappings[l:escaped] = printf(
          \ ":lua %s(%d, '%s')", a:funcstr, l:bufnr, l:key
          \ )
  endfor
  let s:keymappings[a:winid] = l:mappings
endfunction

function! vfiler#popup#unmap(winid) abort
  call remove(s:keymappings, a:winid)
endfunction

function! vfiler#popup#filter(winid, key) abort
  if !has_key(s:keymappings, a:winid)
    call vfiler#core#error('There is no keymappings.')
    popup_close(a:winid)
    return v:true
  endif

  let l:mappings = s:keymappings[a:winid]
  if has_key(l:mappings, a:key)
    call win_execute(a:winid, l:mappings[a:key])
  end
  return v:true
endfunction
