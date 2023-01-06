local api, keymap = vim.api, vim.keymap
local cs = {}

function cs:match_rule(buf, rule, filters)
  local lnum, col = unpack(api.nvim_win_get_cursor(0))
  local matched_idx, start_col
  for i, v in pairs(rule) do
    if col - #v > 0 then
      local res = api.nvim_buf_get_text(buf, lnum - 1, col - #v, lnum - 1, col, {})
      if vim.tbl_contains(rule, res[1]) then
        matched_idx = i
        start_col = col - #v
        break
      end
    end
  end

  local mut = #filters == 0 and true or false
  for _, fn in pairs(filters) do
    if fn({ buf = buf, lnum = lnum - 1, col = col }) then
      mut = true
    end
  end

  if not mut then
    matched_idx = 1
  else
    matched_idx = not matched_idx and 2 or matched_idx + 1
    if matched_idx == #rule + 1 then
      matched_idx = 1
    end
  end

  if not start_col then
    start_col = col
  end

  local mut_char = rule[matched_idx]
  local spos, epos = mut_char:find('!')
  local adjust = 0
  if spos and epos then
    mut_char = mut_char:gsub('!', '')
    adjust = -1
  end

  api.nvim_buf_set_text(buf, lnum - 1, start_col, lnum - 1, col, { mut_char })
  api.nvim_win_set_cursor(0, { lnum, col + #mut_char + adjust })
end

function cs:load_filetype_event(ft, ft_conf)
  local create_event = function(rule)
    api.nvim_create_autocmd('FileType', {
      group = api.nvim_create_augroup('MutChar', { clear = false }),
      pattern = ft,
      callback = function(opt)
        keymap.set('i', rule[1], function()
          local filters = {}
          if ft_conf.filter then
            vim.validate({
              filter = { ft_conf.filter, { 'f', 't' } },
            })
            filters = type(ft_conf.filter) == 'table' and ft_conf.filter or { ft_conf.filter }
            if ft_conf.one_to_one then
              local index = 0
              for i, v in pairs(ft_conf.rules) do
                if v[1] == rule[1] then
                  index = i
                  break
                end
              end

              if ft_conf.filter[index] then
                filters = type(ft_conf.filter[index]) ~= 'table' and { ft_conf.filter[index] }
                  or ft_conf.filter[index]
              end
            end
          end
          self:match_rule(opt.buf, rule, filters)
        end, { silent = true, nowait = true, buffer = true })
      end,
    })
  end

  if not vim.tbl_islist(ft_conf.rules[1]) then
    create_event(ft_conf.rules)
    return
  end

  for _, v in pairs(ft_conf.rules) do
    create_event(v)
  end
end

---@private
local function validate(config)
  for ft, conf in pairs(config) do
    if not conf.rules then
      vim.notify('charshape.nvim please config the rules of ' .. ft, vim.log.levels.ERROR)
      return false
    end
  end
  return true
end

---@private
local function extend_config(config)
  cs.config = config
  for _, conf in pairs(cs.config) do
    if not conf.one_to_one then
      conf.one_to_one = false
    end
  end
end

function cs.setup(config)
  if not validate(config) then
    return
  end
  for k, v in pairs(config) do
    cs:load_filetype_event(k, v)
  end
  extend_config(config)
end

return cs
