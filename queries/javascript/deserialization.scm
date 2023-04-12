
;; jsyaml.load
(call_expression 
  (member_expression 
    object: (identifier) @import (#imports? @import "js-yaml")
    property: (property_identifier) @load (#match? @load "(load|loadAll)")
  ) @result
)

;; jsyaml.DEFAULT_FULL_SCHEMA
(member_expression
  object: (identifier) @import (#imports? @import "js-yaml")
  property: (property_identifier) @schema (#eq? @schema "DEFAULT_FULL_SCHEMA")
) @result


