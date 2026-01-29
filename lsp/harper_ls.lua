return {
  cmd = { 'harper-ls', '--stdio' },
  filetypes = { 'markdown' },
  root_markers = { '.git' },
  settings = {
    ['harper-ls'] = {
      userDictPath = vim.fn.stdpath('config') .. '/spell/en.utf-8.add',
      linters = {
        ToDoHyphen = false,
        SentenceCapitalization = false,
      },
      isolateEnglish = true,
      markdown = {
        IgnoreLinkTitle = true,
      },
    },
  },
}
