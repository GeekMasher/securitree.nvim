;; https://doc.rust-lang.org/std/fs/fn.canonicalize.html

(call_expression 
  function: (identifier) @name
  (#check? @name "canonicalize" "fs")
  
  (arguments [
    (reference_expression) @result     
  ])
)

(call_expression
  (scoped_identifier) @path
  (#eq? @path "std::fs::canonicalize")

  (arguments [
    (reference_expression) @result     
  ])
)

