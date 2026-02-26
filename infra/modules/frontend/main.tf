resource "aws_s3_bucket" "react_bucket" {
    bucket = var.bucket_name
}

resource "aws_s3_bucket_ownership_controls" "react_bucket_ownership" {
    bucket = aws_s3_bucket.react_bucket.id
    rule {
        object_ownership = "BucketOwnerPreferred"
    }
}

resource "aws_s3_bucket_public_access_block" "react_bucket_block" {
    bucket                  = aws_s3_bucket.react_bucket.id
    block_public_acls = false
    block_public_policy = false
    ignore_public_acls = false
    restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "react_website" {
    bucket = aws_s3_bucket.react_bucket.id
    index_document {
      suffix = "index.html"
    }
    error_document {
      key = "index.html"
    }
}

resource "aws_s3_bucket_policy" "react_website_permissions" {
    bucket = aws_s3_bucket.react_bucket.id
    policy = jsonencode({
        Version="2012-10-17"
        Statement=[
            {
                Effect="Allow"
                Principal="*"
                Action = "s3:GetObject"
                Resource = "${aws_s3_bucket.react_bucket.arn}/*"
            }
        ]
    })
    depends_on = [ aws_s3_bucket_public_access_block.react_bucket_block ]
}