local M = {}

local api = vim.api
local autocmd = api.nvim_create_autocmd
local augroup = api.nvim_create_augroup

local u = require("jumplist.util")
local log = require("jumplist.log")
local extmarks = require("jumplist.extmarks")
local persist = require("jumplist.persist")
local c = require("jumplist.config")
local jump = require("jumplist.jump")

local aug_id = augroup("jumplist", {})

function M.setup_jump_hooks()
	-- NOTE: mark on BufEnter may be useful in some cases
	-- e.g. when entering help files
	autocmd("BufLeave", {
		group = aug_id,
		callback = function(opts)
			-- record jumps after VimEnter
			if vim.v.vim_did_enter and u.buf_valid(opts.buf) then
				-- FIXME: deduplication of gd, cnext jumps
				jump.mark({ debounce = c.config.use_debounce, direction = 1 })
			end
		end,
	})
end

function M.setup_autocmds()
	autocmd("VimEnter", {
		group = aug_id,
		callback = function()
			-- workspaces = M.read_workspaces()
			jump.init(persist.read(vim.fn.getcwd(-1, -1)))
			log.trace(jump.jumplist)
			for _, buf in ipairs(api.nvim_list_bufs()) do
				extmarks.load_buf_extmarks(api.nvim_buf_get_name(buf), buf, jump.jumplist)
			end
		end,
	})
	autocmd("VimLeavePre", {
		group = aug_id,
		callback = function()
			-- TODO: incremental sync - write when list is changed
			-- use different format (jump entry = line)
			persist.save(vim.fn.getcwd(-1, -1))
		end,
	})
	autocmd("BufDelete", {
		group = aug_id,
		callback = function(opts)
			-- TODO: store extmark info on BufDelete
			-- this may require mapping buffers to their extmarks
			-- so that we don't iterate whole jumplist every time
			--
			-- for _, entry in ipairs(J.jumplist) do
			--   if api.nvim_buf_is_valid(entry.buffer) then
			--     M.sync_with_extmark(entry, opts)
			--   end
			-- end
		end,
	})
end

function M.setup(opts)
	c.config = vim.tbl_deep_extend("force", c.config, c.default_config, opts or {})
	-- make cache dir
	persist.init()
	-- create extmarks when buffer is loaded
	M.setup_autocmds()
	if c.config.event_hooks then
		M.setup_jump_hooks()
	end
end

return M
