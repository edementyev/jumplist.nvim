---@type Jumplist.Config
local config = require("jumplist.config").config

local feedkeys = function(keys, mode)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, true, true), mode, false)
end
local map = vim.keymap.set
local jump = require("jumplist.jump")

local mode_map = {
	all = "",
	normal = "n",
	visual = "v",
}

if config.remaps then
	if type(config.remaps) == "table" then
		for mode, tbl in pairs(config.remaps) do
			for command, value in pairs(tbl) do
				if value ~= nil and value ~= false then
					map(mode_map[mode], command, function()
						jump.mark()
						-- vim.cmd("normal! " .. key)
            feedkeys(command, "ni")
					end, { noremap = true, silent = true, desc = "jumplist: " .. command })
				end
			end
		end
	end
end
