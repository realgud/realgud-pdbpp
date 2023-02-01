;; Copyright (C) 2016, 2019, 2023 Free Software Foundation, Inc

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

;;  `pdbpp' Main interface to pdbpp via Emacs
(require 'load-relative)

(require 'realgud)
(require-relative-list '("core" "track-mode") "realgud--pdbpp-")

;; This is needed, or at least the docstring part of it is needed to
;; get the customization menu to work in Emacs 24.
(defgroup realgud:pdbpp nil
  "The realgud interface to the Python pdbpp debugger"
  :group 'realgud
  :version "25.1")

(declare-function make-realgud-loc "realgud-loc" (a b c d e f))

;; -------------------------------------------------------------------
;; User-definable variables
;;

(defcustom realgud--pdbpp-command-name
  "pdbpp"
  "File name for executing the stock Python debugger and command options.
This should be an executable on your path, or an absolute file name."
  :type 'string
  :group 'realgud:pdbpp)
;; -------------------------------------------------------------------
;; The end.
;;

(declare-function pdbpp-track-mode       'realgud:pdbpp-track)
(declare-function pdbpp-query-cmdline    'realgud:pdbpp-core)
(declare-function pdbpp-parse-cmd-args   'realgud:pdbpp-core)
(declare-function realgud--pdbpp-completion-at-point 'realgud:pdbpp-core)
(declare-function realgud:run-debugger 'realgud:run)

;;;###autoload
(defun realgud:pdbpp (&optional opt-cmd-line no-reset)
  "Invoke the pdbpp Python debugger and start the Emacs user interface.

String OPT-CMD-LINE specifies how to run pdbpp. You will be prompted
for a command line is one isn't supplied.

OPT-COMMAND-LINE is treated like a shell string; arguments are
tokenized by `split-string-and-unquote'. The tokenized string is
parsed by `pdbpp-parse-cmd-args' and path elements found by that
are expanded using `realgud:expand-file-name-if-exists'.

Normally, command buffers are reused when the same debugger is
reinvoked inside a command buffer with a similar command. If we
discover that the buffer has prior command-buffer information and
NO-RESET is nil, then that information which may point into other
buffers and source buffers which may contain marks and fringe or
marginal icons is reset. See `loc-changes-clear-buffer' to clear
fringe and marginal icons.
"
  (interactive)
  (let ((cmd-buf (realgud:run-debugger "pdbpp" 'pdbpp-query-cmdline
                                       'pdbpp-parse-cmd-args
                                       'realgud--pdbpp-minibuffer-history
                                       opt-cmd-line no-reset))
        )
    (add-hook 'completion-at-point-functions
              'realgud--pdbpp-completion-at-point nil t)
    (with-current-buffer cmd-buf
      (add-hook 'completion-at-point-functions
		'realgud--pdbpp-completion-at-point nil t)
      )
    cmd-buf)
  )


;;;###autoload
(defun realgud:pdbpp-remote (&optional opt-cmd-line no-reset)
  "Invoke the pdbpp Python debugger and start the Emacs user interface.

String OPT-CMD-LINE specifies how to run pdbpp. You will be prompted
for a command line is one isn't supplied.

OPT-COMMAND-LINE is treated like a shell string; arguments are
tokenized by `split-string-and-unquote'. The tokenized string is
parsed by `pdbpp-parse-remote-cmd-args' and path elements found by that
are expanded using `realgud:expand-file-name-if-exists'.

Normally, command buffers are reused when the same debugger is
reinvoked inside a command buffer with a similar command. If we
discover that the buffer has prior command-buffer information and
NO-RESET is nil, then that information which may point into other
buffers and source buffers which may contain marks and fringe or
marginal icons is reset. See `loc-changes-clear-buffer' to clear
fringe and marginal icons.
"
  (interactive)
  (let ((cmd-buf (realgud:run-debugger "pdbpp" 'pdbpp-remote-query-cmdline
                                       'pdbpp-parse-remote-cmd-args
                                       'realgud--pdbpp-remote-minibuffer-history
                                       opt-cmd-line no-reset "remote-pdbpp"))
        )
    (add-hook 'completion-at-point-functions
              'realgud--pdbpp-completion-at-point nil t)
    cmd-buf)
  )


;;;###autoload
(defalias 'pdbpp 'realgud:pdbpp)

(provide-me "realgud-")
