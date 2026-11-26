local M = {}
local api = vim.api
local left_bar = "%!v:lua.require'workspace'.sidebar_bar()"
local right_bar = "%!v:lua.require'workspace'.file_bar()"

local function state(tab)
  return vim.t[tab].workspace or {}
end

local function is_file(buf)
  return vim.bo[buf].buftype == "" and vim.bo[buf].buflisted
end

local function file_buffers()
  return vim.tbl_filter(is_file, api.nvim_list_bufs())
end

local function is_editor(win, tab)
  return win
    and api.nvim_win_is_valid(win)
    and api.nvim_win_get_tabpage(win) == tab
    and api.nvim_win_get_config(win).relative == ""
    and is_file(api.nvim_win_get_buf(win))
end

local function is_git(win)
  return win
    and api.nvim_win_is_valid(win)
    and vim.bo[api.nvim_win_get_buf(win)].filetype == "NeogitStatus"
end

local function editor(tab)
  local current = api.nvim_get_current_win()
  if is_editor(current, tab) then
    return current
  end
  local previous = state(tab).editor
  if is_editor(previous, tab) then
    return previous
  end
  for _, win in ipairs(api.nvim_tabpage_list_wins(tab)) do
    if is_editor(win, tab) then
      return win
    end
  end
end

local function sidebar(tab, tree)
  local win = tree.winid({ tabpage = tab })
  if win and tree.is_tree_buf(api.nvim_win_get_buf(win)) then
    return win, "explorer"
  end
  win = state(tab).git
  if is_git(win) then
    return win, "git"
  end
end

local function tab_label(callback, id, label, active)
  local highlight = active and "TabLineSel" or "TabLine"
  return ("%s%%%d@v:lua.require'workspace'.%s@%s%%T"):format(
    "%#" .. highlight .. "#",
    id,
    callback,
    label:gsub("%%", "%%%%")
  )
end

function M.sidebar_bar()
  local win = vim.g.statusline_winid
  local git = is_git(win)
  local explorer_label = api.nvim_win_get_width(win) >= 15 and " Explorer " or " E "
  return tab_label("click_sidebar", 1, explorer_label, not git)
    .. tab_label("click_sidebar", 2, " Git ", git)
    .. "%#TabLineFill#"
end

local function open_slot(width, enter)
  local buf = api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  local win = api.nvim_open_win(buf, enter, { split = "left", win = -1 })
  api.nvim_win_set_width(win, width)
  return win
end

local function open_explorer(tree, width)
  if width then
    tree.open({ winid = open_slot(width, false) })
  else
    tree.open()
  end
  return tree.winid()
end

local function save_views(tab, left)
  local views = {}
  for _, win in ipairs(api.nvim_tabpage_list_wins(tab)) do
    if win ~= left and api.nvim_win_get_config(win).relative == "" then
      views[win] = api.nvim_win_call(win, vim.fn.winsaveview)
    end
  end
  return views
end

local function show_sidebar(mode)
  local tab = api.nvim_get_current_tabpage()
  local tree = require("nvim-tree.api").tree
  local left, active = sidebar(tab, tree)
  if active == mode then
    api.nvim_set_current_win(left)
    vim.wo[left].winbar = left_bar
    return
  end

  local right = editor(tab)
  if not right then
    return
  end

  local cwd
  if mode == "git" then
    cwd = api.nvim_win_call(right, vim.fn.getcwd)
    local started, git = pcall(
      vim.system,
      { "git", "-C", cwd, "rev-parse", "--is-inside-work-tree" },
      { text = true }
    )
    if not started then
      vim.notify(tostring(git), vim.log.levels.WARN)
      return
    end
    local result = git:wait()
    if result.code ~= 0 or vim.trim(result.stdout) ~= "true" then
      vim.notify(
        "Git-статус недоступен вне рабочего дерева Git",
        vim.log.levels.INFO
      )
      return
    end

    -- Neogit uses one named status buffer, so opening it can reuse another window.
    for _, win in ipairs(api.nvim_list_wins()) do
      if is_git(win) then
        vim.notify("Neogit уже открыт в другом окне", vim.log.levels.INFO)
        return
      end
    end
  end

  local workspace = state(tab)
  workspace.editor = right
  workspace.width = left and api.nvim_win_get_width(left) or workspace.width
  local views = save_views(tab, left)
  local restore_sizes = left and vim.fn.winrestcmd()
  local equalalways = vim.o.equalalways
  vim.o.equalalways = false
  local ok, err = pcall(function()
    api.nvim_set_current_win(right)
    if active == "explorer" then
      tree.close_in_this_tab()
    elseif left then
      api.nvim_win_close(left, false)
    end

    if mode == "git" then
      local slot = open_slot(workspace.width or 30, true)
      local opened, failure = pcall(require("neogit").open, { kind = "replace", cwd = cwd })
      if opened and is_git(slot) then
        left = slot
        workspace.git = slot
      else
        if api.nvim_win_is_valid(slot) then
          api.nvim_win_close(slot, false)
        end
        api.nvim_set_current_win(right)
        left = open_explorer(tree, workspace.width)
        vim.notify(
          tostring(failure or "Neogit не открыл боковую панель"),
          vim.log.levels.WARN
        )
      end
    else
      workspace.git = nil
      left = open_explorer(tree, workspace.width)
    end
  end)
  if ok and left then
    vim.wo[left].winfixwidth = true
    vim.wo[left].winbar = left_bar
  end
  vim.o.equalalways = equalalways
  if ok and restore_sizes then
    ok, err = pcall(vim.cmd, restore_sizes)
  end
  vim.t[tab].workspace = workspace

  for win, view in pairs(views) do
    if api.nvim_win_is_valid(win) then
      api.nvim_win_call(win, function()
        if not vim.deep_equal(vim.fn.winsaveview(), view) then
          vim.fn.winrestview(view)
        end
      end)
    end
  end
  if not ok then
    vim.notify(tostring(err), vim.log.levels.ERROR)
  end
