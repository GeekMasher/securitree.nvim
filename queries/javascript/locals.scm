
(variable_declarator
  (identifier) @import
  (call_expression
    ; require("abc")
    (identifier) @require (#eq? @require "require")
    (arguments (string (string_fragment) @module))
  )
)

;; import { X } from 'abc'
(import_statement
  (import_clause
    (named_imports 
      (import_specifier (identifier) @import)
    )
  )
  source: (string (string_fragment) @module)
)

