local Column = {}
Column.__index = Column

function Column.new(name)
  return setmetatable({
      name = name,
    }, Column)
end

return Column
