local VFiler = require('vfiler/vfiler')

describe('vfiler', function()
  describe('start', function()
    it('simple', function()
      require'vfiler'.start()
      local vfiler = VFiler.get_current()
      vfiler:quit()
    end)

    -- options
    --[[
    local options = {
      auto_cd = { true, false },
      auto_resize = { true, false },
      columns = { 'indent,icon,name,mode,size,time' },
      header = { true, false },
      keep = { true, false },
      listed = { true, false },
      name = { '', 'foo', 'b-a-r' },
      show_hidden_files = { true, false },
      sort = { 'name', 'extension', 'time', 'size' },
      statusline = { true, false },
      layout = { 'none', 'right', 'left', 'top', 'bottom', 'tab' },
      width = { 10, 20, 30, 40, 50, 60, 70, 80, 90 },
      height = { 10, 20, 30, 40, 50, 60, 70, 80, 90 },
      new = { true, false },
      quit = { true, false },
    }
    ]]
  end)
end)
