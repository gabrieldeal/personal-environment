;;; clever-cmd.el --- Cleverize things that run commands (compile, grep)

;; Copyright (C) 2016 Gabriel M Deal
;; Author: Gabriel M Deal <gabriel.m.deal@gmail.com>
;; Version: 0.0.1
;; Package-Requires: ((inf-ruby "2.0.0"))
;; Keywords: tools, unix, compilation-mode, grep
;; URL:


;;; Commentary:

;; Choose default grep/compile commands based on the major mode.
;; Do path and line number substitution in commands.
;; Add byebug support to compilation-mode.

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Customize compile and grep commands based on the major mode:

;; Note: This doesn't default to the last compile command. I think I
;; prefer it this way.
(defun clever-cmd-default-command(command-type default)
  (let ((command-sym (intern-soft (concat "clever-cmd-" (symbol-name major-mode) "-" command-type "-command"))))
    (cond ((fboundp command-sym)
	   (funcall command-sym))
	  ((and command-sym (boundp command-sym))
	   (symbol-value command-sym))
	  ('t
	   (display-message-or-buffer (format "No '%s' command for major mode '%s'."
					      command-type
					      major-mode))
	   default))))

(defun clever-cmd-replace-placeholders(command-template)
  (let ((filename (if (buffer-file-name) (buffer-file-name) ""))
	(line-number-str (number-to-string (line-number-at-pos)))
	(command command-template))
    ;; Nobody actually wants %s or %l in their command... right?
    (setq command (replace-regexp-in-string "%l" line-number-str command))
    (setq command (replace-regexp-in-string "%s" filename command))
    command))

(defun clever-cmd-read-shell-command(default-default-command command-history command-type)
  (let* ((default-command (clever-cmd-default-command command-type default-default-command))
	 (command-from-user-with-placeholders (read-shell-command "Command: "
								  default-command
								  command-history))
	 (command-from-user (clever-cmd-replace-placeholders command-from-user-with-placeholders)))
    (if (not (string= command-from-user command-from-user-with-placeholders))
	;; Save the file and line number in history instead of the placeholder:
	(set command-history (push command-from-user (cdr (symbol-value command-history)))))
    command-from-user))

;;;###autoload
(defun clever-cmd-compile-with-smart-command(orig-fun &rest args)
  "Uses `clever-cmd-<MAJOR-MODE>-compile-command` (variable or function) to determine the default command. Then prompts the user for an override command.

%s in the command is replaced with the current buffer's filename.
%l is replaced with the current line number.

Install it like this:
\(advice-add 'compile :around #'clever-cmd-compile-with-smart-command)
"
  (interactive (list (clever-cmd-read-shell-command compile-command 'compile-history "compile")))
  (apply orig-fun args))

;;;###autoload
(defun clever-cmd-grep-with-smart-command(orig-fun &rest args)
  "Uses `clever-cmd-<MAJOR-MODE>-grep-command` (variable or function) to determine the default command. Then prompts the user for an override command.

Install it like this:
\(advice-add 'grep :around #'clever-cmd-grep-with-smart-command)"
  (interactive (list (clever-cmd-read-shell-command grep-command 'grep-history "grep")))
  (apply orig-fun args))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; compilation-mode filter for Ruby's byebug:


(defun clever-cmd-convert-to-ruby-console()
  "Changes a compilation-mode window into a Ruby console (useful for debugging rspecs)."
  (interactive)
  (read-only-mode 0)
  (require 'inf-ruby)
  (inf-ruby-mode))

;;;###autoload
(defun clever-cmd-ruby-byebug-compilation-filter ()
  "Convert a compilation window to a Ruby console if a byebug breakpoint is hit.

Install the filter like this:
\(add-hook 'compilation-filter-hook 'clever-cmd-ruby-byebug-compilation-filter)"
  (if (not (local-variable-if-set-p 'clever-cmd-ruby-byebug-compilation-filter-is-done))
      (save-excursion
	(goto-char compilation-filter-start)
	(if (re-search-forward "^(byebug) " nil t)
	    (progn
	      (clever-cmd-convert-to-ruby-console)
	      (make-local-variable 'clever-cmd-ruby-byebug-compilation-filter-is-done))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide 'clever-cmd)
;;; clever-cmd.el ends here
