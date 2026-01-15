local rename_file = require 'conf/utils'.rename_file

local function setup_user_commands()
  vim.api.nvim_create_user_command(
    'RenameFile',
    rename_file,
    { bang = true, desc = 'Rename current file' }
  )

  vim.api.nvim_create_user_command(
    'Files',
    function(input)
      vim.call('fzf#vim#files', input.args,
        vim.call('fzf#vim#with_preview', { source = 'rg --files --follow' }),
        input.bang)
    end,
    { bang = true, nargs = '?', complete = 'dir', desc = 'Search project files (using rg ignore)' }
  )

  vim.api.nvim_create_user_command(
    'Mkd',
    '!mkdir -p %:h',
    { bang = true }
  )
end

return {
  setup = setup_user_commands,
}
