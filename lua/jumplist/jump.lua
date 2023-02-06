---@class Jumplist
---@field list table<Jumplist.Entry>
local M = {}

local api = vim.api
local cmd = vim.cmd

local log = require("jumplist.log")
local c = require("jumplist.config")
local u = require("jumplist.util")
local scopes = require("jumplist.scopes")
local extmarks = require("jumplist.extmarks")

---@type Jumplist.List
M.jumplist = {}
---@type number
M.current_jump = 0

---@return Jumplist.Json
function M.get_json()
	return {
		jumplist = M.jumplist,
		current_jump = M.current_jump,
	}
end

function M.get_current_jump()
	return M.jumplist[M.current_jump]
end

function M.get_current_jump_idx()
	return M.current_jump
end

---@param j? Jumplist.Json
function M.init(j)
	M.jumplist = j and j.jumplist or {}
	M.current_jump = j and j.current_jump or 0
end

M.init()

-- if true, prevents from adding jumps on events(e.g. BufLeave) when switching buffers
---@type boolean
vim.g.jumplist_keepjumps = false

---@param opts? Jumplist.MarkOpts
function M.mark(opts)
	opts = opts or {}
	---@type Jumplist.MarkOpts
	local entry = {}
	local window = opts.window or 0
	entry.buffer = api.nvim_win_get_buf(window)
	entry.file = opts.file or api.nvim_buf_get_name(entry.buffer)
	if not c.config.filename_valid(entry.file) then
		return
	end
	if opts.line == nil then
		entry.line, entry.col = unpack(api.nvim_win_get_cursor(window))
	else
		entry.line = opts.line
		entry.col = opts.col or 0
	end
	-- NOTE: equality check should be passed in as param
	if vim.g.jumplist_keepjumps == true or u.eq(M.get_current_jump(), entry, scopes.enum.cursor) then
		return
	end
	entry.pop_stack = vim.F.if_nil(opts.pop_stack, c.config.default_pop_stack)
	local direction = opts.direction or 1
	M.push_entry(
		entry,
		math.max(
			M.current_jump + math.max(direction, 0), --[[convert -1 to 0]]
			1
		)
	)
	if entry.pop_stack then
		M.current_jump = #M.jumplist
	else
		if direction < 0 then
			M.current_jump = M.current_jump + 1
		end
	end
end

---@param entry Jumplist.MarkOpts
---@param at_index number
function M.push_entry(entry, at_index)
	-- log.info("push_entry:", entry, at_index)
	-- check capacity
	if #M.jumplist >= c.config.max_entries then
		-- pop first entry if reached max_entries
		extmarks.remove_extmark(M.jumplist[1].buffer, M.jumplist[1].extmark)
		table.remove(M.jumplist, 1)
    if M.current_jump > 1 then
      M.current_jump = M.current_jump - 1
    end
	end
	u.splice(
		M.jumplist,
		at_index,
		-- if pop_stack == true, remove all entries after current position
		entry.pop_stack and 0 or nil,
		{ entry },
		true,
		function(idx)
			extmarks.remove_extmark(M.jumplist[idx].buffer, M.jumplist[idx].extmark)
		end
	)
	-- set extmark
	entry.extmark = extmarks.set_extmark(entry.buffer, entry.line, entry.col)
	log.trace("position marked", entry)
end

---@param entry Jumplist.Entry
function M.jump(entry)
	-- 0-based, 0-based
	local pos
	local window_to_use = 0
	if entry.buffer ~= nil and api.nvim_buf_is_valid(entry.buffer) then
		pos = extmarks.get_extmark(entry.buffer, entry.extmark)
		if #pos == 0 then
			-- no extmark
			pos = { entry.line - 1, entry.col }
		end
		local cur_buf = api.nvim_win_get_buf(0)
		if cur_buf ~= entry.buffer then
			-- try to find a window with the same buffer as entry's buffer
			local wins = api.nvim_list_wins()
			for _, win in ipairs(wins) do
				if entry.buffer == api.nvim_win_get_buf(win) then
					-- use this win
					vim.fn.win_gotoid(win)
					window_to_use = win
					break
				end
			end
			if window_to_use == 0 then
				api.nvim_win_set_buf(0, entry.buffer)
			end
		end
	else
		pos = { entry.line - 1, entry.col }
		-- reload file into this window
		cmd(("edit %s"):format(entry.file))
	end
	if not pcall(api.nvim_win_set_cursor, window_to_use, { pos[1] + 1, pos[2] }) then
		log.error("could not set cursor position to", pos[1] + 1, pos[2], "file", entry.file)
	end
	vim.g.jumplist_keepjumps = false
