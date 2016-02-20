(require 'compile) ; Must do this before the `defadvice compile` because this redefines `compile`.
(defadvice compile (around gmd-compile-with-smart-command activate)
  "This adds the ability to use %s in the compile command to refer to the full path of the current buffer's file."
  (interactive (list (gmd-read-compile-command)))
  ad-do-it)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(require 'package)
(add-to-list 'package-archives
	     '("melpa-stable" . "http://stable.melpa.org/packages/") t)

(defalias 'perl-mode 'cperl-mode)

(add-to-list 'auto-mode-alist '("\\.pm$" . cperl-mode))
(add-to-list 'auto-mode-alist '("\\.pl$" . cperl-mode))


(menu-bar-mode -1)

(setq read-file-name-completion-ignore-case t)
(setq read-buffer-completion-ignore-case t)

(custom-set-variables
 '(load-home-init-file t t))
(custom-set-faces)

(add-hook 'javascript-mode-hook
	  (lambda ()
	    (setq c-basic-offset 4)
))
(add-hook 'cperl-mode-hook
	  (lambda ()
	    (setq cperl-indent-level 4
		  cperl-close-paren-offset -4
		  cperl-continued-statement-offset 4
		  cperl-indent-parens-as-block t
		  cperl-tab-always-indent t)
	    (font-lock-mode)))

(defun gmd-vc-root-dir()
  (gmd-chomp (gmd-shell-command-to-string "git rev-parse --show-toplevel")))

(defun gmd-chomp (str)
  (if (and str (string-match "[\n\t\s]+\\'" str))
      (replace-match "" t t str)
    str))

(defun gmd-shell-command-to-string(command)
  (with-temp-buffer
    (if	(= 0 (call-process-shell-command command nil (current-buffer)))
	(buffer-string)
      nil)))

;; Note: This doesn't default to the last compile command. I think I
;; prefer it this way.
(defun gmd-default-compile-command()
  (cond	((equal major-mode 'ruby-mode)
	 (concat "cd "
		 (or (gmd-vc-root-dir) ".") ; Default to current directory.
		 " && rspec  ~/config/.rspec_color.rb --format documentation %s:%l"))
	('t
	 (display-message-or-buffer (format "Unrecognized major mode '%s'." major-mode))
	 compile-command)))

(defun gmd-replace-placeholders(command-template)
  (let ((filename (if (buffer-file-name) (buffer-file-name) ""))
	(line-number-str (number-to-string (line-number-at-pos))))
    (command command-template))
  ;; Nobody actually wants %s or %l in their command... right?
  (setq command (replace-regexp-in-string "%l" line-number-str command))
  (setq command (replace-regexp-in-string "%s" filename command))
  command)

(require 'compile) ; Must do this before the `defadvice compile` because this redefines `compile`.
(defadvice compile (around gmd-compile-with-smart-command activate)
  "%s in the command is replaced with the current buffer's filename. 
   %l is replaced with the current line number."
  (interactive (list (gmd-replace-placeholders (read-string "Command: "
							    (gmd-default-compile-command)
							    'compile-history))))
  ad-do-it)
