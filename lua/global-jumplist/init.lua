---@class JumpList
---@field list table<JumpEntry>
local M = {}

---@class JumpEntry
---@field file? string
---@field buf? number
---@field line number 1-based
---@field col number 0-based

local u = require("global-jumplist.util")
local api = vim.api
local cmd = vim.cmd

--  jump line  col file
--    3	 1     0   a.lua
--    2	 70    0   b.lua
--    1  1154  23  b.lua
-- >

local current_jump = 0

---@type table<number, JumpEntry>
local list = {}

function M.get_list()
	return list
end

function M.clear()
	list = {}
end

---@param entry JumpEntry
function M.equals_current(entry)
	if list[current_jump] ~= nil then
		return list[current_jump].file == entry.file and list[current_jump].line == entry.line
		-- do not check column
		-- and list[current_jump].col == cursor[2]
	else
		return false
	end
end

function M.mark(window)
	local file, cursor
	if window ~= nil then
		file = api.nvim_win_call(window, function()
			---@diagnostic disable-next-line: redundant-return-value
			return vim.fn.expand("%:p")
		end)
		cursor = api.nvim_win_get_cursor(window)
	else
		file = vim.fn.expand("%:p")
		cursor = api.nvim_win_get_cursor(0)
	end
	M.push({ file = file, line = cursor[1], col = cursor[2] })
end

-- pushes a new entry to the list at current position removing all entries after it
---@param entry JumpEntry
function M.push(entry)
	-- if entry equals current entry, do nothing
	if entry.file == nil then
		if entry.buf == nil then
			-- TODO: error
			return
		end
		local ok, bufinfo = pcall(vim.fn.getbufinfo, { entry.buf })
		if ok then
			entry.file = bufinfo[1].name
		else
			-- TODO: error
      return
		end
	end
	if M.equals_current(entry) then
		return
	end
	if current_jump < #list and current_jump > 0 then
		-- remove all entries after current position
		u.splice(list, current_jump + 1, -1, { { file = entry.file, line = entry.line, col = entry.col } }, true)
	else
		table.insert(list, { file = entry.file, line = entry.line, col = entry.col })
	end
	current_jump = #list
end

---@param buf number
---@param entry JumpEntry
local function buf_has_entry(buf, entry)
	local bufinfo = vim.fn.getbufinfo({ buf })[1]
	return bufinfo and bufinfo.name == entry.file
end

-- TODO: hook on to crucial commands/motions that set jumplist
-- ? - :e - BufWinEnter
-- gg, G, m', m`
--
-- TODO: invalidate current_jump if cursor was moved out of it's line,
-- meaning that if we jump backwards, next stop would be current_jump position,
-- not the previous one

local function jump(entry)
	-- get all buffers
	-- if some buffer has the same file as entry.file, open buf in this window and move cursor position
	local bufs = api.nvim_list_bufs()
	table.insert(bufs, 0, 0)
	for _, buf in ipairs(bufs) do
		if buf_has_entry(buf, entry) then
			-- use this buf
			api.nvim_win_set_buf(0, buf)
			api.nvim_win_set_cursor(0, { entry.line, entry.col })
			return
		end
	end
	cmd(("edit %s"):format(entry.file))
	api.nvim_win_set_cursor(0, { entry.line, entry.col })
end

function M.jump_next()
	if current_jump < #list then
		jump(list[current_jump + 1])
		current_jump = current_jump + 1
	end
end

function M.jump_prev()
	if current_jump > 1 then
		-- TODO: if current_jump is the last one,
		-- check if we are outside of current_jump's line
		-- if so, jump to current_jump
		jump(list[current_jump - 1])
		current_jump = current_jump - 1
	end
end

-- moves the current position to next entry in another file and opens it in current window
function M.jump_next_file() end

---@see M.jump_next_file
function M.jump_prev_file() end

function M.setup(opts) end

return M
