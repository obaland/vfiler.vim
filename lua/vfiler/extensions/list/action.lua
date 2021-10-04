local action = require 'vfiler/extensions/action'

function action.select()
  action.get_extension():select()
end

return action
