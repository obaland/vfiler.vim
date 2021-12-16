local vim = require('vfiler/vim')

local M = {}

function M.register(group, bufnr, events, funcstr)
  if not events then
    return
  end

  vim.command('augroup ' .. group)
  for event, _ in pairs(events) do
    local au = ('autocmd %s <buffer> :lua %s(%d, "%s")'):format(
      event, funcstr, bufnr, event
    )
    vim.command(au)
  end
  vim.command('augroup END')
end

return M
