local M = require('vfiler/base/mapping').new()

function M.do_action(bufnr, func)
  --action.do_action(bufnr, func)
end

function M.setup(keymaps)
  M:_setup(keymaps, 'vfiler/extensions/rename')
end

return M
