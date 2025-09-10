output "api_invoke_url" {
  value = aws_apigatewayv2_api.httpapi.api_endpoint
}

output "get_count_url" {
  value = "${aws_apigatewayv2_api.httpapi.api_endpoint}/count"
}