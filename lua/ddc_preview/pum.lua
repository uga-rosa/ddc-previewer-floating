local config = require("ddc_preview.config")

local M = {}

function M.is_pum()
  return config.get("ui") == "pum"
end

function M.visible()
  if M.is_pum() then
    return vim.fn["pum#visible"]()
  else
    return vim.fn.pumvisible()
  end
end

function M.complete_info()
  if M.is_pum() then
    return vim.fn["pum#complete_info"]()
  else
    return vim.fn.complete_info()
  end
end

function M.get_pos()
  if M.is_pum() then
    return vim.fn["pum#get_pos"]()
  else
    return vim.fn.pum_getpos()
  end
end

return M
