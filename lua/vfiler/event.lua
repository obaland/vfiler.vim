local vim = require 'vfiler/vim'

local M = {}

------------------------------------------------------------------------------
-- Interfaces
------------------------------------------------------------------------------

function M.register(group, bufnr, events, funcstr)
  local aucommands = {'augroup ' .. group }
  for event, _ in pairs(events) do
    local au = ('autocmd %s <buffer> :lua %s(%d, "%s")'):format(
      event, funcstr, bufnr, event
      )
    table.insert(aucommands, au)
  end
  table.insert(aucommands, 'augroup END')

  for _, au in ipairs(aucommands) do
    vim.command(au)
  end
end

return M
