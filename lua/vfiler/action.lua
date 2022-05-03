local config = require('vfiler/actions/config')

local action_modules = {
  'bookmark',
  'buffer',
  'cursor',
  'directory',
  'file_operation',
  'open',
  'preview',
  'select',
  'view',
  'yank',
}

local M = setmetatable({}, {
  __index = function(t, key)
    for _, name in ipairs(action_modules) do
      local module = require('vfiler/actions/' .. name)
      local func = module[key]
      if func then
        t[key] = func
        return func
      end
    end
    error(('"%s" action is undefined.'):format(key))
    return nil
  end,
})

function M.setup(configs)
  config.setup(configs)
end

return M
