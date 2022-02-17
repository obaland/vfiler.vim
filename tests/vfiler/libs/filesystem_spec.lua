local fs = require('vfiler/libs/filesystem')

describe('filesystem', function()
  local paths = vim.fn.glob('./*', 1, 1)
  describe('stat', function()
    for _, path in ipairs(paths) do
      it(path, function()
        local stat = fs.stat(path)
        assert.is_equal(vim.fn.getfperm(path), stat.mode)
        -- TODO:
      end)
    end
  end)
end)
