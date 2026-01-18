########################################
# Package SOAR Lambda Code
########################################

data "archive_file" "soar_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda/soar_dispatcher.zip"
}
