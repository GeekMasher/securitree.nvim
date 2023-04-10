;; resource == aws_s3_bucket
;; acl not present or acl is set to 'public'
(block 
  (string_lit (template_literal) @resource)
  (#eq? @resource "aws_s3_bucket")
  (body 
    (attribute
      (identifier) @attr
      (expression
        (literal_value
          (string_lit
            (template_literal) @acl (#eq? @acl "public")
          )
        )
      )?
    )
    (#not-contains? @attr "acl")
  )
) @result

