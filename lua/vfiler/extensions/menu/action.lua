local action = require 'vfiler/extensions/action'
local vim = require 'vfiler/vim'

function action.select(extension)
  extension:select()
end

return action
