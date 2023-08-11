local M = {}

---@generic T
---@param list T[]
---@param cb fun(x: T): number
---@return number
function M.max(list, cb)
  assert(#list > 0, "Array is empty")
  local max_value = -math.huge
  for _, elem in ipairs(list) do
    local m = cb and cb(elem) or elem
    if m > max_value then
      max_value = m
    end
  end
  return max_value
end

local timer = {}

---@param name string
local function timer_reset(name)
  if timer[name] then
    timer[name]:stop()
    timer[name]:close()
    timer[name] = nil
  end
end

---@param name string
---@param fn function
---@param time number milliseconds
function M.debounse(name, fn, time)
  timer_reset(name)
  timer[name] = vim.uv.new_timer()
  timer[name]:start(
    time,
    0,
    vim.schedule_wrap(function()
      fn()
      timer_reset(name)
    end)
  )
end

return M
