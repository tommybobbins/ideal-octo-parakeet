resource "random_password" "jupy_string" {
  length  = 16
  special = false
  #  override_special = "/@£$"
}


data "template_file" "init" {
  template = file("userdata.sh")
  vars = {
    project_name    = var.project_name,
    break_workspace = var.break_workspace,
    jupyter_passwd  = random_password.jupy_string.result,
    account_id      = data.aws_caller_identity.current.account_id
  }
}

