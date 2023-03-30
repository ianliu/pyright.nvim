local Path = require("plenary.path")
local Job = require("plenary.job")

local _M = {
  telescope = {}
}

local function make_python_args(args)
  local a = vim.deepcopy(args or {})
  a[#a + 1] = "-c"
  a[#a + 1] = "import sys;sys.stdout.write(sys.executable)"
  return a
end

local function local_python_path()
  local res, ret = Job:new({
    command = "python",
    args = make_python_args(),
  }):sync()
  if ret ~= 0 then
    return {}
  else
    return res
  end
end

local function tool_python_path(tool, lock_name, root_dir)
  if lock_name then
    local lock = Path:new(root_dir) / lock_name
    if not lock:exists() then
      return {}
    end
  end
  local res, retcode = Job:new({
    cwd = root_dir,
    command = tool,
    args = make_python_args({ "run", "python" }),
  }):sync()
  if retcode ~= 0 then
    return {}
  else
    return res
  end
end

local function find_environments()
  local function exists(path)
    return Path:new(path):exists()
  end
  return vim.tbl_filter(
    exists,
    vim.tbl_flatten({
      tool_python_path("pdm", "pdm.lock", "."),
      tool_python_path("pipenv", "Pipenv.lock", "."),
      tool_python_path("poetry", "poetry.lock", "."),
      { "./.venv/bin/python", "./venv/bin/python" },
      local_python_path(),
    }))
end

function _M.pyright_set_python_path(path)
  local clients = vim.lsp.get_active_clients {
    bufnr = vim.api.nvim_get_current_buf(),
    name = 'pyright',
  }
  for _, client in ipairs(clients) do
    client.config.settings = vim.tbl_deep_extend('force', client.config.settings, { python = { pythonPath = path } })
    client.notify('workspace/didChangeConfiguration', { settings = nil })
  end
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

function _M.telescope.python_envs(opts)
  opts = opts or require("telescope.themes").get_dropdown({})
  pickers.new(opts, {
    prompt_title = "Python Environments",
    finder = finders.new_table { results = find_environments() },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        _M.pyright_set_python_path(selection[1])
      end)
      return true
    end
  }):find()
end

return _M
