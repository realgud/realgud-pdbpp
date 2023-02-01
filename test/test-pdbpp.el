;; Press C-x C-e at the end of the next line to run this file test non-interactively
;; (test-simple-run "emacs -batch -L %s -l %s" (file-name-directory (locate-library "test-simple.elc")) buffer-file-name)

(require 'test-simple)
(require 'load-relative)
(load-file "../pdbpp/pdbpp.el")

(eval-when-compile (defvar test:run-process-save))

(declare-function pdbpp-parse-cmd-args 'realgud:pdbpp-core)
(declare-function realgud:pdbpp        'realgud:pdbpp)
(declare-function __FILE__            'load-relative)

(test-simple-start)

;; Save value realgud:run-process and change it to something we want
(setq test:run-process-save (symbol-function 'realgud:run-process))
(defun realgud:run-process(debugger-name script-filename cmd-args
				      minibuffer-histroy &optional no-reset)
  "Fake realgud:run-process used in testing"
  (note
   (format "%s %s %s" debugger-name script-filename cmd-args))
  (assert-equal "pdbpp" debugger-name "debugger name gets passed")
  (assert-equal (expand-file-name "./gcd.py") script-filename "file name check")
  (assert-equal '("3" "5") (cddr cmd-args) "command args listified")
  (generate-new-buffer "*cmdbuf-test*")
  )

(note "pdbpp-parse-cmd-args")
(assert-equal (list nil '("pdbpp") (list (expand-file-name "foo")) nil)
	      (pdbpp-parse-cmd-args '("pdbpp" "foo")))
(assert-equal (list nil '("pdbpp") (list (expand-file-name "program.py") "foo") nil)
	      (pdbpp-parse-cmd-args
	       '("pdbpp" "program.py" "foo")))

(realgud:pdbpp "pdbpp ./gcd.py 3 5")
;; Restore the old value of realgud:run-process
(fset 'realgud:run-process test:run-process-save)

(end-tests)
