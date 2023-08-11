local M = {}

M.default = {
  ui = "pum",
  max_height = 30,
  max_width = 80,
  window_options = {
    wrap = false,
    number = false,
    signcolumn = "no",
    foldenable = false,
    foldcolumn = "0",
  },
}
M.config = vim.tbl_extend("force", {}, M.default)

---@param opt? table
function M.setup(opt)
  vim.validate({ opt = { opt, "t", true } })
  M.config = vim.tbl_extend("force", M.config, opt or {})
end

---@param key string
---@return unknown
function M.get(key)
  return M.config[key]
end

return M
