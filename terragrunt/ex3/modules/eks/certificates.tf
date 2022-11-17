# locals {
#     createCerts = length(var.certificates) != 0 ? true : false
# }

resource "aws_acm_certificate" "cert" {
  #for_each = local.createCerts ? var.certificates : {}
  for_each = var.certificates

  domain_name               = each.value["domain_name"]
  subject_alternative_names = each.value["subject_alternative_names"]
  validation_method         = "DNS"

  tags = {
    Environment = var.cluster_name
  }
}

# This part is not working and I'm lazy to continue it

# resource "aws_route53_record" "route53-record" {
#   for_each = local.createCerts ? var.certificates : {}

#   name = tolist(aws_acm_certificate.cert[each.key].domain_validation_options)[0].resource_record_name
#   type = tolist(aws_acm_certificate.cert[each.key].domain_validation_options)[0].resource_record_type
#   zone_id = "Z23L123123123"
#   records = [tolist(aws_acm_certificate.cert[each.key].domain_validation_options)[0].resource_record_value]
#   ttl = 60
# }

# resource "aws_acm_certificate_validation" "cert-validation" {
#   #for_each = local.createCerts ? var.certificates : {}
#   for_each = var.certificates

#   certificate_arn = aws_acm_certificate.cert[each.key].arn
#   validation_record_fqdns = [aws_route53_record.route53-record[each.key].fqdn]
# }
