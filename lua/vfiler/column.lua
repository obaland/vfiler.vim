local core = require('vfiler/core')

local M = {}

local loaded_columns = {}

function M.load(name)
  local column = loaded_columns[name]
  if column then
    return column
  end
  local code, cmodule = pcall(require, 'vfiler/columns/' .. name)
  if not code then
    core.message.error('Unknown "%s" column module.', name)
    return nil
  end
  loaded_columns[name] = cmodule.new()
  return loaded_columns[name]
end

return M
