local filters = {}

local function filters_factor(fn)
  return function(opt)
    return fn(opt)
  end
end

---check diagnostic have the string
function filters.find_diagnostic_msg(patterns)
  vim.validate({
    patterns = { 'patterns', { 's', 't' } },
  })
  patterns = type(patterns) == 'string' and { patterns } or patterns

  local function check_diag(opt)
    local diagnostics = vim.diagnostic.get(opt.buf, { lnum = opt.lnum })
    for _, diag in pairs(diagnostics) do
      if diag.message then
        for _, pattern in pairs(patterns) do
          if diag.message:find(pattern) then
            return true
          end
        end
      end
    end
    return false
  end
  return filters_factor(check_diag)
end

local function find_space(opt)
  local before = vim.api.nvim_buf_get_text(opt.buf, opt.lnum, opt.col - 1, opt.lnum, opt.col, {})[1]
  if before == ' ' then
    return true
  end
  return false
end

function filters.non_space_before(opt)
  if not find_space(opt) then
    return true
  end
  return false
end

function filters.has_space_before(opt)
  return find_space(opt)
end

local function ts_query_and_node()
  local ok, _ = pcall(require, 'nvim-treesitter')
  if not ok then
    vim.notify('[mutchar.nvim] this filter need install treesitter')
    return
  end

  local ts_utils = require('nvim-treesitter.ts_utils')
  local current_node = ts_utils.get_node_at_cursor()
  if not current_node then
    return
  end

  local parent_node = current_node:parent()
  if not parent_node then
    parent_node = current_node
  end
  local queries = require('nvim-treesitter.query')
  local ft_to_lang = require('nvim-treesitter.parsers').ft_to_lang
  local query = queries.get_query(ft_to_lang('rust'), 'highlights')

  return parent_node, query
end

---@private
local function ts_captures_at_line(opt)
  local parent_node, query = ts_query_and_node()
  if not query then
    vim.notify('[mutchar.nvim] get treesitter query failed', vim.log.levels.ERROR)
    return
  end

  local types = {}
  for id, _, _ in query:iter_captures(parent_node, 0, opt.lnum, opt.lnum + 1) do
    local name = query.captures[id] -- name of the capture in the query
    -- local node_srow, _, node_erow, node_ecol = node:range()
    table.insert(types, name)
  end

  return types
end

---@private
local function equals_lnum_col(srow, erow, ecol, opt)
  ecol = ecol or nil
  if srow == opt.lnum and erow == opt.lnum then
    if not ecol then
      return true
    end
    if ecol == opt.col then
      return true
    else
      return false
    end
  end
  return false
end

---@private
local function tbl_filter(t1, t2)
  vim.validate({
    t1 = { t1, 't' },
    t2 = { t2, 't' },
  })
  local matched = false
  for _, need_match in pairs(t1) do
    for i, v in pairs(t2) do
      if need_match[i] == v then
        matched = true
      end
    end
    if matched then
      break
    end
  end

  return matched
end

local function ts_node_type_start()
  return {
    { 'keyword', 'type' },
    { 'keyword', 'variable' },
    { 'keyword.function', 'variable' },
  }
end

function filters.semicolon_in_lua(opt)
  local text = vim.api.nvim_get_current_line()
  if text:sub(#text - 4, #text) == 'self' then
    return true
  end
  return false
end

function filters.go_arrow_symbol(opt)
  local need_match = {
    'string',
    'operator',
    'variable',
    'function.macro',
  }
  local types = ts_captures_at_line(opt)
  if not types then
    return false
  end
  return tbl_filter({ need_match }, types)
end

function filters.generic_in_rust(opt)
  local parent_node, query = ts_query_and_node()
  if not query then
    return
  end

  local types = {}
  local match_start = ts_node_type_start()
  local function ts_match_generic()
    if #types == 2 and tbl_filter(match_start, types) then
      return true
    end
    return false
  end

  for id, node, _ in query:iter_captures(parent_node, 0, opt.lnum, opt.lnum + 1) do
    local name = query.captures[id] -- name of the capture in the query
    table.insert(types, name)
    local srow, _, erow, ecol = node:range()
    if equals_lnum_col(srow, erow, ecol, opt) and ts_match_generic() then
      return true
    end
  end
  return false
end

function filters.minus_in_rust(opt)
  local types = ts_captures_at_line(opt)
  if not types then
    return false
  end

  local tbl = ts_node_type_start()[3]

  if types[1] == tbl[1] and types[2] == tbl[2] and types[#types] == 'punctuation.delimiter' then
    return true
  end
  return false
end

function filters.semicolon_in_rust(opt)
  if find_space(opt) then
    return false
  end

  local parent_node, query = ts_query_and_node()
  if not query then
    return
  end

  for id, node, _ in query:iter_captures(parent_node, 0, opt.lnum, opt.lnum + 1) do
    local name = query.captures[id] -- name of the capture in the query
    local srow, _, erow, ecol = node:range()
    if equals_lnum_col(srow, erow, ecol, opt) and name == 'variable' then
      return true
    end
  end

  local text = vim.api.nvim_get_current_line()
  if opt.col == tonumber(vim.api.nvim_strwidth(text)) then
    return false
  end

  return true
end

function filters.generic_in_cpp(opt)
  local text = vim.api.nvim_get_current_line()
  if text == 'template' then
    return true
  end
  return false
end

return filters
