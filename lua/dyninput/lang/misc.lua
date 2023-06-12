local api = vim.api
local util = require('dyninput.util')
local ms = {}

function ms.c_struct_pointer(opt)
  local curtype = util.ts_cursor_type(opt)

  if curtype and curtype ~= 'string_literal' and not util.has_space_before(opt) then
    return true
  end
  return false
end

function ms.semicolon_in_lua(opt)
  local curnode = util.ts_cursor_node(opt)
  if not curnode then
    return
  end
  local word = util.ts_cursor_word(opt)
  if word == 'self' or curnode:type() == 'identifier' then
    return true
  end
end

function ms.generic_in_cpp()
  local text = api.nvim_get_current_line()
  if text == 'template' then
    return true
  end
  return false
end

function ms.go_variable_define(opt)
  local curnode = util.ts_cursor_node(opt)
  if not curnode then
    return
  end
  local parent = util.ts_parent_node_type(opt)
  if curnode:type() == 'identifier' and (parent == 'block' or parent == 'ERROR') then
    return true
  end
end

function ms.go_struct_field(opt)
  local parent = util.ts_parent_node_type(opt)
  if parent and parent == 'literal_element' then
    return true
  end
end

function ms.snake_case(opt)
  local curtype = util.ts_cursor_type(opt)
  if curtype and (curtype == 'string_literal' or curtype == 'string_content') then
    return false
  end
  return util.snake_case(opt)
end

return ms
