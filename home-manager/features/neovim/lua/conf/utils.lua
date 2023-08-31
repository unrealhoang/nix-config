local function rename_file()
  local old_name = vim.fn.expand('%')
  local new_name = vim.fn.input('New file name: ', old_name, 'file')
  if new_name ~= '' and new_name ~= old_name then
    vim.cmd(string.format("saveas %s", new_name))
    vim.cmd(string.format("silent !rm %s", old_name))
    vim.cmd('redraw!')
  end
end

return {
  rename_file = rename_file,
}
