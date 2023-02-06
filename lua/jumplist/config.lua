local M = {}

local log = require("jumplist.log")

---@alias Mode "all" | "normal" | "visual"

---@class Jumplist.Config
M.default_config = {
	exclude_buftypes = { "terminal", "quickfix", "nofile", "prompt" },
	exclude_filetypes = { "NvimTree", "packer", "aerial", "", "fugitive", "harpoon-menu" },
	filename_valid = function(filename)
		local result
		if filename == "" then
			result = false
		elseif vim.loop.fs_realpath(filename) == nil then
			result = false
		else
			result = true
		end
		log.trace("filename_valid:", filename, result)
		return result
	end,
	max_entries = 200,
	scopes = {
		nearby = {
			lines = 7,
		},
	},
	mark_pos_on_jump = true,
	default_pop_stack = true,
	event_hooks = true,
	use_debounce = false,
	---@type table<string, table<Mode, boolean | function>>
	remaps = {
		all = {
			gg = true,
			G = true,
			["m'"] = true,
			["m`"] = true,
			n = true,
			N = true,
			["*"] = true,
			["#"] = true,
		},
	},
	-- TODO: remaps: K in help files
}

---@type Jumplist.Config
M.config = {}

return M
