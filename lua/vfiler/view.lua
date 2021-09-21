local View = {}
View.__index = View

function View.new()
  return setmetatable({
    }, View)
end

function View.draw(context)
end

return View
