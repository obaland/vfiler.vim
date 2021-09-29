local List = {}

function List.new()
  return setmetatable({
    }, List)
end

return List
