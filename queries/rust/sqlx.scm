;; sqlx::query
;; sqlx::query_as
(call_expression
  (generic_function
    (scoped_identifier
      path: (identifier) @path (#eq? @path "sqlx")
      name: (identifier) @name (#match? @name "(query|query_as)")
    )
  )

  (arguments [
    (reference_expression) @result
    (call_expression) @result
  ]) 
)

