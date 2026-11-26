local gitsigns = require("gitsigns")

vim.api.nvim_create_user_command("AtlzGitDiff", function()
  local diff_windows = {}

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf)

    if vim.wo[win].diff and name:match("^gitsigns://") then
      table.insert(diff_windows, win)
    end
  end

  if #diff_windows > 0 then
    for _, win in ipairs(diff_windows) do
      vim.api.nvim_win_close(win, false)
    end

    vim.cmd("diffoff!")
    return
  end

  gitsigns.diffthis()
end, {
  desc = "Переключить Git diff",
})


