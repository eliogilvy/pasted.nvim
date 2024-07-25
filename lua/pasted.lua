local M = {}

local registers = '"abcdefghijklmnopqrstuvwxyz0123456789%#=:.-+*'
local user_registers = '"abcdefghijklmnopqrstuvwxyz0123456789%#=:.-+*'

---@class RegItem
---@field register string
---@field contents string

---@param str string
local function escape_pattern(str) return str:gsub("([%[%]%(%)%.%+%-%*%?%^%$%%])", "%%%1") end

---@param str string
---@return boolean
local function is_not_empty(str)
  local s = str:match("^%s*(.-)%s*$")
  return s ~= nil and #s > 0
end

---Returns a list of registers with optional non_empty_only flag
---@param show_all boolean
---@return RegItem[]
local function get_registers(show_all)
  ---@type RegItem[]
  local items = {}
  for i = 1, #user_registers do
    local register = user_registers:sub(i, i)
    ---@type string
    local contents = vim.fn.getreg(register)

    local checked_register = escape_pattern(register)
    local valid_register = string.match(registers, checked_register) ~= nil

    if is_not_empty(contents) or show_all then
      ---@type RegItem
      local item = { register = register, contents = contents }
      table.insert(items, item)
    elseif not valid_register then
      error(register .. " is not a valid nvim register")
    end
  end
  return items
end

---Formats the item to be shown in the register list
---@param item RegItem
---@return string
local function format_item(item) return item.register .. ": " .. item.contents end

---@param item RegItem
---@param after boolean
---@param follow boolean
local function on_paste(item, after, follow)
  if not item or item == nil then return end

  ---@type string[]
  local lines = {}

  for line in string.gmatch(item.contents, "[^\r\n]+") do
    table.insert(lines, line)
  end
  vim.api.nvim_put(lines, "", after, follow)
end

---Gets the highighted line(s) and returns them
---@return table
local function get_visual_selection()
  local mode = vim.fn.mode()

  if not mode == "v" or not mode == "V" then
    error("Shouldn't call this command in non-visual mode. Offending mode: " .. mode)
  end

  local line_start = vim.fn.getpos("v")
  local line_end = vim.fn.getpos(".")

  ---@type table
  local lines = vim.api.nvim_buf_get_lines(0, line_start[2] - 1, line_end[2], false)

  if mode == "v" then
    ---The col of the start of the highlighted line(s)
    ---@type integer
    local string_start = line_start[3]

    ---The col of the end of the highlighted line(s)
    ---@type integer
    local string_end = line_end[3]

    ---Trim the first line based on the first col index
    lines[1] = string.sub(lines[1], string_start)

    ---Trim the last line based on the last col index
    if #lines == 1 then
      lines[1] = string.sub(lines[1], 1, string_end - string_start + 1)
    else
      ---@type integer
      local last_line = #lines
      lines[last_line] = string.sub(lines[last_line], 1, string_end)
    end
  end

  return lines
end

---@param item RegItem
---@param lines table
local function fill_register(item, lines)
  if not item or item == nil then return end
  if #lines > 0 then
    vim.fn.setreg(item.register, lines)
  else
    print("Tried to paste empty selection")
  end
end

M.paste_options = function()
  local contents = get_registers(false)
  vim.ui.select(
    contents,
    { prompt = "Paste options", format_item = format_item },
    function(item) on_paste(item, true, true) end
  )
end

M.register_options = function()
  local contents = get_registers(true)
  local lines = get_visual_selection()
  vim.ui.select(
    contents,
    { prompt = "Registers", format_item = format_item },
    function(item) fill_register(item, lines) end
  )
end

local command = function(name, callback, opts)
  vim.api.nvim_create_user_command(name, callback, opts or {})
end

local function create_user_commands()
  command("PastedY", function() M.register_options() end)
  command("PastedP", function() M.paste_options() end)
  command("Pastedp", function() M.paste_options() end)
end

M.setup = function() create_user_commands() end

return M
