-- describe(modes, lhs, desc): gives a key a plugin bound without a desc one, so it shows in the keys picker
-- (;?), and changes nothing else about it: the mapping is copied with the desc added. For keys a plugin binds
-- with logic of its own (vim-tmux-navigator's fzf check in terminal mode) that rebinding here would copy.
return function(modes, lhs, desc)
  for _, mode in ipairs(type(modes) == 'table' and modes or { modes }) do
    local map = vim.fn.maparg(lhs, mode, false, true)
    if map.lhs then
      map.desc = desc
      vim.fn.mapset(mode, false, map)
    end
  end
end
