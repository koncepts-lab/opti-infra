# create ses domain identity and setup dkim so that we can sign outgoing emails.

resource "aws_ses_domain_identity" "mail_oi_portal" {
  domain = "mail.oi-portal.com"
}

resource "aws_ses_email_identity" "validated_emails" {
  email = "vishnuvyas@gmail.com"
}

resource "aws_route53_record" "ses_domain_verification" {
  zone_id = aws_route53_zone.oi_portal.zone_id
  name = aws_ses_domain_identity.mail_oi_portal.id
  type = "TXT"
  ttl = "600"
  records = [aws_ses_domain_identity.mail_oi_portal.verification_token]
}

# resource "aws_ses_domain_dkim" "mail_oi_portal_dkim" {
#   domain = aws_ses_domain_identity.mail_oi_portal.domain
# }

# resource "aws_route53_record" "mail_oi_portal_dkim_record" {
#   for_each = toset(aws_ses_domain_dkim.mail_oi_portal_dkim.dkim_tokens)
#   zone_id = aws_route53_zone.oi_portal.zone_id
#   name = "${each.value}._domainkey.mail.oi-portal.com"
#   type = "CNAME"
#   ttl = 600
#   records = ["${each.value}.dkim.amazonses.com"]

#   depends_on = [ aws_ses_domain_dkim.mail_oi_portal_dkim ]
# }

# setup an iam policy / user that enables us to send emails
resource "aws_iam_user" "email_user" {
  name = "email_user"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${local.prefix}-email-user"
  }
}

data "aws_iam_policy_document" "aws_ses_sender" {
  statement {
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "send_email_policy" {
  name = "ses-send-emails"
  user = aws_iam_user.email_user.name
  policy = data.aws_iam_policy_document.aws_ses_sender.json
}

resource "aws_iam_access_key" "email_sender_access_key" {
  user = aws_iam_user.email_user.name
}
