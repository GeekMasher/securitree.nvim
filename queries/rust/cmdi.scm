;; use std::process::Command;
;; Command::new(...)
(call_expression
  (scoped_identifier 
    path: (identifier) @path
    (#check? @path "Command" "std::process")
  )
) @result

;; std::process::Command::new(...)
(call_expression
  (scoped_identifier) @path (#eq? @path "std::process::Command::new")
) @result

