Introduction
============

Emacs Lisp Module to add [pdb++](https://github.com/pdbpp/pdbpp/) support to [realgud](https://github.com/realgud/realgud).


Installation
=============

From github source
------------------

* Have `realgud` and `test-simple` installed.
* From inside GNU Emacs, evaluate:
```lisp
  (compile (format "EMACSLOADPATH=:%s:%s ./autogen.sh" (file-name-directory (locate-library "test-simple.elc")) (file-name-directory (locate-library "realgud.elc"))))
```

[gnu-elpa-image]: https://elpa.gnu.org/packages/realgud-pdbpp.svg
[gnu-elpa]: https://elpa.gnu.org/packages/realgud-pdbpp.html
