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
			{ "<leader>d", group = "Diffview" },
			{
				"<leader>dd",
				function()
					if next(require("diffview.lib").views) == nil then
						vim.cmd("DiffviewOpen")
					else
						vim.cmd("DiffviewClose")
					end
				end,
				desc = "Toggle Diffview (working tree)",
			},
			{ "<leader>dc", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
			{ "<leader>dr", "<cmd>DiffviewRefresh<cr>", desc = "Refresh Diffview" },
			{ "<leader>de", "<cmd>DiffviewToggleFiles<cr>", desc = "Toggle file panel" },
			{ "<leader>df", "<cmd>DiffviewFocusFiles<cr>", desc = "Focus file panel" },
			{ "<leader>dh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history (current file)" },
			{ "<leader>dh", ":'<,'>DiffviewFileHistory<cr>", mode = "x", desc = "File history (selection)" },
			{ "<leader>dH", "<cmd>DiffviewFileHistory<cr>", desc = "Repo history" },
			{ "<leader>dm", "<cmd>DiffviewOpen origin/HEAD...HEAD --imply-local<cr>", desc = "Diff against origin/HEAD (PR view)" },
			{ "<leader>ds", "<cmd>DiffviewOpen --staged<cr>", desc = "Staged changes" },
			{
				"<leader>db",
				function()
					Snacks.picker.git_branches({
						title = "Diffview against branch",
						confirm = function(picker, item)
							picker:close()
							if item then
								vim.cmd("DiffviewOpen " .. (item.branch or item.text) .. "...HEAD")
							end
						end,
					})
				end,
				desc = "Diff against branch (picker)",
			},
			{
				"<leader>dl",
				function()
					Snacks.picker.git_log({
						title = "Diffview commit",
						confirm = function(picker, item)
							picker:close()
							if item then
								vim.cmd("DiffviewOpen " .. (item.commit or item.text) .. "^!")
							end
						end,
					})
				end,
				desc = "Diff a commit (picker)",
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
