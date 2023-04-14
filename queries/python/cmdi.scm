
;; from subprocess import run
;; run(['ls'])
(call 
  function: (identifier) @dangerous
  (#imports? @dangerous "subprocess")
  (argument_list . (_) @result)
)

;; import subprocess
;; subprocess.run(["ls"])
(call 
  (attribute
    object: (identifier) @object (#imports? @object "subprocess")
    attribute: (identifier) @dangerous
  )
  (argument_list . (_) @result)
)


;; subprocess functions
(#match? @dangerous "(run|check_call|check_output)")

