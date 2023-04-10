;;

(block 
  (string_lit (template_literal) @resource)
  (#eq? @resource "aws_s3_bucket")
  (body 
    (_
      (identifier) @attr
      (body
        (attribute
          (identifier) @enabled (#eq? @enabled "enabled")
          (expression (literal_value (bool_lit) @value (#eq? @value "false")))
        )
      )?
    )
    (#not-contains? @attr "versioning")
  )
) @result

