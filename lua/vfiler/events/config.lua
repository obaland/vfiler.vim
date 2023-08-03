local core = require('vfiler/libs/core')

local M = {}

-- TODO:
-- Update the file action.
--local function action_update_file(vfiler, context, view, path)
--  local lnum = view:lineof(path)
--  if lnum == 0 then
--    return
--  end
--  local item = view:get_item(lnum)
--  context:reload_item(item)
--  view:redraw_line(lnum)
--  -- NOTE: Reload the parent directory as git status is updated.
--  local parent = item.parent
--  while parent ~= nil do
--    lnum = view:lineof(parent.path)
--    if lnum > 0 then
--      view:redraw_line(lnum)
--    end
--    parent = parent.parent
--  end
--end

-- TODO:
-- Update the file.
--local function update_file(bufnr, group, event)
--  local vfilers = VFiler.get_visible_in_tabpage(0)
--  if #vfilers == 0 then
--    return
--  end
--  local path = core.path.normalize(vim.fn.bufname(bufnr))
--  for _, vfiler in ipairs(vfilers) do
--    vfiler:do_action(action_update_file, path)
--  end
--end

-- Default configs
M.configs = {
  enabled = true,
  events = {
    -- TODO:
    --vfiler = {
    --  {
    --    event = { 'BufWritePost' },
    --    callback = update_file,
    --  },
    --},
  },
}

--- Setup vfiler global events.
---@param configs table
function M.setup(configs)
  core.table.merge(M.configs, configs)
  return M.configs
end

return M
