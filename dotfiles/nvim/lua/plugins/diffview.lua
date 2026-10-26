return {
	{
		"sindrets/diffview.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		cmd = {
			"DiffviewOpen",
			"DiffviewClose",
			"DiffviewToggleFiles",
			"DiffviewFocusFiles",
			"DiffviewFileHistory",
			"DiffviewRefresh",
		},
		keys = {
			{
				"<leader>gv",
				function()
					if next(require("diffview.lib").views) == nil then
						vim.cmd("DiffviewOpen")
					else
						vim.cmd("DiffviewClose")
					end
				end,
				desc = "Toggle Diffview",
			},
			{
				"<leader>gh",
				"<cmd>DiffviewFileHistory %<cr>",
				mode = "n",
				desc = "Diffview File History (current file)",
			},
			{
				"<leader>gh",
				":'<,'>DiffviewFileHistory<cr>",
				mode = "x",
				desc = "Diffview File History (selection)",
			},
			{
				"<leader>gH",
				"<cmd>DiffviewFileHistory<cr>",
				desc = "Diffview Repo History",
			},
		},
		opts = {
			enhanced_diff_hl = true,
			view = {
				merge_tool = {
					layout = "diff3_mixed",
				},
			},
		},
	},
}
