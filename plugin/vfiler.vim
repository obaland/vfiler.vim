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

highlight default link vfilerGitStatusDelimiter Comment
highlight default vfilerGitStatusDeleted
      \ ctermfg=167 guifg=#fb4934
highlight default vfilerGitStatusIndex
      \ ctermfg=142 guifg=#b8bb26
highlight default vfilerGitStatusModified
      \ ctermfg=214 guifg=#fabd2f
highlight default vfilerGitStatusUnmerged
      \ ctermfg=167 guifg=#fb4934
highlight default link vfilerGitStatusUntracked Comment
highlight default link vfilerGitStatusIgnored   Comment
highlight default vfilerGitStatusRenamed
      \ ctermfg=214 guifg=#fabd2f
highlight default vfilerGitStatusWorktree
      \ ctermfg=1 guifg=#dc233f

highlight default link vfilerStatusLine        StatusLine
highlight default vfilerStatusLineSection
      \ ctermfg=230 ctermbg=57 guifg=#ffffd7 guibg=#44788E

highlight default link vfilerFloatingWindowTitle Constant

highlight default link vfilerBookmarkCategory  Title
highlight default link vfilerBookmarkDirectory Directory
highlight default link vfilerBookmarkFile      None
highlight default link vfilerBookmarkLink      Constant
highlight default link vfilerBookmarkPath      Comment

" Commands
function! s:complete(arglead, cmdline, cursorpos) abort
  let list = luaeval(
        \ 'require("vfiler/config").complete_options(_A)', a:arglead
        \ )
  if len(list) > 0
    return list
  endif
  return map(getcompletion(a:arglead, 'dir'), {-> escape(v:val, ' ')})
endfunction

" Define commands
command! -nargs=? -complete=customlist,s:complete VFiler
      \ call luaeval('require("vfiler").start_command(_A)', <q-args>)
