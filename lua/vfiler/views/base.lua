local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local Base = {}
Base.__index = Base

function Base.new()
  return setmetatable({
    src_winid = vim.fn.win_getid(),
    winid = 0,
    _buffer = nil,
  }, Base)
end

function Base:close()
  self:_on_close(self.winid, self._buffer)
  self.winid = 0
  self._buffer = nil
end

function Base:define_mappings(mappings, funcstr)
  return self._buffer:define_mappings(mappings, funcstr)
end

function Base:open(buffer, options)
  self._buffer = buffer
  if self.winid > 0 then
    self.winid = self:_on_update(self.winid, buffer, options)
  else
    self.winid = self:_on_open(buffer, options)
  end

  -- set window options
  -- default window options
  local winoptions = {
    colorcolumn = '',
    conceallevel = 2,
    concealcursor = 'nvc',
    foldcolumn = '0',
    foldenable = false,
    list = false,
    number = true,
    relativenumber = false,
    spell = false,
    wrap = false,
  }
  vim.set_win_options(
    self.winid,
    core.table.merge(winoptions, options.winoptions)
  )
  return self.winid
end

function Base:winnr()
  return vim.fn.bufwinnr(self._buffer.number)
end

function Base:_on_close(winid, buffer)
  -- Not implemented
end

function Base:_on_open(buffer, options)
  -- Not implemented
end

function Base:_on_update(winid, buffer, options)
  -- Not implemented
end

return Base
