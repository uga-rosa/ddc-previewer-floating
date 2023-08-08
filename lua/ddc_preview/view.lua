local config = require("ddc_preview.config")
local pum = require("ddc_preview.pum")
local utils = require("ddc_preview.utils")

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

---@param height number
---@param width number
function View:_win_open(height, width)
  local pum_pos = pum.get_pos()
  local row = pum_pos.row
  local col = pum_pos.col + pum_pos.width + pum_pos.scrollbar
  self.winid = vim.api.nvim_open_win(self.bufnr, false, {
    relative = "editor",
    row = row,
    col = col,
    height = math.min(height, vim.opt.lines:get() - row, config.get("max_height")),
    width = math.min(width, vim.opt.columns:get() - col, config.get("max_width")),
    border = "single",
    zindex = 10000,
  })
  for key, value in pairs(config.get("window_options")) do
    vim.api.nvim_set_option_value(key, value, { win = self.winid })
  end
end

---@param input dp.lsp.MarkedString | dp.lsp.MarkedString[] | ddc.lsp.MarkupContent
---@param contents? string[]
---@return string[] contents
local function converter(input, contents)
  return vim.lsp.util.convert_input_to_markdown_lines(input, contents)
end

---@param item dp.completeItem
function View:_open(item)
  if utils.get_rec(item, "user_data", "vsnip", "snippet") then
    -- source-vsnip
    local documents = converter({
      language = vim.bo.filetype,
      value = vim.fn["vsnip#to_string"](item.user_data.vsnip.snippet),
    })
    self:_post_markdown(documents)
  elseif utils.get_rec(item, "user_data", "lspitem") then
    -- source-nvim-lsp
    ---@type ddc.lsp.CompletionItem
    local lspItem = vim.json.decode(item.user_data.lspitem)
    local unresolvedItem = lspItem
    if lspItem.documentation == nil then
      local clientId = item.user_data.clientId
      lspItem = require("ddc_nvim_lsp.internal").resolve(clientId, lspItem) or lspItem
    end
    ---@type string[]
    local documents = {}

    -- detail
    if not utils.empty(lspItem.detail) then
      documents = converter({
        language = vim.bo.filetype,
        value = lspItem.detail,
      }, documents)
    end

    -- import from (tsc)
    local source = utils.get_rec(unresolvedItem, "data", "tsc", "source")
    if type(source) == "string" then
      if #documents > 0 then
        documents = converter("---", documents)
      end
      documents = converter(("import from `%s`"):format(source), documents)
    end

    -- documentation
    if not utils.empty(lspItem.documentation) then
      if #documents > 0 then
        documents = converter("---", documents)
      end
      documents = converter(lspItem.documentation, documents)
    end

    self:_post_markdown(documents)
  elseif utils.get_rec(item, "user_data", "help_tag") then
    -- source-nvim-lua
    local help_tag = item.user_data.help_tag
    if utils.empty(help_tag, "string") then
      return
    end

    self:_win_open(config.get("max_height"), math.min(78, config.get("max_width")))
    vim.api.nvim_set_option_value("buftype", "help", { buf = self.bufnr })
    vim.api.nvim_win_call(self.winid, function()
      local ok = pcall(vim.cmd.help, help_tag)
      if not ok then
        self:close()
      end
    end)
  elseif not utils.empty(item.info, "string") then
  end
end

---@param documents string[]
function View:_post_markdown(documents)
  if #documents == 0 then
    return
  end
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, true, documents)
  vim.lsp.util.stylize_markdown(self.bufnr, documents, {
    max_height = config.get("max_height"),
    max_width = config.get("max_width"),
  })
  local lines = vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, true) --[[@as string[] ]]
  self:_win_open(#lines, utils.max(lines, vim.api.nvim_strwidth))
end

return View
