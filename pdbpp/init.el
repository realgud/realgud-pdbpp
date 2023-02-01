;; Copyright (C) 2016, 2018-2019, 2023 Free Software Foundation, Inc

;; Author: Rocky Bernstein <rocky@gnu.org>
;; Author: Sean Farley <sean@farley.io>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;; pdbpp: "interactive" debugger extension to Python debugger pdb

(eval-when-compile (require 'cl-lib))   ;For setf.

(require 'load-relative)
(require 'realgud)

(defvar realgud-pat-hash)
(declare-function make-realgud-loc-pat 'realgud-regexp)

(defvar realgud:pdbpp-pat-hash (make-hash-table :test 'equal)
  "Hash key is the what kind of pattern we want to match:
backtrace, prompt, etc.  The values of a hash entry is a
realgud-loc-pat struct")

(declare-function make-realgud-loc 'realgud-loc)

;; -------------------------------------------------------------------
;; User-definable variables
;;

;; realgud-loc-pat that describes a pdbpp location generally shown
;; before a command prompt.
;;
;; Program-location lines look like this:
;;   [0] > /usr/bin/zonetab2pot.py(15)<module>()
;; or MS Windows:
;;   [0] > c:\\mydirectory\\gcd.py(10)<module>
(setf (gethash "loc" realgud:pdbpp-pat-hash)
      (make-realgud-loc-pat
       :regexp "^\\[[0-9]+\\] > \\(\\(?:[a-zA-Z]:\\)?[-a-zA-Z0-9_/.\\\\ ]+\\)(\\([0-9]+\\))"
       ;; Todo add a frame group in realgud for pattern group 1. That is the first
       ;; number in [] above.
       :file-group 1
       :line-group 2))

;; An initial list of regexps that don't generally have files
;; associated with them and therefore we should not try to find file
;; associations for them.  This list is used to seed a field of the
;; same name in the cmd-info structure inside a command buffer. A user
;; may add additional files to the command-buffer's re-ignore-list.
(setf (gethash "ignore-re-file-list" realgud:pdbpp-pat-hash)
      (list realgud-python-ignore-file-re))

(setf (gethash "prompt" realgud:pdbpp-pat-hash)
      (make-realgud-loc-pat
       :regexp   "^(Pdb++) "
       ))

;;  realgud-loc-pat that describes a Python backtrace line.
(setf (gethash "lang-backtrace" realgud:pdbpp-pat-hash)
      realgud-python-backtrace-loc-pat)

(setf (gethash "debugger-backtrace" realgud:pdbpp-pat-hash)
      realgud:python-trepan-backtrace-pat)

;;  realgud-loc-pat that describes a line a Python "info break" line.
;; For example:
;; 1   breakpoint    keep y   at /usr/local/bin/trepan3k:7
(setf (gethash "debugger-breakpoint" realgud:pdbpp-pat-hash)
  (make-realgud-loc-pat
   :regexp (format "^%s[ \t]+\\(breakpoint\\)[ \t]+\\(keep\\|del\\)[ \t]+\\(yes\\|no\\)[ \t]+.*at \\(.+\\):%s"
		   realgud:regexp-captured-num realgud:regexp-captured-num)
   :num 1
   :text-group 2  ;; misnamed Is "breakpoint" or "watchpoint"
   :string 3      ;; misnamed. Is "keep" or "del"
   :file-group 5
   :line-group 6))

;;  realgud-loc-pat that describes location in a pytest error
(setf (gethash "pytest-error" realgud:pdbpp-pat-hash)
      realgud-pytest-error-loc-pat)

;;  realgud-loc-pat that describes location in a flake8 message
(setf (gethash "flake8-msg" realgud:pdbpp-pat-hash)
      realgud-flake8-msg-loc-pat)

;;  realgud-loc-pat that describes a "breakpoint set" line. For example:
;;     Breakpoint 1 at /usr/bin/pdbpp:7
(setf (gethash "brkpt-set" realgud:pdbpp-pat-hash)
      (make-realgud-loc-pat
       :regexp "^Breakpoint \\([0-9]+\\) at[ \t\n]+\\(.+\\):\\([0-9]+\\)\\(\n\\|$\\)"
       :num 1
       :file-group 2
       :line-group 3))

;; realgud-loc-pat that describes a "delete breakpoint" line
;; Python 3 includes a file name and line number; Python 2 doesn't
(setf (gethash "brkpt-del" realgud:pdbpp-pat-hash)
      (make-realgud-loc-pat
       :regexp "^Deleted breakpoint \\([0-9]+\\)"
       :num 1))

(setf (gethash "font-lock-keywords" realgud:pdbpp-pat-hash)
      '(
	;; The frame number and first type name, if present.
	("^\\(->\\|##\\)\\([0-9]+\\) \\(<module>\\)? *\\([a-zA-Z_][a-zA-Z0-9_]*\\)(\\(.+\\))?"
	 (2 realgud-backtrace-number-face)
	 (4 font-lock-function-name-face nil t))     ; t means optional.

	;; Parameter sequence, E.g. gcd(a=3, b=5)
	;;                             ^^^^^^^^^
	("(\\(.+\\))"
	 (1 font-lock-variable-name-face))

	;; File name. E.g  file '/test/gcd.py'
	;;                 ------^^^^^^^^^^^^-
	("[ \t]+file '\\([^ ]+*\\)'"
	 (1 realgud-file-name-face))

	;; Line number. E.g. at line 28
        ;;                  ---------^^
	("[ \t]+at line \\([0-9]+\\)$"
	 (1 realgud-line-number-face))

	;; Function name.
	("\\<\\([a-zA-Z_][a-zA-Z0-9_]*\\)\\.\\([a-zA-Z_][a-zA-Z0-9_]*\\)"
	 (1 font-lock-type-face)
	 (2 font-lock-function-name-face))
	;; (pdbpp-frames-match-current-line
	;;  (0 pdbpp-frames-current-frame-face append))
	))

(setf (gethash "pdbpp" realgud-pat-hash) realgud:pdbpp-pat-hash)

(defvar realgud:pdbpp-command-hash (make-hash-table :test 'equal)
  "Hash key is command name like 'finish' and the value is
the pdbpp command to use, like 'return'")

;; Mappings between pdbpp-specific names and GUD names
(setf (gethash "finish"           realgud:pdbpp-command-hash) "return")
(setf (gethash "kill"             realgud:pdbpp-command-hash) "quit")
(setf (gethash "backtrace"        realgud:pdbpp-command-hash) "where")
;; Clear in Python does both the usual “delete” and “clear”
(setf (gethash "delete"           realgud:pdbpp-command-hash) "clear %p")
(setf (gethash "clear"            realgud:pdbpp-command-hash) "clear %X:%l")
;; Use ‘!’ instead of ‘p’, since ‘p’ only works for expressions, not statements
(setf (gethash "eval"             realgud:pdbpp-command-hash) "pp %s")
(setf (gethash "info-breakpoints" realgud:pdbpp-command-hash) "break")

;; Unsupported features:
(setf (gethash "shell" realgud:pdbpp-command-hash) "*not-implemented*")
(setf (gethash "frame" realgud:pdbpp-command-hash) "*not-implemented*")

(setf (gethash "pdbpp" realgud-command-hash) realgud:pdbpp-command-hash)

(provide-me "realgud--pdbpp-")
