terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    postmark = {
      source  = "shebang-labs/postmark"
      version = "0.2.4"
    }
  }
}

provider "aws" {}
provider "random" {}
provider "postmark" {}


resource "postmark_server" "server" {
  name          = var.serverName
  delivery_type = "live"
}

resource "postmark_domain" "domain" {
  name  = var.domain
}

data "aws_route53_zone" "zone" {
  name  = var.domain
}

resource "aws_route53_record" "postmark_domain_dkim" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = postmark_domain.domain.dkim_pending_host
  type    = "TXT"
  ttl     = 300
  records = [
    postmark_domain.domain.dkim_pending_text_value
  ]
}

resource "aws_route53_record" "postmark_domain_return_path" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = postmark_domain.domain.return_path_domain
  type    = "CNAME"
  ttl     = 300
  records = [
    postmark_domain.domain.return_path_domain_cname_value
  ]
}

resource "random_pet" "postmark_server_key" {
  length = 2
}

resource "aws_ssm_parameter" "postmark_server_key" {
  name        = "/postmark_server/${random_pet.postmark_server_key.id}/server_key"
  description = "server key for postmark server ${var.serverName}"
  type        = "SecureString"
  value       = postmark_server.server.apitokens[0]
}


output "postmarkServerKey" {
  value = aws_ssm_parameter.postmark_server_key.arn
}

