return {
	{
		'nvim-lualine/lualine.nvim',
		dependencies = { 'nvim-tree/nvim-web-devicons' },
		opts = {
			options = {
				theme = "gruvbox-material",
				-- component_separators = { left = '', right = '' },
				section_separators = { left = '', right = '' },
				-- section_separators = { left = "", right = "" },
				-- component_separators = { left = "", right = "" },
				-- section_separators = "",
				component_separators = "|"
			},
			sections = {
				lualine_c = {
					{ "filename", file_status = true, newfile_status = true, path = 1 },
				},
				lualine_x = {
					'encoding',
					'fileformat',
					'filetype'
				},
			},
			winbar = {
				lualine_c = {
					{
						"navic",
						navic_opts = {
							highlight = true,
						}
					}
				},
				lualine_x = {
					'lsp_status',
				}
			}
		}
	},
	{
		"SmiteshP/nvim-navic",
		dependencies = { "neovim/nvim-lspconfig" },
		event = "LspAttach",
		config = function()
			local navic = require("nvim-navic")
			vim.api.nvim_create_autocmd('LspAttach', {
				callback = function(ev)
					local client = vim.lsp.get_client_by_id(ev.data.client_id)
					if client.server_capabilities.documentSymbolProvider then
						navic.attach(client, ev.buf)
					end
				end,
			})
		end
	},
}
