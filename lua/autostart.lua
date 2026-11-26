vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
	-- открытие tree view
        require("nvim-tree.api").tree.open()
    end,
})

