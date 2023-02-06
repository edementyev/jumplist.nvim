---@meta

---@class Jumplist.Entry
---@field file string
---@field buffer? number
---@field extmark? number
---@field line number 1-based
---@field col number 0-based

---@alias Jumplist.List table<number, Jumplist.Entry>
---@alias Jumplist.MarkList table<number, Jumplist.MarkOpts>

---@class Jumplist.MarkOpts : Jumplist.Entry
---@field window? number
---@field pop_stack? boolean remove all entries after inserted one (if we are in the middle of the list)
---@field direction? number default 1. 1 to insert past current, -1 to insert before current

---@class Jumplist.Json
---@field jumplist Jumplist.List
---@field current_jump number

---@class Jumplist.ExtmarkOpts
---@field buf? number
---@field file? string
