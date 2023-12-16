local View = require("ddc_previewer_floating.view")
local pum = require("ddc_previewer_floating.pum")
local utils = require("ddc_previewer_floating.utils")
local config = require("ddc_previewer_floating.config")

local M = {}

local GROUP_NAME = "ddc-preview"

function M.enable()
  local view = View.new()
  local function open()
    utils.debounse("view_open", function()
      view:open()
    end, 100)
  end
  local function close()
    if vim.api.nvim_get_mode().mode == "i" then
      -- textlock
      vim.schedule(function()
        view:close()
      end)
    else
      view:close()
    end
  end

  local group = vim.api.nvim_create_augroup(GROUP_NAME, {})
  if pum.is_pum() then
    vim.api.nvim_create_autocmd("User", {
      pattern = "PumCompleteChanged",
      group = group,
      callback = open,
    })
    vim.api.nvim_create_autocmd("User", {
      pattern = { "PumClose", "PumCompleteDone" },
      group = group,
      callback = close,
    })
  else
    vim.api.nvim_create_autocmd("CompleteChanged", {
      group = group,
      callback = open,
    })
    vim.api.nvim_create_autocmd("CompleteDone", {
      group = group,
      callback = close,
    })
  end
end

function M.disable()
  vim.api.nvim_del_augroup_by_name(GROUP_NAME)
end

M.setup = config.setup

return M
