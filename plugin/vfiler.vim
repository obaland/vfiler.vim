"=============================================================================
" FILE: plugin/vfiler.vim
" AUTHOR: OBARA Taihei
" License: MIT license
"=============================================================================

if exists('g:loaded_vfiler')
  finish
endif

if has('nvim') && !has('nvim-0.5.0')
  echomsg 'VFiler requires Neovim 0.5.0 or later.'
  finish
elseif !has('nvim')
  if !has('lua') || v:version < 802
    echomsg 'VFiler requires Vim 8.2 or later with Lua support ("+lua").'
    finish
  endif
endif

let g:loaded_vfiler = 1

" Syntax highlights
highlight default link vfilerDirectory         Directory
highlight default link vfilerExecutable        PreProc
highlight default link vfilerFile              None
highlight default link vfilerHeader            Statement
highlight default link vfilerHidden            Comment
highlight default link vfilerLink              Constant
highlight default link vfilerSelected          Title
highlight default link vfilerSize              Statement
highlight default link vfilerTime              None
highlight default link vfilerTimeToday         PreProc
highlight default link vfilerTimeWeek          Type

highlight default vfilerStatusLine_ChooseWindowKey ctermfg=230 ctermbg=57 guifg=#ffffd7 guibg=#44788E

highlight default link vfilerBookmark_Category  Title
highlight default link vfilerBookmark_Directory Directory
highlight default link vfilerBookmark_File      None
highlight default link vfilerBookmark_Link      Constant
highlight default link vfilerBookmark_Path      Comment
highlight default link vfilerBookmark_Warning   WarningMsg

" Define commands
command! -nargs=? -complete=customlist,vfiler#complete VFiler
      \ call vfiler#start(<q-args>)
