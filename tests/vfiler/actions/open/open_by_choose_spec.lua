local core = require('vfiler/libs/core')
local a = require('vfiler/actions/open')
local u = require('tests/helper/utilities')

describe('open actions', function()
  local layouts = {
    'none', 'right', 'left', 'top', 'bottom', 'tab', 'floating'
  }
  for _, layout in ipairs(layouts) do
    local configs = {
      options = u.vfiler.generate_options(),
    }
    configs.options.layout = layout
    local vfiler = u.vfiler.start(configs)
    assert.is_not_nil(vfiler)

    local view = vfiler._view
    assert.is_not_nil(view)
    local lnum = u.int.random(2, view:num_lines())
    local target = view:get_item(lnum)
    if target then
      core.cursor.move(lnum)
      local message = ('open by choose [layout:%s] (%s)'):format(layout, target.path)
      it(u.vfiler.desc(message, vfiler), function()
        assert.is_not_nil(view)
        vfiler:do_action(a.open_by_choose)
      end)
    end
    vfiler:quit(true)
  end
end)

describe('window picker statuslines', function()
  local cmdline = require('vfiler/libs/cmdline')
  local VFiler = require('vfiler/vfiler')
  local original_getchar = cmdline.getchar
  local original_clear_prompt = cmdline.clear_prompt
  local dir, path, filer, view, first, second, laststatus

  local function check_prompt(choose)
    cmdline.getchar = function(prompt)
      assert.are.equal(2, vim.o.laststatus)
      local first_key = vim.wo[first].statusline:match('Section# +(%w) ')
      local second_key = vim.wo[second].statusline:match('Section# +(%w) ')
      assert.is_not_nil(first_key)
      assert.is_not_nil(second_key)
      assert.not_equal(first_key, second_key)
      assert.are.equal(('choose (%s/%s) ?'):format(first_key, second_key), prompt)
      return choose and second_key or '<ESC>'
    end
  end

  local function check_restored()
    assert.are.equal('first window', vim.wo[first].statusline)
    assert.are.equal('second window', vim.wo[second].statusline)
    assert.are.equal(0, vim.o.laststatus)
  end

  before_each(function()
    laststatus = vim.o.laststatus
    vim.cmd('tabnew')
    first = vim.api.nvim_get_current_win()
    vim.cmd('rightbelow split')
    second = vim.api.nvim_get_current_win()
    vim.wo[first].statusline = 'first window'
    vim.wo[second].statusline = 'second window'
    vim.o.laststatus = 0

    dir = vim.fn.resolve(vim.fn.tempname())
    assert.are.equal(1, vim.fn.mkdir(dir))
    path = core.path.join(dir, 'picked.txt')
    assert.are.equal(0, vim.fn.writefile({ 'picked' }, path))
    assert.is_true(require('vfiler').start(dir, {
      options = { columns = 'name', layout = 'left', new = true },
    }))
    filer = VFiler.get(vim.fn.bufnr())
    view = filer._view
    view:move_cursor(path)
    cmdline.clear_prompt = function() end
  end)

  after_each(function()
    cmdline.getchar = original_getchar
    cmdline.clear_prompt = original_clear_prompt
    if filer then
      filer:wipeout()
      filer = nil
    end
    vim.cmd('tabclose!')
    vim.o.laststatus = laststatus
    vim.fn.delete(dir, 'rf')
  end)

  it('shows both keys and restores the statuslines after selecting a window', function()
    local restored
    vim.api.nvim_create_autocmd('WinEnter', {
      callback = function()
        if vim.api.nvim_get_current_win() == second then
          restored = { vim.wo[first].statusline, vim.wo[second].statusline }
          return true
        end
      end,
    })
    check_prompt(true)
    filer:do_action(a.open_by_choose)
    assert.are.same({ 'first window', 'second window' }, restored)
    assert.are.equal(0, vim.o.laststatus)
    assert.are.equal(second, vim.api.nvim_get_current_win())
    local bufnr = vim.api.nvim_win_get_buf(second)
    assert.are.equal(path, vim.api.nvim_buf_get_name(bufnr))
  end)

  it('restores the statuslines and stays in the filer after cancelling', function()
    local first_buf = vim.api.nvim_win_get_buf(first)
    local second_buf = vim.api.nvim_win_get_buf(second)
    check_prompt(false)
    filer:do_action(a.open_by_choose)
    check_restored()
    assert.are.equal(view:winid(), vim.api.nvim_get_current_win())
    assert.are.equal(first_buf, vim.api.nvim_win_get_buf(first))
    assert.are.equal(second_buf, vim.api.nvim_win_get_buf(second))
  end)
end)
