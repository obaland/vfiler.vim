local vim = require 'vfiler/vim'

local Extension = {}
Extension.__index = Extension

function Extension.new(name)
  return setmetatable({
      name = name,
      number = 0,
    }, Extension)
end

function Extension:run(lines, option)
end

function Extension:quit()
  if self.number > 0 then
    vim.command('silent bwipeout ' .. self.number)
  end
end

return Extension
