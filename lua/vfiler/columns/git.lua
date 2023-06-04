local core = require('vfiler/libs/core')

local GitColumn = {}

local COLUMN_WIDTH = 4

function GitColumn.new()
  local Column = require('vfiler/columns/column')
  return core.inherit(GitColumn, Column, {
    {
      name = 'worktree',
      group = 'vfilerGitStatusWorktree',
      match = '.',
      options = {
        contained = true,
      },
    },
    {
      name = 'index',
      group = 'vfilerGitStatusIndex',
      match = '.',
      options = {
        contained = true,
        containedin = 'vfilerGitStatusDelimiter',
        nextgroup = 'vfilerGitStatusWorktree',
      },
    },
    {
      name = 'ignored',
      group = 'vfilerGitStatusIgnored',
      match = core.string.vesc('!!'),
      options = {
        contained = true,
        containedin = 'vfilerGitStatusDelimiter',
      },
    },
    {
      name = 'untracked',
      group = 'vfilerGitStatusUntracked',
      match = core.string.vesc('??'),
      options = {
        contained = true,
        containedin = 'vfilerGitStatusDelimiter',
      },
    },
    {
      name = 'unmerged',
      group = 'vfilerGitStatusUnmerged',
      match = [[DD\|AU\|UD\|UA\|DU\|AA\|UU]],
      options = {
        contained = true,
        containedin = 'vfilerGitStatusDelimiter',
      },
    },
    {
      name = 'modified',
      group = 'vfilerGitStatusModified',
      match = ' M',
      options = {
        contained = true,
        containedin = 'vfilerGitStatusDelimiter',
      },
    },
    {
      name = 'deleted',
      group = 'vfilerGitStatusDeleted',
      match = ' D',
      options = {
        contained = true,
        containedin = 'vfilerGitStatusDelimiter',
      },
    },
    {
      name = 'renamed',
      group = 'vfilerGitStatusRenamed',
      match = 'R.',
      options = {
        contained = true,
        containedin = 'vfilerGitStatusDelimiter',
      },
    },
    {
      name = 'delimiter',
      group = 'vfilerGitStatusDelimiter',
      match = '\\[\\zs..\\ze\\]',
      options = {
        contained = true,
        containedin = 'vfilerGitStatus',
      },
    },
    {
      name = 'status',
      group = 'vfilerGitStatus',
      region = {
        start_mark = 'g</',
        end_mark = '/>g',
      },
    },
  })
end

function GitColumn:to_text(item, width)
  local gitstatus = item.gitstatus
  local status = ''
  if gitstatus and (gitstatus.us ~= ' ' or gitstatus.them ~= ' ') then
    status = gitstatus.us .. gitstatus.them
  end
  if #status > 0 then
    status = '[' .. status .. ']'
  else
    status = (' '):rep(COLUMN_WIDTH)
  end
  return {
    string = status,
    width = COLUMN_WIDTH,
    syntax = 'status',
  }
end

function GitColumn:get_width(items, width, winid)
  return COLUMN_WIDTH
end

return GitColumn
