return

require('lualine').setup {
    options = {
        icons_enabled = true,
        theme = 'gruvbox',
        component_separators = { left = '', right = '' },
        section_separators = { left = '', right = '' },
        disabled_filetypes = {
            statusline = {'typst'},
            winbar = {},
        },
        ignore_focus = {},
        always_divide_middle = true,
        globalstatus = true,
        refresh = {
            statusline = 200,
            tabline = 200,
            winbar = 200,
        }
    },
    sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'diagnostics', 'diff' },
        lualine_c = {
            {
                'filename',
                path = 3,
                shorting_target = 10,
            }
        },
        lualine_x = { 'filetype' },
        lualine_y = { 'branch' },
        lualine_z = { 'location' }
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { 'filename' },
        lualine_x = { 'location' },
        lualine_y = {},
        lualine_z = {}
    },
    tabline = {},
    winbar = {},
    inactive_winbar = {},
    extensions = {}
}
