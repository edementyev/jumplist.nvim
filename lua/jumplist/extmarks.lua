local M = {}

local api = vim.api
-- local cmd = vim.cmd
local log = require("jumplist.log")
local u = require("jumplist.util")
local c = require("jumplist.config")

local ns_id = api.nvim_create_namespace("jumplist_extmarks")

local extmarks_loaded = {}
local filename_loaded = {}

---@param file string
---@param buf? number
---@param jumplist Jumplist.List
function M.load_buf_extmarks(file, buf, jumplist)
	log.trace("load_buf_extmarks: buf", buf, "file", file)
	if
		file == nil
		or not c.config.filename_valid(file)
		-- or not u.buf_valid(buf)
		or (buf ~= nil and not u.buf_has_file(buf, file))
	then
		log.trace("load_buf_extmarks: file/buf is not valid, nothing to load", buf, file)
		return
	end
	if filename_loaded[file] ~= nil then
		return
	end
	if buf == nil then
		-- get buf
		if api.nvim_buf_get_name(api.nvim_win_get_buf(0)) == file then
			buf = api.nvim_win_get_buf(0)
		else
			-- buffer should be loaded
			for _, b in ipairs(api.nvim_list_bufs()) do
				if api.nvim_buf_get_name(b) == file then
					buf = b
					break
				end
			end
		end
	end
	if buf == nil then
		log.trace(("load_buf_extmarks: buf not found/is not loaded for file %s"):format(file))
		return
	end
	for i, entry in ipairs(jumplist) do
		if not extmarks_loaded[entry.file .. ":" .. entry.extmark] and entry.file == file then
			log.trace("load_buf_extmarks: loading extmark for entry", i)
			-- loop over jumplist and create extmarks for current file
			entry.extmark = M.set_extmark(buf, entry.line, entry.col)
			entry.buffer = buf
			extmarks_loaded[entry.file .. ":" .. entry.extmark] = true
		end
	end
	filename_loaded[file] = true
end

---@param buffer number
---@param line number 1-based
---@param col number 0-based
function M.set_extmark(buffer, line, col)
	return api.nvim_buf_set_extmark(buffer, ns_id, line - 1, col, { right_gravity = true, strict = false })
end

---@param opts? table params for nvim_buf_get_extmark_by_id call
function M.get_extmark(buf, id, opts)
	local pos = {}
	if buf ~= nil then
		pos = api.nvim_buf_get_extmark_by_id(buf, ns_id, id, opts or {})
	end
	if #pos > 0 then
		api.nvim_buf_call(buf, function()
			-- fix extmark line being over last line
			local last_line = vim.fn.line("$")
			if pos[1] == last_line then
				pos[1] = pos[1] - 1
			end
		end)
	else
		log.trace(
			"get_extmark: extmark not found for buffer",
			buf,
			"id",
			id,
			"filename",
			buf ~= nil and api.nvim_buf_get_name(buf) or nil
		)
	end
	return pos
end

function M.remove_extmark(buffer, id)
	if buffer == nil then
		return
	end
	if not pcall(api.nvim_buf_del_extmark, buffer, ns_id, id) then
		log.trace("remove_extmark: could not remove extmark", id, "buffer", buffer)
	end
end

-- get entry's extmark and update line/col
---@param entry Jumplist.Entry
---@param jumplist Jumplist.List
---@param get_extmark_opts? table
-- TODO: auto sync with extmarks on index access
function M.sync_with_extmark(entry, jumplist, get_extmark_opts)
	---@type Jumplist.ExtmarkOpts
	if not filename_loaded[entry.file] then
		M.load_buf_extmarks(entry.file, nil, jumplist)
	end
	local pos = M.get_extmark(entry.buffer, entry.extmark, get_extmark_opts)
	if #pos > 0 then
		entry.line, entry.col = unpack(pos)
		-- 0-based to 1-based
		entry.line = entry.line + 1
		log.trace("sync_with_extmark: new pos", entry.line, entry.col)
	end
end

return M