end

function M.click_sidebar(id, _, button)
  if button ~= "l" then
    return
  end
  local win = vim.fn.getmousepos().winid
  local tab = api.nvim_get_current_tabpage()
  vim.schedule(function()
    if api.nvim_get_current_tabpage() == tab and api.nvim_win_is_valid(win) then
      show_sidebar(id == 1 and "explorer" or "git")
    end
  end)
end

function M.focus_explorer()
  show_sidebar("explorer")
end

function M.focus_editor()
  local win = editor(api.nvim_get_current_tabpage())
  if win then
    api.nvim_set_current_win(win)
  end
end

function M.file_bar()
  local win = vim.g.statusline_winid
  local current = api.nvim_win_get_buf(win)
  local tabs, counts = {}, {}
  for _, buf in ipairs(file_buffers()) do
    local path = api.nvim_buf_get_name(buf)
    local name = path == "" and "[Без имени]" or vim.fs.basename(path)
    tabs[#tabs + 1] = { buf = buf, path = path, name = name }
    counts[name] = (counts[name] or 0) + 1
  end

  local labels, available = {}, api.nvim_win_get_width(win)
  local first, active = 1, 0
  for index, tab in ipairs(tabs) do
    if counts[tab.name] > 1 then
      tab.name = tab.path == "" and (tab.name .. " " .. tab.buf)
        or vim.fn.fnamemodify(tab.path, ":~:.")
    end
    tab.name = vim.fn.strtrans(tab.name)
    tab.suffix = vim.bo[tab.buf].modified and " [+] " or " "
    tab.width = vim.fn.strdisplaywidth(tab.name) + #tab.suffix + 1
    if tab.buf == current then
      active = index
    end
  end
  local through_active = 0
  for index = 1, active do
    through_active = through_active + tabs[index].width
  end
  while through_active > available and first < active do
    through_active = through_active - tabs[first].width
    first = first + 1
  end
  for index = first, #tabs do
    local tab = tabs[index]
    if tab.width > available then
      if index == active then
        local size = math.max(0, available - #tab.suffix - 2)
        local name = vim.fn.strcharpart(tab.name, 0, size)
        while vim.fn.strdisplaywidth(name) > size do
          size = size - 1
          name = vim.fn.strcharpart(tab.name, 0, size)
        end
        labels[#labels + 1] =
          tab_label("click_file", tab.buf, " " .. name .. "…" .. tab.suffix, true)
      elseif available > 0 then
        labels[#labels + 1] = "%#TabLineFill#…"
      end
      break
    end
    local label = " " .. tab.name .. tab.suffix
    labels[#labels + 1] = tab_label("click_file", tab.buf, label, tab.buf == current)
    available = available - tab.width
  end
  return table.concat(labels) .. "%#TabLineFill#"
end

local function select_buffer(buf)
  vim.cmd.buffer({ args = { tostring(buf) }, mods = { hide = true } })
end

function M.click_file(buf, _, button)
  if button ~= "l" then
    return
  end
  local win = vim.fn.getmousepos().winid
  local tab = api.nvim_get_current_tabpage()
  vim.schedule(function()
    if is_editor(win, tab) and api.nvim_buf_is_valid(buf) and is_file(buf) then
      api.nvim_set_current_win(win)
      select_buffer(buf)
    end
  end)
end

local function update_bar(win)
  local tab = api.nvim_win_get_tabpage(win)
  if is_editor(win, tab) then
    local workspace = state(tab)
    workspace.editor = win
    vim.t[tab].workspace = workspace
    if vim.wo[win].winbar == "" then
      vim.wo[win].winbar = right_bar
    end
  elseif vim.wo[win].winbar == right_bar then
    vim.wo[win].winbar = ""
  end
end

function M.cycle_tab(forward)
  local tab = api.nvim_get_current_tabpage()
  local win = api.nvim_get_current_win()
  local left, active = sidebar(tab, require("nvim-tree.api").tree)
  if win == left then
    show_sidebar(active == "explorer" and "git" or "explorer")
  elseif is_editor(win, tab) then
    local buffers = file_buffers()
    if #buffers > 1 then
      local index = vim.fn.index(buffers, api.nvim_win_get_buf(win))
      local step = forward and 1 or -1
      select_buffer(buffers[(index + step) % #buffers + 1])
    end
  end
end

local sidebar_tabs = { "explorer", "git" }

function M.select_tab(index)
  local tab = api.nvim_get_current_tabpage()
  local win = api.nvim_get_current_win()
  if win == sidebar(tab, require("nvim-tree.api").tree) then
    local mode = sidebar_tabs[index]
    if mode then
      show_sidebar(mode)
    end
  elseif is_editor(win, tab) then
    local buf = file_buffers()[index]
    if buf and buf ~= api.nvim_win_get_buf(win) then
      select_buffer(buf)
    end
  end
end

function M.close_tab(force)
  if not is_editor(api.nvim_get_current_win(), api.nvim_get_current_tabpage()) then
    vim.notify(
      "Выберите файловую вкладку в редакторе",
      vim.log.levels.INFO
    )
    return
  end
  local buf = api.nvim_get_current_buf()
  if vim.bo[buf].modified and not force then
    vim.notify(
      "Сохраните изменения перед закрытием вкладки",
      vim.log.levels.WARN
    )
    return
  end

  local windows = vim.fn.win_findbuf(buf)
  for _, win in ipairs(windows) do
    if vim.wo[win].winfixbuf then
      vim.notify("Буфер закреплён в окне (winfixbuf)", vim.log.levels.WARN)
      return
    end
  end

  local replacement = vim.fn.bufnr("#")
  if replacement == buf or not api.nvim_buf_is_valid(replacement) or not is_file(replacement) then
    replacement = vim.iter(api.nvim_list_bufs()):find(function(candidate)
      return candidate ~= buf and is_file(candidate)
    end) or api.nvim_create_buf(true, false)
  end

  -- Detach the buffer from its windows before :bdelete can close them.
  for _, win in ipairs(windows) do
    api.nvim_win_call(win, function()
      select_buffer(replacement)
    end)
  end
  vim.cmd.bdelete({ args = { tostring(buf) }, bang = force })
end

function M.setup()
  local group = api.nvim_create_augroup("WorkspacePanels", { clear = true })
  local tree_api = require("nvim-tree.api")
  api.nvim_create_autocmd({ "WinEnter", "BufEnter", "BufWinEnter" }, {
    group = group,
    callback = function()
      update_bar(api.nvim_get_current_win())
    end,
  })
  tree_api.events.subscribe(tree_api.events.Event.TreeOpen, function()
    local tab = api.nvim_get_current_tabpage()
    local left = tree_api.tree.winid({ tabpage = tab })
    local workspace = state(tab)
    if is_git(workspace.git) then
      local width = api.nvim_win_get_width(workspace.git)
      api.nvim_win_close(workspace.git, false)
      workspace.git = nil
      vim.t[tab].workspace = workspace
      api.nvim_win_set_width(left, width)
    end
    vim.wo[left].winbar = left_bar
  end)
  local windows = api.nvim_tabpage_list_wins(0)
  local left = tree_api.tree.winid()
  -- nvim-tree can take over the initial window when Nvim opens a directory.
  if left and #windows == 1 then
    local buf = api.nvim_create_buf(true, false)
    windows[2] = api.nvim_open_win(buf, false, { split = "right", win = left })
    tree_api.tree.resize()
  end
  for _, win in ipairs(windows) do
    update_bar(win)
  end
  M.focus_explorer()
end

return M
