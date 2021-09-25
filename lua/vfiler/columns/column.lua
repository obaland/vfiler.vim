local Column = {}
Column.__index = Column

function Column.new(name)
  return setmetatable({
      name = name,
      variable = false,
      stretch = false,
    }, Column)
end

function Column:get_text(context, lnum, width)
  return 'Not implemented'
end

function Column:get_width(context, lnum, width)
  return 0
end

function Column:highlights()
  return {}
end

function Column:syntaxes()
  return {}
end

return Column
