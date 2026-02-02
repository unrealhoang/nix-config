local function setup_user_commands()
  vim.api.nvim_create_user_command(
    'Mkd',
    '!mkdir -p %:h',
    { bang = true }
  )
  vim.api.nvim_create_user_command(
    'BufOnly',
    function(opts)
      Snacks.bufdelete.other({ force = opts.bang })
    end,
    { bang = true }
  )
end

return {
  setup = setup_user_commands,
}
