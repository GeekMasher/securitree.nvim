
(variable_declarator
  (identifier) @import
  (call_expression
    ; require("abc")
    (identifier) @require (#eq? @require "require")
    (arguments (string (string_fragment) @module))
  )
)

;; Import Statements
(import_statement
  (import_clause
    [
      ;; import x from 'y';
      (identifier) @import
      ;; import * as x from 'y';
      (namespace_import 
        (identifier) @import
      )
      ;; import { x } from 'y'
      (named_imports 
        (import_specifier (identifier) @import)
      )
    ]
  )
  source: (string (string_fragment) @module)
)

