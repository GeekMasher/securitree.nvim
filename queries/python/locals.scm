;; https://github.com/nvim-treesitter/nvim-treesitter/blob/master/queries/python/locals.scm

(import_statement 
  (dotted_name
    (identifier) @import
  ) @module
)

(import_from_statement
  module_name: (dotted_name) @module
  name: (dotted_name) @import
)

