local core = require('vfiler/libs/core')

local COLUMN_WIDTH = 4

local GitColumn = {}

function GitColumn.new()
  local Column = require('vfiler/columns/column')
  return core.inherit(GitColumn, Column, {
    syntaxes = {
      status = {
        group = 'vfilerGitStatus',
        start_mark = 'g@s\\',
      },

      delimiter = {
        group = 'vfilerGitStatusDelimiter',
        pattern = '\\[\\zs..\\ze\\]',
        options = {
          contained = true,
          containedin = 'vfilerGitStatus',
        },
      },

      index = {
        group = 'vfilerGitStatusIndex',
        pattern = '.',
        options = {
          contained = true,
          containedin = 'vfilerGitStatusDelimiter',
          nextgroup = 'vfilerGitStatusWorktree',
        },
      },

      worktree = {
        group = 'vfilerGitStatusWorktree',
        pattern = '.',
        options = {
          contained = true,
        },
      },

      renamed = {
        group = 'vfilerGitStatusRenamed',
        pattern = 'R.',
        options = {
          contained = true,
          containedin = 'vfilerGitStatusDelimiter',
        },
        priority = 1,
      },

      deleted = {
        group = 'vfilerGitStatusDeleted',
        pattern = ' D',
        options = {
          contained = true,
          containedin = 'vfilerGitStatusDelimiter',
        },
        priority = 2,
      },

      modified = {
        group = 'vfilerGitStatusModified',
        pattern = ' M',
        options = {
          contained = true,
          containedin = 'vfilerGitStatusDelimiter',
        },
        priority = 3,
      },

      unmerged = {
        group = 'vfilerGitStatusUnmerged',
        pattern = [[DD\|AU\|UD\|UA\|DU\|AA\|UU]],
        options = {
          contained = true,
          containedin = 'vfilerGitStatusDelimiter',
        },
        priority = 4,
      },

      untracked = {
        group = 'vfilerGitStatusUntracked',
        pattern = '??',
        options = {
          contained = true,
          containedin = 'vfilerGitStatusDelimiter',
        },
        priority = 5,
      },

      ignored = {
        group = 'vfilerGitStatusIgnored',
        pattern = '!!',
        options = {
          contained = true,
          containedin = 'vfilerGitStatusDelimiter',
        },
        priority = 6,
      },
    },
    end_mark = '\\g@',
  })
end

function GitColumn:get_width(items, width)
  return COLUMN_WIDTH
end

function GitColumn:_get_text(item, width)
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
  return status
end

function GitColumn:_get_syntax_name(item, width)
  return 'status'
end

return GitColumn
