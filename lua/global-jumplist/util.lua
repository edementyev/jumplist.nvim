M = {}

---@param list table<number, any>
---@param start number
---@param stop number
---@param replacement? table<number, any>
---@param in_place? boolean
function M.splice(list, start, stop, replacement, in_place)
	if not vim.tbl_islist(list) then
		error("first argument must be list-like table")
		return
	end
	local t
	if in_place then
		t = list
	else
		t = vim.tbl_deep_extend("force", {}, list)
	end
	local n = #t
	if start < 0 then
		start = n + start + 1
	end
	if stop < 0 then
		stop = n + stop + 1
	end
	local rlen = replacement ~= nil and #replacement or 0
	local delta = rlen - stop + start - 1
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
	if rlen > 0 then
		for i = 1, rlen do
			---@diagnostic disable-next-line: need-check-nil
			t[start + i - 1] = replacement[i]
		end
	end
	return t
end

return M
