local M = {}

function M.setup() end

function M.secrets_list()
  require("cshelper.secrets").list()
end

function M.secrets_edit()
  require("cshelper.secrets").list()
end

function M.templates()
  require("cshelper.template_chooser").show()
end

return M
