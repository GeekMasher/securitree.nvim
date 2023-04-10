;; https://github.com/nvim-treesitter/nvim-treesitter/blob/master/queries/rust/locals.scm
(use_declaration 
  (scoped_identifier
    (scoped_identifier) @module
    (identifier) @import
  )
)

(use_declaration 
  (scoped_use_list 
    (scoped_identifier) @module
    (use_list
      (identifier) @import
    )
  )
)

(use_declaration
  (scoped_identifier
    path: (identifier) @module
    name: (identifier) @import
  )
)

