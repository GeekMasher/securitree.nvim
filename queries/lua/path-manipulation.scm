;; look for variables being passed into normalize function

(function_call 
  (dot_index_expression) @name (#eq? @name "vim.fs.normalize")
  (arguments [
    ; . (string) ; static strings are fine 
    (identifier) @result ; variable access
  ])
)

