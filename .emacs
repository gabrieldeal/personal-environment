;;; .emacs --- You know.

;;; Commentary:

;; This is here to make flycheck happy.

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Set the title of the XWindows window.
(defun set-title(title)
  (interactive "sTitle: ")
  (setq-default frame-title-format title))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; For M-x package-install

(defun gmd-refresh-local-package-archive-contents (packages package-source-directory)
  (let ((should-refresh (or (not (boundp 'package-archive-contents))
			    (not package-archive-contents))))
    (dolist (package packages)
      (unless (assoc package package-archive-contents)
	(progn
	  (package-upload-file (format "%s/%s.el"
				       package-source-directory
				       package))
	  (setq should-refresh t))))
    (if should-refresh
	(package-refresh-contents))))

(defun gmd-install-packages (packages)
  (dolist (package packages)
    (when (not (package-installed-p package))
      (package-install package))))

(defvar gmd-package-archive-directory (expand-file-name "~/.emacs.d/gmd/"))
(defvar gmd-package-source-directory (expand-file-name "~/config/emacs/package-archives"))

(autoload 'package-upload-file "package-x" "doc" t)
(with-eval-after-load "package-x"
  (setq package-archive-upload-base gmd-package-archive-directory))

(require 'package)

(add-to-list 'package-archives
	     '("melpa" . "http://melpa.org/packages/"))
(add-to-list 'package-archives
	     '("marmalade" . "http://marmalade-repo.org/packages/") t)
(add-to-list 'package-archives
	     '("tromey" . "http://tromey.com/elpa/") t)
(add-to-list 'package-archives
	     (cons "gmd" gmd-package-archive-directory) t)

(defvar gmd-local-packages '(clever-cmd))
(defvar gmd-remote-packages
  '(cider
    clojure-mode
    flycheck
    jsx-mode
    magit
    markdown-mode
    nxml-mode
    paredit
    puppet-mode
    robe
    rubocop
    web-mode
    ws-trim))

(package-initialize)
(gmd-refresh-local-package-archive-contents gmd-local-packages gmd-package-source-directory)
(gmd-install-packages (append gmd-local-packages gmd-remote-packages))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set load path and load libraries
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq load-path
      (append load-path (list (expand-file-name "~/.emacs.d/manual"))))

(savehist-mode 1)
(autoload 'nxml-mode "nxml-mode" "doc" t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Git mode

(autoload 'magit-diff "magit" "doc" t)
(autoload 'magit-status "magit" "doc" t)
(autoload 'magit-log "magit" "doc" t)

(defun gmd-vc-root-dir()
  (let ((root-dir (gmd-chomp (gmd-shell-command-to-string "git rev-parse --show-toplevel"))))
    (if root-dir
	(concat root-dir "/") ; Without the trailing slash, the diff buffer has nothing in it.
      nil)))

;; Set the default directory, so I can press enter on a line of my
;; diff buffer and it will take me to the changed file -- even if I
;; run the diff somewhere other than at the root of my repo.
(defun gmd-around-magit-diff(orig-fun &rest args)
  (let ((default-directory (gmd-vc-root-dir)))
    (if (not default-directory)
	(message "Unable to determine version control root directory")
      (apply orig-fun args)
      (visual-line-mode)
      (setq word-wrap nil))))

(advice-add 'magit-diff :around #'gmd-around-magit-diff)

(defun gmd-magit-diff()
  (interactive)
  (gmd-around-magit-diff 'magit-diff "HEAD"))

(defun gmd-magit-diff-no-whitespace()
  (interactive)
  (gmd-around-magit-diff 'magit-diff "HEAD" "-w"))

(add-hook 'magit-diff-mode-hook
	  (lambda()
	    (local-set-key "\M-p" (lambda()
				    (interactive)
				    (scroll-down-command 1)))
	    (local-set-key "\M-n" (lambda()
				    (interactive)
				    (scroll-up-command 1)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Tinydesk

(autoload 'tinydesk-save-state "tinydesk" "doc" t)
(autoload 'tinydesk-recover-state "tinydesk" "doc" t)

(setq tinydesk--directory-location "~/tmp/emacs-tinydesk/")

; Making some aliases to make tab completion easier:
(defalias 'gmd-tinydesk-save-state 'tinydesk-save-state)
(defalias 'gmd-tinydesk-recover-state 'tinydesk-recover-state)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; WS mode
;; This strips trailing whitespace and converts tabs to spaces on
;; lines that are modified.

(require 'ws-trim)
(global-ws-trim-mode t)
(set-default 'ws-trim-level 0)
(setq ws-trim-global-modes '(guess (not message-mode eshell-mode)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SQL

;; Rename the SQL buffer to include user and DB name -- even if it is
;; the only SQL buffer.
(add-hook 'sql-interactive-mode-hook 'sql-rename-buffer)

(defun my-sql-save-history-hook ()
  (let ((lval 'sql-input-ring-file-name)
	(rval 'sql-product))
    (if (symbol-value rval)
	(let ((filename
	       (concat "~/.emacs.d/sql/"
		       (symbol-name (symbol-value rval))
		       "-history.sql")))
	  (set (make-local-variable lval) filename))
      (error
       (format "SQL history will not be saved because %s is nil"
	       (symbol-name rval))))))
(add-hook 'sql-interactive-mode-hook 'my-sql-save-history-hook)

(defun gmd-format-sql ()
  "Format SQL queries"
  (interactive)
  (save-excursion
    (while (re-search-forward "\\\(\\<left\\>\\\|\\<from\\>\\\|\\<where\\>\\\|\\<values\\>\\\|\\<group by\\>\\\|\\<values\\>\\\|\\<order by\\>\\\|\<left outer join\\\)" nil t)
      (replace-match "\n\\1")))
  (save-excursion
    (while (re-search-forward "\\\(\\<and\\>\\\)" nil t)
      (replace-match "\n\t\\1"))))

(defun eat-sqlplus-junk (str)
  "Eat the line numbers SQL*Plus returns.
    Put this on `comint-preoutput-filter-functions' if you are
    running SQL*Plus.

    If the line numbers are not eaten, you get stuff like this:
    ...
      2    3    4       from v$parameter p, all_tables u
	      *
    ERROR at line 2:
    ORA-00942: table or view does not exist

    The mismatch is very annoying."
  (interactive "s")
  (while (string-match " [ 1-9][0-9]  " str)
    (setq str (replace-match "" nil nil str)))
  str)
(defun install-eat-sqlplus-junk ()
  "Install `comint-preoutput-filter-functions' if appropriate.
    Add this function to `sql-interactive-mode-hook' in your .emacs:
    \(add-hook 'sql-mode-hook 'install-eat-sqlplus-junk)"
      (add-to-list 'comint-preoutput-filter-functions
		   'eat-sqlplus-junk))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set up default modes for different file types
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq auto-mode-alist '()) ;; so fundamental-mode will be default

(setq auto-mode-alist (cons '("[Mm]akefile" . makefile-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.mk$" . makefile-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.ps$" . postscript-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.t$" . perl-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.pl$" . perl-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.PL$" . perl-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.pm$" . perl-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.cgi$" . perl-mode) auto-mode-alist))

(autoload 'markdown-mode "markdown-mode")
(setq auto-mode-alist (cons '("\\.md$" . markdown-mode) auto-mode-alist))

(autoload 'puppet-mode "puppet-mode")
(setq auto-mode-alist (cons '("\\.pp$" . puppet-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.sh$" . sh-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.bash[^/]*" . sh-mode) auto-mode-alist))

(autoload 'web-mode "web-mode") ; https://github.com/fxbois/web-mode
(setq auto-mode-alist (cons '("\\.php$" . web-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.erb$" . web-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.rb$" . ruby-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.rake$" . ruby-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("Gemfile" . ruby-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("Rakefile" . ruby-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.h$" . c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.c$" . c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.cpp$" . c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.xs$" . c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("typemap" . c++-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.java$" . java-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.js$" . javascript-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.es6$" . javascript-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.jsx$" . jsx-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.css$" . css-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.m$" . html-mode) auto-mode-alist))

(autoload 'clojure-mode "clojure-mode")
(setq auto-mode-alist (cons '("\\.clj$" . clojure-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.emacs$" . emacs-lisp-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.el$" . emacs-lisp-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.elc$" . emacs-lisp-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.xml$" . nxml-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.tld$" . nxml-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.jsp$" . nxml-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.tag$" . nxml-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.xslt$" . nxml-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.wsdl$" . nxml-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.asdl$" . nxml-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.xsd$" . nxml-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.sql$" . sql-mode) auto-mode-alist))

(setq interpreter-mode-alist '())

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Settings for GUI mode:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq mouse-yank-at-point t)

; Disable the mouse
(dolist (k '([mouse-1] [down-mouse-1] [drag-mouse-1] [double-mouse-1] [triple-mouse-1]
	     [mouse-2] [down-mouse-2] [drag-mouse-2] [double-mouse-2] [triple-mouse-2]
	     [mouse-3] [down-mouse-3] [drag-mouse-3] [double-mouse-3] [triple-mouse-3]
	     [mouse-4] [down-mouse-4] [drag-mouse-4] [double-mouse-4] [triple-mouse-4]
	     [mouse-5] [down-mouse-5] [drag-mouse-5] [double-mouse-5] [triple-mouse-5]))
  (global-unset-key k))

;;(set-specifier menubar-visible-p nil)
(if (string-match "XEmacs" emacs-version)
    (set-specifier default-toolbar-visible-p nil))
(tool-bar-mode -1)

; get rid of the menu bar
(if menu-bar-mode
    (menu-bar-mode -1))

(if (fboundp 'scroll-bar-mode)
    (scroll-bar-mode -1))

;; Make emacs share the copy/paste clipboard that everything else uses.
(if (boundp 'x-select-enable-clipboard)
    (progn
      (setq x-select-enable-clipboard t)
      (setq interprogram-paste-function 'x-cut-buffer-or-selection-value)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Misc settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Used by M-x diff (override them using C-u M-x diff):
(setq diff-switches "-U5")

(show-paren-mode 1)

(setq read-buffer-completion-ignore-case 't)
(setq read-file-name-completion-ignore-case 't)
(setq line-move-visual nil)

(setq split-height-threshold nil)
(setq split-width-threshold most-positive-fixnum)

; Stop emacs from asking if I want to follow the symlink.
(setq vc-follow-symlinks 't)

; Fix Esc-/ so it honors case:
(setq dabbrev-case-replace nil)
(setq dabbrev-case-fold-search nil)

(setq enable-recursive-minibuffers 't)

(setq line-number-mode 1)
(setq explicit-shell-file-name "bash")
(setq inhibit-startup-message 't)
(setq next-line-add-newlines 'nil)
(setq next-screen-context-lines 1)
(setq scroll-step 1)
(setq minibuffer-electric-file-name-behavior nil)

;; Wrap lines instead of truncating them with a '$' (when splitting windows vertically)
(setq truncate-partial-width-windows nil)

;; Keep ESC-q from indenting every line of a paragraph.
(setq adaptive-fill-mode nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Misc functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun gmd-chomp (str)
  (if (and str (string-match "[\n\t\s]+\\'" str))
      (replace-match "" t t str)
    str))

(defun gmd-shell-command-to-string(command)
  (with-temp-buffer
    (if	(= 0 (call-process-shell-command command nil (current-buffer)))
	(buffer-string)
      nil)))

;; I thought join-lines was a built in??? Anyway it dissappeared.  I
;; wish emacs lisp had a good namespacing system.
(defun join-lines(not-used)
  (end-of-line)
  (if (not (eobp))
      (progn (delete-char 1)
	     (delete-horizontal-space)
	     (insert " "))))

(defun join-with-next-line()
  ""
  (interactive)
  ;; the argument makes it join with the next one instead of the previous one.
  (join-lines 't))

(defun gmd-ucase-first-character()
  (interactive)
  (save-excursion
    (let ((char-to-ucase (buffer-substring (point) (+ 1 (point)))))
      (delete-char 1)
      (insert (upcase char-to-ucase)))))

;; I can't get byte-compile-directory to work.
(defun gmd-byte-compile-directory()
  ""
  (interactive)
  (gmd-internal-byte-compile-files
   (directory-files
    (read-file-name "Directory name: ")
    't
    ".el$")))
(defun gmd-internal-byte-compile-files (files)
  (if (> (length files) 0)
      (progn
	  (byte-compile-file (car files))
	  (gmd-internal-byte-compile-files (cdr files)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Functions tied to a language
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun perl-script-start()
  "create the start of a perl script"
  (interactive)
  (insert "#!/opt/third-party/bin/perl -w
#-*-Perl-*-

use strict;

sub get_options {
    use Amazon::Content::CommandLineOptions ();

    my (%options);
    Amazon::Content::CommandLineOptions::get_options
	( { },
	  \%options,
	  \"\"
	);

    return \%options;
}
")
  (perl-mode))

(defun my-cperl-setup()
  "old indentation for editing old files"
  (interactive)
  (setq tab-width 3)
  (setq cperl-continued-statement-offset 3)
  (setq cperl-brace-offset -3)
  (setq cperl-label-offset -3)
  (setq cperl-indent-level 3))

(defun two-space-c-mode()
  "switch indentation to two-spaces"
  (interactive)
  (setq c-basic-offset 2))

(defun no-coloring ()
  "switch indentation to two-spaces"
  (interactive)
  (set-face-foreground 'font-lock-comment-face "black")
  (set-face-foreground 'font-lock-function-name-face "black")
  (set-face-foreground 'font-lock-keyword-face "black")
  (set-face-foreground 'font-lock-variable-name-face "black")

  (set-face-foreground 'font-lock-other-type-face "black")
  (set-face-foreground 'font-lock-type-face "black")
  (set-face-foreground 'font-lock-type-face "black")
  (set-face-foreground 'font-lock-doc-string-face "black")
  (set-face-foreground 'font-lock-string-face "black")

  (set-face-foreground 'font-lock-preprocessor-face "black")
  (set-face-foreground 'font-lock-reference-face "black")
  (set-face-foreground 'font-lock-warning-face "black"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Mode hooks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Can't set these in buffer-menu-mode-hook because it renders the menu
; before our hook.  Can't use (buffer-menu-toggle-mode-column) because
; that causes an infinite loop (it calls (buffer-menu)).
(setq Buffer-menu-buffer+size-width 100)
(setq Buffer-menu-time-flag nil)
(setq Buffer-menu-mode-flag nil)

(autoload 'robe-mode "robe")
(add-hook 'robe-mode
	  (lambda()
	    ;; robe overrides M-,
	    (define-key robe-mode-map (kbd "M-,") 'tags-loop-continue)))

(add-hook 'ruby-mode-hook 'robe-mode)
(add-hook 'ruby-mode-hook 'rubocop-mode)

(autoload 'enable-paredit-mode "paredit" nil t)
(add-hook 'clojure-mode-hook 'enable-paredit-mode)
(add-hook 'emacs-lisp-mode-hook 'enable-paredit-mode)
(add-hook 'cider-repl-mode-hook
	  (lambda ()
	    (enable-paredit-mode)
	    (local-set-key (kbd "C-j") 'cider-repl-return)))

(eval-after-load 'paredit
  (lambda ()
    ;; C-2 doesn't work on Windows.
    (define-key paredit-mode-map (kbd "C-0") 'paredit-forward-slurp-sexp)
    (define-key paredit-mode-map (kbd "C-9") 'paredit-forward-barf-sexp)
    (define-key paredit-mode-map (kbd "M-0") 'paredit-forward-slurp-sexp)
    (define-key paredit-mode-map (kbd "M-9") 'paredit-forward-barf-sexp)
    (define-key paredit-mode-map (kbd "C-1") 'paredit-backward-slurp-sexp)
    (define-key paredit-mode-map (kbd "C-2") 'paredit-backward-barf-sexp)
    (define-key paredit-mode-map (kbd "M-1") 'paredit-backward-slurp-sexp)
    (define-key paredit-mode-map (kbd "M-2") 'paredit-backward-barf-sexp)
    (define-key paredit-mode-map (kbd "C-j") nil)))

(add-hook 'markdown-mode-hook
	  (lambda()
	    ;; Override markdown mode's bindings:
	    (local-set-key "\M-p" (lambda()
				    (interactive)
				    (scroll-down-command 1)))
	    (local-set-key "\M-n" (lambda()
				    (interactive)
				    (scroll-up-command 1)))))

(add-hook 'after-init-hook #'global-flycheck-mode)

(add-hook 'web-mode-hook
	  (function (lambda()
		      (setq web-mode-markup-indent-offset 2)
		      (setq web-mode-css-indent-offset 2)
		      (setq web-mode-code-indent-offset 2)
		      )))

(add-hook 'buffer-menu-mode-hook
	  (function (lambda()
		      (font-lock-mode -1))))

(add-hook 'mmm-mason-class-hook
	  (lambda()
	    (setq indent-tabs-mode nil)))


(add-hook 'sql-interactive-mode-hook 'install-eat-sqlplus-junk)

(add-hook 'sql-mode-hook
	  (function (lambda()
		      (font-lock-mode))))

(add-hook 'sql-interactive-mode-hook
	  (function (lambda()
		      ;(setq comint-prompt-regexp "^SQL>|^[a-z_]+@[a-z\\.]+>")
		      (font-lock-mode))))

(add-hook 'text-mode
	  (function (lambda()
		      (setq indent-tabs-mode 't))))

(add-hook 'html-mode-hook
	  (function (lambda()
		      (font-lock-mode)
		      (setq sgml-indent-step 4)
		      )))

(add-hook 'nxml-mode-hook
	  (function (lambda()
		      (font-lock-mode)
		      (setq nxml-child-indent 4)
		      )))

(add-hook 'postscript-mode-hook
	  (function (lambda()
		      (font-lock-mode)
		      (setq ps-indent-level 4)
		      )))

(add-hook 'nxml-mode-hook
	  (lambda()
	    (setq indent-tabs-mode nil)))


(add-hook 'js-mode-hook
	  (function (lambda()
		      (font-lock-mode)
		      (setq js-indent-level 2)
		      (setq indent-tabs-mode nil)
		      )))

(add-hook 'java-mode-hook
	  (function (lambda()
		      (c-set-style "java")
		      (c-set-offset 'arglist-intro 'c-lineup-whitesmith-in-block)
		      (c-set-offset 'innamespace 0 nil)
		      (font-lock-mode)
		      (setq c-basic-offset 4)
		      (c-set-offset 'substatement-open 0)
		      (c-set-offset 'case-label 4)
		      (setq indent-tabs-mode nil)
		      (setq show-trailing-whitespace nil)
		      ;; The next two lines are a hack to make
		      ;; annotations indent correctly:
		      (setq c-comment-start-regexp "(@|/(/|[*][*]?))")
		      (modify-syntax-entry ?@ "< b" java-mode-syntax-table)
		      )))

(defun gmd-indent-buffer()
  (interactive "")
  (untabify (point-min) (point-max))
  (indent-region (point-min) (point-max) nil)
)

(defun gmd-indent-test-buffer()
  (interactive "")
  (gmd-indent-buffer)
  (replace-string "    public" "public" nil (point-min) (point-max))
)

(defun natalien-java-mode()
  ""
  (interactive)
  (setq indent-tabs-mode 't)
  (setq c-basic-offset 8)
  (setq tab-width 8)
)
(defun jameyer-java-mode()
  ""
  (interactive)
  (setq indent-tabs-mode 't)
  (setq c-basic-offset 4)
  (setq tab-width 4)
)
(defun bradheld-c-mode()
  ""
  (interactive)
  (setq c-basic-offset 8)
  (setq tab-width 8)
  (setq indent-tabs-mode 't));

(defun aperry-c-mode()
  ""
  (interactive)
  (setq tab-width 4)
  (setq c-basic-offset 4)
  (setq indent-tabs-mode 't))

(add-hook 'c++-mode-hook
	  (function (lambda ()
		      (hs-minor-mode)
		      (font-lock-mode)
		      (setq indent-tabs-mode nil
			    c-default-style "user"
			    c-basic-offset 4)
		      (c-set-offset 'substatement-open '0)
		      (c-set-offset 'inline-open '0)
		      (define-key c-mode-base-map "" 'backward-kill-word)
		     ;(define-key c-mode-base-map [(escape backspace)] 'backward-kill-word)
)))

(add-hook 'c-mode-hook
	  (function (lambda ()
		      (font-lock-mode)
)))

(defun gmd-perl-mode-hook()
	 (font-lock-mode 't)
	  (setq indent-tabs-mode nil)
	 (setq tab-width 8)
	 (setq cperl-continued-statement-offset 4)
	 (setq cperl-brace-offset -4)
	 (setq cperl-label-offset -4)
	 (setq cperl-indent-level 4)
	 (cperl-define-key "\C-h" 'backward-delete-char)
	 (cperl-define-key "\C-j" 'set-mark-command)
	 (set-face-foreground 'cperl-array-face "black")
	 (set-face-foreground 'cperl-hash-face "black")
	 (set-face-background 'cperl-hash-face "white")
	 (set-face-background 'cperl-array-face "white")
)
(setq cperl-mode-hook
      '(lambda()
	 (gmd-perl-mode-hook)))
(setq perl-mode-hook
      '(lambda()
	 (gmd-perl-mode-hook)))

(setq compilation-mode-hook
      '(lambda()
	 (font-lock-mode 1)
	 (setq compilation-scroll-output 'first-error)
	 ))

;; Make compilation mode color text based on the ANSI color control
;; characters.
(require 'ansi-color)
(defun colorize-compilation-buffer ()
  (toggle-read-only)
  (ansi-color-apply-on-region compilation-filter-start (point))
  (toggle-read-only))
(add-hook 'compilation-filter-hook 'colorize-compilation-buffer)

(setq gdb-mode-hook
      '(lambda()
	 (define-key gdb-mode-map "\M-u" 'gdb-up)
	 (define-key gdb-mode-map "\M-d" 'gdb-down)
	 ))

(add-hook 'emacs-lisp-mode-hook 'font-lock-mode)

(setq shell-script-mode-hook
      '(lambda()
	 (font-lock-mode 't)))
(setq sh-mode-hook shell-script-mode-hook)

(setq makefile-mode-hook
      '(lambda()
	 (font-lock-mode)
	 (define-key makefile-mode-map "\M-n" 'scroll-one-line-ahead)
	 (define-key makefile-mode-map "\M-p" 'scroll-one-line-behind)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; From http://www.emacswiki.org/emacs/CamelCase
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun un-camelcase-string (s &optional sep start)
  "Convert CamelCase string S to lower case with word separator SEP.
    Default for SEP is a hyphen \"-\".

    If third argument START is non-nil, convert words after that
    index in STRING."
  (let ((case-fold-search nil))
    (while (string-match "[A-Z]" s (or start 1))
      (setq s (replace-match (concat (or sep "-")
				     (downcase (match-string 0 s)))
			     t nil s)))
    (downcase s)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; From http://www.jspwiki.org/wiki/InsertingGettersAndSettersInEmacs
;; Then modified to handle case correctly
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun extract-class-name()
  (save-excursion
    (goto-char (point-min))
    (search-forward-regexp "\\<class\\>[ \t]+\\([A-Za-z0-9]+\\)")
    (match-string 1)))

(defun extract-class-variables (&rest modifiers)
  (let ((regexp
	 (concat
	  "^\\([ \t]*\\)"
	  "\\(" (mapconcat (lambda (m) (format "%S" m)) modifiers "\\|") "\\)"
	  "\\([ \t]*\\)"
	  "\\([A-Za-z0-9<>]+\\)"
	  "\\([ \t]*\\)"
	  "\\([a-zA-Z0-9]+\\);$")))
    (save-excursion
      (goto-char (point-min))
      (loop for pos = (search-forward-regexp regexp nil t)
	    while pos collect (let ((modifier (match-string 2))
				    (type (match-string 4))
				    (name (match-string 6)))
				(list modifier type name))))))

(defun generate-class-getter-setter (should-return-this
				     generate-func
				     &rest modifiers)
  (let ((oldpoint (point)))
    (insert
     (mapconcat
      (lambda (var)
	(apply generate-func should-return-this (rest var)))
      (apply 'extract-class-variables modifiers)
      "\n"))
    (c-indent-region oldpoint (point) t)))

(defun make-hibernate-hbm-properties-format (should-return-this type var)
  (let ((var-upcased (concat (upcase (substring var 0 1)) (substring var 1)))
	(hibernate-type (cond
			 ((equal type "Date") "timestamp")
			 (t (downcase type)))))
    (format (concat "<property name=\"%s\"\n"
		    "          type=\"%s\"\n"
		    "          column=\"%s\" />\n")
	    var
	    (downcase type)
	    (un-camelcase-string var "_"))))
(defun make-hibernate-hbm-properties()
  (interactive)
  (generate-class-getter-setter nil
				'make-hibernate-hbm-properties-format
				'private))

(defun make-oracle-ddl-format (should-return-this type var)
  (let ((var-upcased (concat (upcase (substring var 0 1)) (substring var 1)))
	(class-name (extract-class-name)))
    (format (concat "%s %s NOT NULL,")
	    (un-camelcase-string var "_")
	    (cond
	     ((equal type "String") "VARCHAR()")
	     ((equal type "Long") "NUMBER()")
	     ((equal type "Date") "TIMESTAMP")
	     (t type)))))
(defun make-oracle-ddl()
  (interactive)
  (generate-class-getter-setter nil
				'make-oracle-ddl-format
				'private))

(defun make-java-mutators-format (should-return-this type var)
  (let ((var-upcased (concat (upcase (substring var 0 1)) (substring var 1)))
	(class-name (extract-class-name)))
    (if should-return-this
	(format (concat "public %s get%s() {\n"
			"    return this.%s;\n"
			"}\n"
			"public %s set%s(final %s %s) {\n"
			"    this.%s = %s;\n"
			"    return this;\n"
			"}\n")
		type var-upcased var
		class-name var-upcased type var var var)
      (format (concat "public %s get%s() {\n"
		      "    return this.%s;\n"
		      "}\n"
		      "public void set%s(final %s %s) {\n"
		      "    this.%s = %s;\n"
		      "}\n")
	      type var-upcased var
	      var-upcased type var var var))))
(defun make-java-mutators(should-return-this)
  (interactive (list (yes-or-no-p "Should setters return 'this'? ")))
  (generate-class-getter-setter should-return-this
				'make-java-mutators-format
				'private))

(defun make-java-builders-format (should-return-this-not-used type var)
  (let ((var-upcased (concat (upcase (substring var 0 1)) (substring var 1)))
	(class-name (extract-class-name)))
    (format (concat "@Override\n"
		    "public void set%s(final %s %s) {\n"
		    "    getCurrentProduct().set%s(%s);\n"
		    "}\n")
	    var-upcased type var var-upcased var)))
(defun make-java-builders()
  (interactive)
  (generate-class-getter-setter nil
				'make-java-builders-format
				'private))


;; My manual version
(defun make-java-mutator(variable-type variable-name)
  "Makes a java getter and setter"
  (interactive "sType: \nsName: \n")
  (insert (concat "    public " variable-type " get" (upcase (substring variable-name 0 1)) (substring variable-name 1) "() {\n"
		  "        return " variable-name ";\n"
		  "    }\n"
		  "    public void set" (upcase (substring variable-name 0 1)) (substring variable-name 1) "(final " variable-type " " variable-name ") {\n"
		  "        this." variable-name " = " variable-name ";\n"
		  "    }\n"
)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Define macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fset 'gmd-tab "   ")
(fset 'gmd-whack-leading-space-then-go-down
      "\C-a\\\C-n")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Key mappings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(global-set-key "\M-'" 'search-again)
(global-set-key "\M-g" 'goto-line)
(global-set-key "\C-s" 'isearch-forward-regexp)
(global-set-key "\C-r" 'isearch-backward-regexp)

(define-key text-mode-map (kbd "TAB") 'self-insert-command)

(define-key ctl-x-map "V" (lambda()
			    (interactive)
			    (revert-buffer t (not (buffer-modified-p)) nil)))
(global-set-key "\M-p" (lambda()
			 (interactive)
			 (scroll-down-command 1)))
(global-set-key "\M-n" (lambda()
			 (interactive)
			 (scroll-up-command 1)))

(normal-erase-is-backspace-mode 0)

(defvar ctl-x-6-map (make-sparse-keymap) "")
(define-key ctl-x-map "6" 'ctl-x-6-prefix)
(fset 'ctl-x-6-prefix ctl-x-6-map)
(define-key ctl-x-6-map "r" 'recompile)
(define-key ctl-x-6-map "c" 'compile)

;(define-key p4-prefix-map "r" 'gmd-p4-revert)
;(define-key p4-prefix-map "e" 'gmd-p4-edit)
;(define-key p4-prefix-map "=" 'gmd-p4-diff)

(define-key global-map "\C-t" 'join-with-next-line)
(define-key global-map "\C-h" 'backward-delete-char)
(global-set-key "\C-h" 'backward-delete-char)
(define-key global-map "OR" 'gmd-whack-leading-space-then-go-down) ; f3
(define-key ctl-x-map "w" 'save-buffer)
(define-key ctl-x-map "c" 'quoted-insert)
(define-key ctl-x-map "?" 'help-for-help)
(define-key ctl-x-map ">" 'replace-regexp)
(define-key esc-map "i" 'gmd-ucase-first-character)
(define-key esc-map "s" 'isearch-forward-regexp)
(define-key esc-map "\C-h" 'backward-kill-word)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Compile & grep customizations

(add-hook 'compilation-filter-hook 'clever-cmd-ruby-byebug-compilation-filter)

; grep-null-device=nil keep M-x grep from appending "/dev/null" to the
; end of my grep commands (needs to happen before the mode hook is
; called):
(setq grep-null-device nil)

(setq grep-command "grep -nr ")
(defvar clever-cmd-ruby-mode-grep-command
  "grep -nr --include=\"*.rb\" --include=\"*.erb\" --include=\"*.rake\" ")
(defvar clever-cmd-jsx-mode-grep-command
  "grep -nr --exclude-dir generated --include=\"*.js\" --include=\"*.jsx\" --include=\"*.es6\" ")
(defvar clever-cmd-js-mode-grep-command clever-cmd-jsx-mode-grep-command)

(defun clever-cmd-ruby-mode-compile-command ()
  (concat "cd "
	  (or (gmd-vc-root-dir) ".") ; Default to current directory.
	  " && rspec  ~/config/.rspec_color.rb --format documentation %s:%l"))

(defun clever-cmd-js-mode-compile-command ()
  (concat "cd "
	  (or (gmd-vc-root-dir) ".") ; Default to current directory.
	  " && npm test run -- -- --grep 'MiniCard'"))

(advice-add 'compile :around #'clever-cmd-compile-with-smart-command)
(advice-add 'grep :around #'clever-cmd-grep-with-smart-command)

;; For eslint:
(eval-after-load "compile"
  '(add-to-list 'compilation-error-regexp-alist
		'("^\\(/[^\":\n]+\\)\n  \\([0-9]+\\):[0-9]+ +error +" 1 2)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun gmd-sql-oracle()
  "Runs sql-oracle and names the buffer after the database and user"
  (interactive)
  (setenv "SQLPATH" (expand-file-name "~/local/sql"))
  ;(setenv "TNS_ADMIN" (expand-file-name ""))
  (setenv "ORACLE_HOME" "/opt/app/oracle/product/10.2.0.2/client")
  (sql-oracle)
  (rename-buffer (concat "*SQL* " sql-database " " sql-user)))

(defun gmd-sql-rds()
  "Runs sql-oracle and names the buffer after the database and user"
  (interactive)
  (setenv "SQLPATH" (expand-file-name "~/local/sql"))
  (setenv "TNS_ADMIN" (expand-file-name "/opt/disco/lsd/lsd-data/tnsnames/desktop/"))
  (setenv "ORACLE_HOME" "/opt/app/oracle/product/10.2.0.2/client")
  (let ((sql-oracle-program (expand-file-name "~/local/bin/sqlplus-tvndrprf"))
	(sql-user "receivept")
	(sql-password "foo"))
    (sql-oracle)
    (rename-buffer (concat "*SQL* " sql-database " " sql-user))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; From stevey@

(defun show-kill-ring ()
  "Shows the current contents of the kill ring in a separate buffer.
This makes it easy to figure out which prefix to pass to yank."
  (interactive)
  (let* ((buf (get-buffer-create "*Kill Ring*"))
	 (temp kill-ring)
	 (count 1)
	 (bar (make-string 32 ?=))
	 (bar2 (concat " " bar))
	 (item "  Item ")
	 (yptr nil) (ynum 1))

    (set-buffer buf)
    (erase-buffer)

    ;; header
    (if temp
	(insert "Contents of the kill ring:\n")
      (insert "The kill ring is empty."))

    ;; show each of the items in the kill ring, in order
    (while temp

      ;; insert our little divider
      (insert (concat "\n" bar item (prin1-to-string count) "  "
		      (if (< count 10) bar2 bar) "\n"))

      ;; if this is the yank pointer target, grab it
      (if (equal temp kill-ring-yank-pointer)
	  (progn
	    (setq yptr (car temp))
	    (setq ynum count)))

      ;; insert the item and loop
      (insert (car temp))
      (setq count (1+ count))
      (setq temp (cdr temp)))

    ;; insert final divider and the yank-pointer info
    (if kill-ring
	(progn
	  (save-excursion
	    (re-search-backward "^\\(=+  Item [0-9]+\\ +=+\\)$"))
	  (insert "\n")
	  (insert (make-string (length (match-string 1)) ?=))
	  (insert (concat "\n\nItem " (int-to-string ynum)
			  " is the next to be yanked:\n\n"))
	  (insert (concat yptr "\n\n"))
	  (insert "The prefix arg will yank relative to this item.")))

    ;; show the thing
    (goto-char (point-min))
    (set-buffer-modified-p nil)
    (display-buffer buf)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun gmd-p4-changes ()
  ""
  (interactive)
  (let ((args))
    (if (not args)
	(setq args (read-string "p4 changes arguments: " "...")))
    (p4-file-change-log "changes" (list args))))

;; Overriding this function to fix the way p4.el wipes out all windows
;; and starts over with two windows horizontally split.
(defun p4-noinput-buffer-action (cmd
				 do-revert
				 show-output
				 &optional arguments preserve-buffer)
  "Internal function called by various p4 commands."
  (save-excursion
    (save-excursion
      (if (not preserve-buffer)
	  (progn
	    (get-buffer-create p4-output-buffer-name);; We do these two lines
	    (kill-buffer p4-output-buffer-name)))    ;; to ensure no duplicates
      (p4-exec-p4 (get-buffer-create p4-output-buffer-name)
		  (append (list cmd) arguments)
		  t))
    (p4-partial-cache-cleanup cmd)
    (if show-output
	(if (and
	     (eq show-output 's)
	     (= (save-excursion
		  (set-buffer p4-output-buffer-name)
		  (count-lines (point-min) (point-max)))
		1)
	     (not (save-excursion
		    (set-buffer p4-output-buffer-name)
		    (goto-char (point-min))
		    (looking-at "==== "))))
	    (save-excursion
	      (set-buffer p4-output-buffer-name)
	      (message (buffer-substring (point-min)
					 (save-excursion
					   (goto-char (point-min))
					   (end-of-line)
					   (point)))))
	  (p4-push-window-config)
	  (display-buffer p4-output-buffer-name t))))
  (if (and do-revert (p4-buffer-file-name))
      (revert-buffer t t)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; M-x customize

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(magit-item-highlight ((t nil))))
