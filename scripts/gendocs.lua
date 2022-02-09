local docgen = require('docgen')

local docs = {}

local filepaths = {
  './lua/vfiler.lua',
}
local docpath = './doc/vfiler_.txt'

function docs.test()
  local doc = io.open(docpath, 'w')
  for _, path in ipairs(filepaths) do
    docgen.write(path, doc)
  end
  doc:write("vim:ft=help:norl:ts=8:tw=78:\n")
  doc:close()
  vim.cmd('checktime')
end

docs.test()

return docs
