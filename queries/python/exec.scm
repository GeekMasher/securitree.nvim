;; __builtin__.eval()
(call
  function: (identifier) @name (#eq? @name "eval")
  (argument_list
    . (identifier) @result
  )
)
