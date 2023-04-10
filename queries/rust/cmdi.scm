;; std::process::Command::new(...)

(call_expression
  (scoped_identifier) @result (#match? @result "^(std::process::Command::new|Command::new)")
)

