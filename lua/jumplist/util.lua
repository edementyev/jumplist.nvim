local M = {}

local log = require("jumplist.log")
local c = require("jumplist.config")
local scopes = require("jumplist.scopes")

---@param list table<number, any>
---@param start number delete from this index (inclusive)
---@param stop? number delete up to this index (exclusive)
---@param replacement? table<number, any> | nil
---@param in_place? boolean
---@param on_delete? fun(index: number, value: any)
function M.splice(list, start, stop, replacement, in_place, on_delete)
	if not vim.tbl_islist(list) then
		error("first argument must be list-like table")
	end
	local t
	if in_place then
		t = list
	else
		t = vim.tbl_deep_extend("force", {}, list)
	end
	local n = #t
	if start < 1 then
		start = n + start
	end
	stop = vim.F.if_nil(stop, start)
	if stop < 1 then
		stop = n + stop + 1
	end
	if start > stop then
		-- error(("start(%s) should be >= than stop(%s)"):format(start, stop))
    stop = start
	end
	if on_delete ~= nil then
		if type(on_delete) == "function" then
			for i = start, stop - 1, 1 do
				on_delete(i, t[i])
			end
		else
			error("on_delete must be function")
		end
	end
	if n ~= #t then
		error("on_delete must not mutate table length!")
	end
	local rlen = replacement ~= nil and #replacement or 0
	local delta = rlen - (stop - start)
	local newlen = n + delta
	if delta < 0 then
		for i = start + rlen, newlen do
			t[i] = t[i - delta]
		end
		for i = newlen + 1, n do
			t[i] = nil
		end
	elseif delta > 0 then
		for i = newlen, start + rlen, -1 do
			t[i] = t[i - delta]
		end
	end
	if replacement ~= nil then
		for i = 1, rlen do
			t[start + i - 1] = replacement[i]
		end
	end
	return t
end

function M.buf_valid(buf)
	local result
	if vim.tbl_contains(c.config.exclude_buftypes, vim.bo[buf].buftype) then
		result = false
	elseif vim.tbl_contains(c.config.exclude_filetypes, vim.bo[buf].filetype) then
		result = false
	else
		result = true
	end
	log.trace("buf_valid:", buf, result)
	return result
end

function M.buf_has_file(buf, file)
	log.trace("buf_has_file:", buf, file, vim.api.nvim_buf_get_name(buf) == file)
	return vim.api.nvim_buf_get_name(buf) == file
end

---@param first Jumplist.Entry
---@param second Jumplist.Entry
---@param scope Jumplist.Scope
function M.eq(first, second, scope)
	if first == nil or second == nil then
		return false
	end
	if scope == scopes.enum.global then
		return true
	elseif scope == scopes.enum.file then
		return first.file == second.file
	elseif scope == scopes.enum.nearby then
		return first.file == second.file and math.abs(first.line - second.line) <= c.config.scopes.nearby.lines
	elseif scope == scopes.enum.line then
		return first.file == second.file and first.line == second.line
	elseif scope == scopes.enum.cursor then
		return first.file == second.file and first.line == second.line and first.col == second.col
	else
		return false
	end
end

return M
