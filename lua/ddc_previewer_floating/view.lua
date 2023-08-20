local config = require("ddc_previewer_floating.config")
local pum = require("ddc_previewer_floating.pum")
local utils = require("ddc_previewer_floating.utils")

---@class View
---@field bufnr number
---@field winid? number
local View = {}

---@return View
function View.new()
  local self = setmetatable({}, { __index = View })
  self:_buf_reset()
  return self
end

function View:_buf_reset()
  if self.bufnr and vim.api.nvim_buf_is_valid(self.bufnr) then
    vim.api.nvim_buf_delete(self.bufnr, { force = true })
  end
  self.bufnr = vim.api.nvim_create_buf(false, true)
end

function View:open()
  self:close()
  if not pum.visible() then
    return
  end
  local complete_info = pum.complete_info()
  local current_item = complete_info.items[complete_info.selected + 1]
  if current_item == nil then
    return
  end
  self:_buf_reset()
  self:_open(current_item)
  vim.cmd.redraw()
end

function View:close()
  if self.winid and vim.api.nvim_win_is_valid(self.winid) then
    vim.api.nvim_win_close(self.winid, true)
  end
  self.winid = nil
end

---@param context PreviewContext
function View:_win_open(context)
  local max_width = config.get("max_width")
  local max_height = config.get("max_height")
  self.winid = vim.api.nvim_open_win(self.bufnr, false, {
    relative = "editor",
    row = context.row,
    col = context.col,
    height = math.min(context.height, max_height),
    width = math.min(context.width, max_width),
    border = config.get("border"),
    zindex = config.get("zindex"),
  })
  for key, value in pairs(config.get("window_options")) do
    vim.api.nvim_set_option_value(key, value, { win = self.winid })
  end
end

---@param item dp.completeItem
function View:_open(item)
  local pum_pos = pum.get_pos()
  local row = pum_pos.row
  local col = pum_pos.col + pum_pos.width
  if utils.is_truthy(pum_pos.scrollbar) then
    col = col + 1
  end
  local max_width = config.get("max_width")
  local max_height = config.get("max_height")
  ---@type PreviewContext
  local context = {
    row = row,
    col = col,
    width = max_width,
    height = max_height,
    isFloating = true,
  }
  ---@type Previewer
  local previewer = vim.fn["ddc#get_previewer"](item, context)
  if previewer.kind == "empty" and type(item.info) == "string" and item.info ~= "" then
    local info = item.info:gsub("\r\n?", "\n")
    previewer = { kind = "text", contents = vim.split(info, "\n") }
  end

  if previewer.kind == "empty" then
    return
  elseif previewer.contents then
    -- text or markdown
    local contents = previewer.contents
    if #contents == 0 then
      return
    end
    vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, true, contents)
    if previewer.kind == "markdown" then
      vim.lsp.util.stylize_markdown(self.bufnr, contents, {
        max_height = max_height,
        max_width = max_width,
      })
      contents = vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, true) --[[@as string[] ]]
    end
    context.height = #contents
    context.width = utils.max(contents, vim.api.nvim_strwidth)
    self:_win_open(context)
  else
    -- help or command
    local command = previewer.kind == "help" and "setlocal buftype=help | help " .. previewer.tag
      or previewer.command
    self:_win_open(context)
    vim.api.nvim_win_call(self.winid, function()
      local ok = pcall(function()
        vim.cmd(command)
      end)
      if not ok then
        self:close()
      end
    end)
  end
end

return View
