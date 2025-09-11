data "aws_caller_identity" "current" {}

# Block public access (we'll use a bucket policy that grants only CloudFront)
resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = data.aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy: allow only *this* CloudFront distribution via OAC
data "aws_iam_policy_document" "cf_read" {
  statement {
    sid    = "AllowCloudFrontReadViaOAC"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${data.aws_s3_bucket.site.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values = [
        "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.cdn.id}"
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = data.aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.cf_read.json

  depends_on = [
    aws_cloudfront_distribution.cdn,
    aws_s3_bucket_public_access_block.site
  ]
}