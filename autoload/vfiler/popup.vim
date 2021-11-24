"=============================================================================
" FILE: autoload/vfiler/popup.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

function! vfiler#popup#map(winid, bufnr, keys, funcstr) abort
  let l:mappings = {}
  for l:key in a:keys
    let l:escaped = l:key
    " for special keys, escape the key string
    if l:key =~ '^<.\+>$'
      let l:escaped = eval('"\' . l:key . '"')
    end
    let l:mappings[l:escaped] = printf(
          \ ":lua %s(%d, '%s')", a:funcstr, a:bufnr, l:key
          \ )
  endfor
  call setwinvar(a:winid, 'keymappings', l:mappings)
endfunction

function! vfiler#popup#filter(winid, key) abort
  let l:mappings = getwinvar(a:winid, 'keymappings')
  if has_key(l:mappings, a:key)
    call win_execute(a:winid, l:mappings[a:key])
  endif
  return v:true
endfunction
