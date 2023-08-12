---:h complete-items
---@class dp.completeItem
---@field word string
---@field abbr? string
---@field menu? string
---@field info? string
---@field kind? string
---@field icase? number
---@field equal? number
---@field dup? number
---@field empty? number
---@field user_data? unknown

---@class PreviewContext
---@field row? number
---@field col? number
---@field height? number
---@field width? number
---@field isFloating? boolean
---@field split? "horizontal" | "vertical" | "no"

---@class EmptyPreviewer
---@field kind "empty"

---@class HelpPreviewer
---@field kind "help"
---@field tag string

---@class CommandPreviewer
---@field kind "command"
---@field command string

---@class MarkdownPreviewer
---@field kind "markdown"
---@field contents string[]

---@class TextPreviewer
---@field kind "text"
---@field contents string[]

---@alias Previewer EmptyPreviewer | HelpPreviewer | CommandPreviewer | MarkdownPreviewer | TextPreviewer
