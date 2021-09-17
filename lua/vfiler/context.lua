local Context = {}
Context.__index = Context

function Context.new(buffer, configs)
  --[[
  local object = setmetatable({
      buffer = buffer,
      path = configs.path,
    }, Context)
  object:switch(configs.path)
  return object
  ]]
  return setmetatable({
      buffer = buffer,
      path = configs.path,
    }, Context)
end

function Context:switch(path)
end
