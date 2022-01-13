local core = require('vfiler/core')
local vim = require('vfiler/vim')

local Job = require('vfiler/async/job')

local M = {}

local function update_dirstatus(dirstatus, status)
  if status.us == '!' then
    return
  end
  if status.us ~= ' ' and status.us ~= '?' then
    dirstatus.us = '*'
  end
  if status.them ~= ' ' then
    dirstatus.them = '*'
  end
end

function M.get_toplevel(dirpath)
  local command = ('git -C %s rev-parse --show-toplevel'):format(dirpath)
  local path = vim.fn.system(command)
  if (not path or #path == 0) or path:match('^fatal') then
    return nil
  end
  return core.path.normalize(path:sub(0, -2))
end

function M.reload_status(rootpath, options, on_completed)
  local args = {
    '--no-optional-locks',
    'status',
    '--porcelain=v1',
  }
  if options.untracked then
    table.insert(args, '-u')
  end
  if options.ignored then
    table.insert(args, '--ignored=matching')
  else
    table.insert(args, '--ignored=no')
  end

  local gitstatus = {}
  local job = Job.new({
    command = ('git -C %s %s'):format(rootpath, table.concat(args, ' ')),

    on_received = function(_, data)
      local status = data:sub(1, 2)
      local rpath = data:sub(4, -1)
      -- for renamed
      local splitted = vim.from_vimlist(vim.fn.split(rpath, ' -> '))
      rpath = splitted[#splitted]
      -- Removing: extra characters
      rpath = rpath:gsub('^"', ''):gsub('^"', '')
      local path = core.path.join(rootpath, rpath)
      gitstatus[path] = {
        us = status:sub(1, 1),
        them = status:sub(2, 2),
      }
    end,

    on_completed = function()
      -- update directories
      local dirs = {}
      for path, status in pairs(gitstatus) do
        local modified = core.path.parent(path)
        local dirstatus = dirs[modified]
        if not dirstatus then
          dirstatus = {
            us = ' ',
            them = ' ',
          }
          dirs[modified] = dirstatus
        end
        update_dirstatus(dirstatus, status)
      end

      for dir, status in pairs(dirs) do
        while rootpath ~= dir do
          local dirstatus = gitstatus[dir]
          if dirstatus then
            update_dirstatus(dirstatus, status)
          else
            gitstatus[dir] = {
              us = status.us,
              them = status.them,
            }
          end
          dir = core.path.parent(dir)
        end
      end
      on_completed(gitstatus)
    end,
  })
  job:start()
end

return M
