;; Math.random()
(call_expression 
  (member_expression
    object: (identifier) @obj (#match? @obj "^Math$")
    property: (property_identifier) @func (#match? @func "random")
  )
) @result

