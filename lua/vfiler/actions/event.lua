local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')
local buffer = require('vfiler/actions/buffer')

local M = {}

local event_lock = setmetatable({
  _bufnrs = {},
}, {})

function event_lock:lock(bufnr)
  if self._bufnrs[bufnr] then
    return true
  end
  self._bufnrs[bufnr] = true
end

function event_lock:unlock(bufnr)
  self._bufnrs[bufnr] = nil
end

function M.latest_update(vfiler, context, view)
  local bufnr = view:bufnr()
  if event_lock:lock(bufnr) then
    return
  end

  core.try({
    function()
      local root = context.root
      if vim.fn.getftime(root.path) > root.time then
        vfiler:do_action(buffer.reload)
        return
      end

      for item in view:walk_items() do
        if item.type == 'directory' then
          if vim.fn.getftime(item.path) > item.time then
            vfiler:do_action(buffer.reload)
            return
          end
        end
      end
    end,
    finally = function()
      event_lock:unlock(bufnr)
    end,
  })
end

function M.close_floating(vfiler, context, view)
  if view:type() == 'floating' then
    -- For floating windows, close the window,
    -- including the buffer, as this will lead to problems.
    vfiler:wipeout()
  end
end

return M
