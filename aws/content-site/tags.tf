locals {
  tags = merge(
    var.tags,
    {
      Terraform       = true
      TerraformModule = "github.com/halostatue/terraform-modules//aws/content-site@v5.3.1"
    }
  )
}
