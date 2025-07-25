local fs = require("cshelper.fs")

local M = {}

local exclude_dirs = { "obj", "bin", ".git" }

function M.get_projects(include_solution)
  local valid_ext = { "csproj" }
  if include_solution then
    table.insert(valid_ext, "sln")
  end
  return M.get_file_options(fs.cwd(), valid_ext)
end

function M.get_namespace_for_file(file_path)
  local elements = {}
  local csproj_path
  local curr_path = file_path
  local max_level = 5
  for _ = 1, max_level do
    curr_path = fs.get_parent_path(curr_path)

    for _, file in ipairs(fs.get_files(curr_path)) do
      if fs.get_ext(file:lower()) == "csproj" then
        csproj_path = file
        break
      end
    end

    if csproj_path then
      break
    end

    -- insert dir name as element of namespace
    table.insert(elements, 1, fs.get_file_name(curr_path))

    -- do not go above pwd
    if curr_path == vim.fn.getcwd() then
      break
    end
  end
  if csproj_path then
    local root_namespace = M.get_root_namespace(csproj_path)
    if root_namespace then
      table.insert(elements, 1, root_namespace)
    end
  end
  local namespace
  if vim.tbl_count(elements) > 0 then
    namespace = table.concat(elements, ".")
  end
  return namespace
end

function M.get_root_namespace(path)
  local namespace
  for line in io.lines(path) do
    namespace = string.match(line, "<RootNamespace>([^<>]+)</RootNamespace>")
    if namespace then
      break
    end
  end
  if not namespace then
    namespace = fs.get_file_name_without_ext(path)
  end
  return namespace
end

---Get list of valid project dirs for fzf
function M.get_dir_options(path)
  local result = { path }
  for _, dir_path in ipairs(fs.get_dirs(path)) do
    if not vim.tbl_contains(exclude_dirs, fs.get_file_name(dir_path)) then
      for _, subdir in ipairs(M.get_dir_options(dir_path)) do
        table.insert(result, subdir)
      end
    end
  end
  return result
end

---Get list of valid project files in path
function M.get_file_options(path, valid_ext)
  valid_ext = valid_ext or {}
  local result = {}
  local files = fs.get_files(path)
  for _, file in ipairs(files) do
    local ext = fs.get_ext(file:lower())
    if vim.tbl_isempty(valid_ext) or vim.tbl_contains(valid_ext, ext) then
      table.insert(result, file)
    end
  end
  for _, dir_path in ipairs(fs.get_dirs(path)) do
    if not vim.tbl_contains(exclude_dirs, fs.get_file_name(dir_path)) then
      for _, subresult in ipairs(M.get_file_options(dir_path, valid_ext)) do
        table.insert(result, subresult)
      end
    end
  end
  return result
end

function M.get_valid_buffers()
  local result = {}
  for _, no in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(no) then
      table.insert(result, { no = no, name = vim.api.nvim_buf_get_name(no) })
    end
  end
  return result
end

function M.get_valid_buffers_in_dir(dir)
  return vim.tbl_filter(function(x)
    return vim.startswith(x.name, fs.abs_path(dir))
  end, M.get_valid_buffers())
end

function M.read(no)
  return vim.api.nvim_buf_get_lines(no, 0, -1, false)
end

function M.open_and_replace_lines(filepath, lines)
  vim.cmd("edit " .. vim.fn.fnameescape(filepath))
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

function M.replace_lines(no, lines)
  vim.api.nvim_buf_set_lines(no, 0, -1, false, lines)
end

function M.get_cur_row()
  return vim.api.nvim_win_get_cursor(0)[1]
end

function M.get_cur_col()
  return vim.api.nvim_win_get_cursor(0)[2] + 1
end

function M.set_col(col)
  vim.api.nvim_win_set_cursor(0, { M.get_cur_row(), col - 1 })
end

function M.set_pos(row, col)
  vim.api.nvim_win_set_cursor(0, { row, col - 1 })
end

return M
