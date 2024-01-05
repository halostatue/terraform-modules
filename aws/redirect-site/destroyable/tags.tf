locals {
  tags = merge(
    var.tags, {
      Terraform       = true
      TerraformModule = "github.com/halostatue/terraform-modules//aws/redirect-site/destroyable@v5.4.0"
    }
  )
}
