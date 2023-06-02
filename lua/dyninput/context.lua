local api = vim.api
local util = require('dyninput.util')
local ctx = {}

local function factory(fn)
  return function(opt)
    return fn(opt)
  end
end

---check diagnostic have the string
function ctx.diagnostic_match(patterns)
  patterns = type(patterns) == 'string' and { patterns } or patterns
  local function check_diag(opt)
    local diagnostics = vim.diagnostic.get(opt.buf, { lnum = opt.lnum - 1 })
    if next(diagnostics) == nil then
      return false
    end
    local it = vim.iter(diagnostics):find(function(item)
      return vim.iter(patterns):any(function(pattern)
        return item.message:find(pattern)
      end)
    end)
    return it and true or false
  end
  return factory(check_diag)
end

local function find_space(opt)
  local before = vim.api.nvim_buf_get_text(opt.buf, opt.lnum, opt.col - 1, opt.lnum, opt.col, {})[1]
  if before == ' ' then
    return true
  end
  return false
end

function ctx.non_space_before(opt)
  if not find_space(opt) then
    return true
  end
  return false
end

function ctx.has_space_before(opt)
  return find_space(opt)
end

function ctx.semicolon_in_lua(opt)
  local text = vim.api.nvim_get_current_line()
  if text:sub(#text - 3, #text) == 'self' then
    return true
  end
end

function ctx.rust_single_colon(opt)
  local line = api.nvim_get_current_line()
  if line:find('%s*use$%s*') then
    return false
  end
  local curnode = util.ts_cursor_node(opt)
  local parent = util.ts_parent_node_type(opt)
  if
    (parent == 'let_declaration' and curnode and curnode:type() == 'identifier')
    or parent == 'parameters'
  then
    return true
  end
  local scope = util.ts_blank_node_parent(opt.buf)
  if scope == 'struct_item' or scope == 'struct_expression' then
    return true
  end
end

function ctx.rust_double_colon(opt)
  local line = api.nvim_buf_get_text(opt.buf, opt.lnum - 1, 0, opt.lnum - 1, opt.col, {})[1]
  local part = vim.split(line, '%s')
  local word = part[#part]

  local list = { 'Option', 'String', 'std', 'super', 'Vec' }
  for _, item in ipairs(list) do
    if word == item or word:sub(#word - #item + 1, #word) == item then
      return true
    end
  end

  if util.ts_parent_node_type(opt) == 'generic_function' then
    return true
  end

  local type = { 'enum', 'namespace', 'type' }
  --match module/enum
  if util.ts_hl_match(type, word, opt) then
    return true
  end
end

function ctx.rust_thin_arrow()
  local line = api.nvim_get_current_line()
  if line:find('^%s*[pub%s*]*fn') then
    return true
  end
end

function ctx.rust_closure(opt)
  local curnode = util.ts_cursor_node(opt)
  if curnode and curnode:type() == 'arguments' then
    return true
  end
end

function ctx.rust_fat_arrow(opt)
  local type = util.ts_blank_node_parent(opt.buf)
  if type ~= 'match_block' and type ~= 'match_expression' and type ~= 'ERROR' then
    return
  end
  return true
end

function ctx.generic_in_cpp()
  local text = api.nvim_get_current_line()
  if text == 'template' then
    return true
  end
  return false
end

return ctx
