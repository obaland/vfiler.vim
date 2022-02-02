local utility = require('tests/utility')
local VFiler = require('vfiler/vfiler')

describe('vfiler', function()
  describe('Start', function()
    it('simple', function()
      require'vfiler'.start()
      local vfiler = VFiler.get_current()
      vfiler:quit(true)
    end)

    local configs = {
      options = utility.generate_vfiler_options(),
    }
    it('with options: ' .. vim.inspect(configs), function()
      require'vfiler'.start('.', configs)
      local vfiler = VFiler.get_current()
      vfiler:quit(true)
    end)

    local args = utility.convert_command_options(configs.options)
    it('from command args: ' .. args, function()
      require'vfiler'.start_command(args)
      local vfiler = VFiler.get_current()
      vfiler:quit(true)
    end)
  end)
end)
