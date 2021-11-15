"=============================================================================
" FILE: autoload/vfiler/configs.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

function! vfiler#configs#get_command_options() abort
  let options = luaeval('require"vfiler/config".configs.options')
  echom options
  return []
endfunction
