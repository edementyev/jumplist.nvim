local M = {}

local api = vim.api

local extmarks = require("jumplist.extmarks")
local jump = require("jumplist.jump")

local Path = require("plenary.path")

local cache_path = string.format("%s/jumplist.nvim", vim.fn.stdpath("cache"))
local workspaces_path = Path:new(cache_path .. "/workspaces.json")
local workspaces = {}
local cached_list_path_template = cache_path .. "/%s.json"

-- local function get_cache_path(cwd)
-- 	local filename = workspaces[cwd]
-- 	if filename == nil then
-- 		filename = vim.tbl_count(workspaces) + 1
-- 		workspaces[cwd] = filename
-- 		M.save_workspaces()
-- 	end
-- 	return cached_list_path_template:format(filename)
-- end

local function get_cache_path(cwd)
	return cached_list_path_template:format(cwd:gsub("/", "%%"))
end

function M.init()
	Path:new(cache_path):mkdir()
end

---@param cwd string
function M.read(cwd)
	local path = Path:new(get_cache_path(cwd))
	if not path:exists() then
		path:write("{}", "w")
	end
  ---@type Jumplist.Json | nil
  local j = vim.json.decode(path:read()) or {}
	if j == nil or j.jumplist == nil then
		return nil
  else
    return j
	end
end

function M.read_workspaces()
	if not workspaces_path:exists() then
		workspaces_path:write("{}", "w")
	end
	return vim.json.decode(workspaces_path:read()) or {}
end

---@param cwd string
function M.save(cwd)
	-- serialize extmarks
	-- do not allocate new object upon each call :)
	local opts = {}
	for _, entry in ipairs(jump.jumplist) do
		if entry.buffer ~= nil and api.nvim_buf_is_valid(entry.buffer) then
			extmarks.sync_with_extmark(entry, opts)
		end
    -- DO NOT STORE BUFFER NUMBERS
    entry.buffer = nil
	end
	Path:new(get_cache_path(cwd)):write(vim.fn.json_encode(jump.get_json()), "w")
end

function M.save_workspaces()
	local upd_ws = M.read_workspaces()
	workspaces_path:write(vim.fn.json_encode(vim.tbl_deep_extend("force", upd_ws, workspaces)), "w")
end

return M
