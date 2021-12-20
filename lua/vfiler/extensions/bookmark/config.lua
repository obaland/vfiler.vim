local action = require('vfiler/extensions/bookmark/action')
local core = require('vfiler/core')

local M = {}

M.configs = {}

if core.is_nvim then
M.configs.options = {
  floating = {
    width = 'auto',
    height = 'auto',
    minwidth = 4,
    minheight = 1,
    relative = true,
  },
}
else
M.configs.options = {
  top = 'auto',
}
end

M.configs.mappings = {
  ['q']     = action.quit,
  ['<ESC>'] = action.quit,
}

function M.setup(configs)
  return core.table.merge(M.configs, configs)
end

return M
