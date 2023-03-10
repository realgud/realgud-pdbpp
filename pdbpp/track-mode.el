;; Copyright (C) 2016, 2018, 2019, 2023 Free Software Foundation, Inc

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
;; Python "pdbpp" Debugger tracking a comint buffer.

(eval-when-compile (require 'cl-lib))

(require 'realgud)
(require 'load-relative)

(require-relative-list '("core" "init") "realgud--pdbpp-")

(realgud-track-mode-vars "pdbpp")

(declare-function realgud-track-mode 'realgud-track-mode)
(declare-function realgud-track-mode-setup 'realgud-track-mode)
(declare-function realgud:track-set-debugger 'realgud-track-mode)
(declare-function realgud-python-populate-command-keys 'realgud-lang-python)
(declare-function realgud:pdbpp-completion-at-point 'realgud:pdbpp-core)

(realgud-python-populate-command-keys pdbpp-track-mode-map)

(defun pdbpp-track-mode-hook()
  (if pdbpp-track-mode
      (progn
        (use-local-map pdbpp-track-mode-map)
	(realgud:remove-ansi-schmutz)
        (add-hook 'completion-at-point-functions
                  'realgud:pdbpp-completion-at-point nil t)
        (message "using pdbpp mode map")
        )
    (message "pdbpp track-mode-hook disable called")
    )
)

(define-minor-mode pdbpp-track-mode
  "Minor mode for tracking pdbpp source locations inside a process shell via realgud. pdbpp is a Python debugger based on ipython.

If called interactively with no prefix argument, the mode is toggled. A prefix argument, captured as ARG, enables the mode if the argument is positive, and disables it otherwise.

a process shell.

\\{pdbpp-track-mode-map}
"
  :init-value nil
  ;; :lighter " pdbpp"   ;; mode-line indicator from realgud-track is sufficient.
  ;; The minor mode bindings.
  :global nil
  :group 'realgud:pdbpp
  :keymap pdbpp-track-mode-map
  (realgud:track-set-debugger "pdbpp")
  (if pdbpp-track-mode
      (progn
	(realgud-track-mode-setup 't)
        (pdbpp-track-mode-hook))
    (progn
      (setq realgud-track-mode nil)
      ))
)

(provide-me "realgud--pdbpp-")
