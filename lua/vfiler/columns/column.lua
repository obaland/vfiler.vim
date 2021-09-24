local Column = {}
Column.__index = Column

function Column.new(name)
  return setmetatable({
      name = name,
      variable = false,
    }, Column)
end

function Column:get_width(context, width)
  return 0
end

function Column:highlights()
  return {}
end

function Column:syntaxes()
  return {}
end

function Column:to_line(context, lnum, width)
  return 'Not implemented'
end

return Column
