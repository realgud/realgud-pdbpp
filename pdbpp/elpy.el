;; Copyright (C) 2023 Free Software Foundation, Inc

(defun elpy-test-pytest-pdb-runner (top file module test)
  (interactive (elpy-test-at-point))
  (realgud:pdbpp (format "python -m pytest --pdb -s %s"
                       (cond
                        (test
                         (let ((test-list (split-string test "\\.")))
                           (mapconcat #'identity
                                      (cons file test-list)
                                      "::")))
                        (module file)
                        (t "")))))

(defun elpy-test-pdb (&optional test-whole-project)
  "Run test the current project with the elpy-test-pdb-runner

            prefix args have the same semantics as for `elpy-test'"
  (interactive "P")
  (let ((elpy-test-runner elpy-test-pdb-runner))
    (elpy-test test-whole-project)))
(defvar elpy-test-pdb-runner
  #'elpy-test-pytest-pdb-runner
  "Test runner to run with pdb++")