end

function M.jump_prev()
	if M.current_jump > 0 then
		local new_current
		local entry = M.mk_entry()
		extmarks.sync_with_extmark(M.get_current_jump(), M.jumplist, nil)
		M.current_jump = M.clear_consequent_dups(M.current_jump, -1)
		if not u.eq(M.get_current_jump(), entry, scopes.enum.line) then
			-- jump to current_jump's position if we are out of it's line
			new_current = M.current_jump
		else
			new_current = math.max(M.current_jump - 1, 1)
		end
		local nearby = u.eq(M.get_current_jump(), entry, scopes.enum.nearby)
		-- allow BufLeave hook to mark position
		-- if we are leaving current buffer and not nearby current_jump
		vim.g.jumplist_keepjumps = nearby
		if c.config.mark_pos_on_jump and not nearby then
			-- if we are not "nearby" current_jump, mark
			entry.pop_stack = false
			M.mark(entry)
			-- no need to mark on BufLeave
			vim.g.jumplist_keepjumps = true
		end
		log.trace("jump_prev:", new_current, M.jumplist[new_current])
		M.jump(M.jumplist[new_current])
		M.current_jump = new_current
	end
end

function M.jump_next()
	if M.current_jump < #M.jumplist then
		M.current_jump = M.clear_consequent_dups(M.current_jump, 1)
		local new_current = M.current_jump + 1
		local entry = M.mk_entry()
		if c.config.mark_pos_on_jump and not u.eq(M.get_current_jump(), entry, scopes.enum.nearby) then
			entry.pop_stack = false
			M.mark(entry)
			new_current = new_current + 1
		end
		vim.g.jumplist_keepjumps = true
		log.trace("jump_next:", new_current, M.jumplist[new_current])
		M.jump(M.jumplist[new_current])
		M.current_jump = new_current
	end
end

local function jump_if_idx_in_another_file(idx, keepjumps)
	if M.jumplist[idx] and M.jumplist[idx].file ~= M.jumplist[M.current_jump].file then
		vim.g.jumplist_keepjumps = vim.F.if_nil(keepjumps, false)
		M.jump(M.jumplist[idx])
		M.current_jump = idx
		return true
	else
		return false
	end
end

function M.jump_prev_file()
	for i = M.current_jump, 1, -1 do
		if jump_if_idx_in_another_file(i, true) then
			break
		end
	end
end

function M.jump_next_file()
	for i = M.current_jump, #M.jumplist, 1 do
		if jump_if_idx_in_another_file(i, true) then
			break
		end
	end
end

---@return Jumplist.MarkOpts
function M.mk_entry()
	local cursor = api.nvim_win_get_cursor(0)
	return { file = api.nvim_buf_get_name(0), line = cursor[1], col = cursor[2] }
end

-- if previous/next jump is the same(due to text edits), skip it and remove from list
---@return number new_current index
---@nodiscard
function M.clear_consequent_dups(from_index, step)
	while u.eq(M.jumplist[from_index], M.jumplist[from_index + step], scopes.enum.cursor) do
		-- delete new_current
		log.trace("clear_consequent_dups: removing entry", from_index, "step", step)
		extmarks.remove_extmark(M.jumplist[from_index].buffer, M.jumplist[from_index].extmark)
		table.remove(M.jumplist, from_index)
		if step < 0 then
			from_index = from_index - 1
		end
	end
	return from_index
end

return M
