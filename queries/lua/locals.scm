
(assignment_statement 
  (variable_list (identifier) @import)
  (expression_list 
    (function_call
      name: (identifier) @name (#eq? @name "require")
      arguments: (arguments (string) @module)
    )
  )
)

