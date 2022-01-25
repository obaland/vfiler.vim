local M = {}

local action_modules = {
  'basic',
  'bookmark',
  'event',
  'file',
  'preview',
  'utility',
}

local function merge_actions(dest, src)
  for name, value in pairs(src) do
    if type(value) == 'table' then
      if not dest[name] then
        dest[name] = {}
      end
      merge_actions(dest[name], value)
    else
      assert(not dest[name], 'Duplicate "' .. name .. '" action.')
      dest[name] = value
    end
  end
  return dest
end

-- merge actions
for _, name in ipairs(action_modules) do
  local module = require('vfiler/actions/' .. name)
  assert(module, 'Not exists "' .. name .. '" module.')
  merge_actions(M, module)
end

return M
