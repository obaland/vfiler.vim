local action = require 'vfiler/extensions/action'

function action.check(extension)
  extension:check()
end

function action.execute(extension)
  extension:execute()
end

return action
