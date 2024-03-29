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

(defun gmd-refresh-local-package-archive-contents(package-infos)
  "Load local packages (PACKAGE-INFOS) if they are not available in ELPA."
  (let ((should-refresh (or (not (boundp 'package-archive-contents))
			    (not package-archive-contents))))
    (dolist (package-info package-infos)
      (let ((package (nth 0 package-info))
	    (package-source-directory (nth 1 package-info)))
	(message (format "Checking if local package %s is available in ELPA."
			 package))
	(unless (assoc package package-archive-contents)
	  (progn
	    (package-upload-file (format "%s/%s.el"
					 package-source-directory
					 package))
	    (setq should-refresh t)))))
    (if should-refresh
	(package-refresh-contents))))

(defun gmd-install-packages(packages)
  (dolist (package packages)
    (when (not (package-installed-p package))
      (package-install package))))

(defvar gmd-package-archive-directory (expand-file-name "~/.emacs.d/gmd/"))

(autoload 'package-upload-file "package-x" "doc" t)
(with-eval-after-load "package-x"
  (setq package-archive-upload-base gmd-package-archive-directory))

(require 'package)

(add-to-list 'package-archives
	     '("melpa" . "http://stable.melpa.org/packages/"))
;; (add-to-list 'package-archives
;; 	     '("marmalade" . "http://marmalade-repo.org/packages/") t)
;; (add-to-list 'package-archives
;; 	     '("tromey" . "http://tromey.com/elpa/") t)
(add-to-list 'package-archives
	     (cons "gmd" gmd-package-archive-directory) t)

(defvar gmd-clever-cmd-package-source-directory (expand-file-name "~/projects/clever-cmd"))
(defvar gmd-local-packages
  (list (list 'clever-cmd gmd-clever-cmd-package-source-directory)
	(list 'clever-cmd-example-config gmd-clever-cmd-package-source-directory)))
(defvar gmd-remote-packages
  '(
    company
    disable-mouse
    flycheck
    graphql-mode
    json-mode
    lsp-mode
    lsp-treemacs
    lsp-ui
    magit
    markdown-mode
    nxml-mode
    paredit
    prettier-js
    protobuf-mode
    rubocop
    typescript-mode
    web-mode
    ws-butler
    yaml-mode
    zenburn-theme))

(package-initialize)
(gmd-refresh-local-package-archive-contents gmd-local-packages)
(gmd-install-packages (append (mapcar 'car gmd-local-packages) gmd-remote-packages))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set load path and load libraries
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq load-path (append load-path (list (expand-file-name "~/.emacs.d/manual"))))

(savehist-mode 1)
(autoload 'nxml-mode "nxml-mode" "doc" t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Git mode

(autoload 'magit-diff "magit" "doc" t)
(autoload 'magit-status "magit" "doc" t)
(autoload 'magit-log "magit" "doc" t)
(autoload 'magit-status "magit" "doc" t)

(global-set-key (kbd "C-x g") 'magit-status)

;; Set the default directory, so I can press enter on a line of my
;; diff buffer and it will take me to the changed file -- even if I
;; run the diff somewhere other than at the root of my repo.
(defun gmd-around-magit-diff(orig-fun &rest args)
  (let ((default-directory (clever-cmd-ec--vc-root-dir)))
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
	    (setq git-commit-fill-column 9999)
	    (local-set-key "\M-p" (lambda()
				    (interactive)
				    (scroll-down-command 1)))
	    (local-set-key "\M-n" (lambda()
				    (interactive)
				    (scroll-up-command 1)))))

(add-hook 'magit-status-mode-hook
	  (lambda()
	    (add-to-list 'magit-no-confirm 'stage-all-changes)
	    (add-to-list 'magit-no-confirm 'unstage-all-changes)
	    (setf (alist-get 'unpushed magit-section-initial-visibility-alist) 'show)
	    (setf (alist-get 'unpulled magit-section-initial-visibility-alist) 'show)
	    (setf (alist-get 'stashes magit-section-initial-visibility-alist) 'show)
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

(setq tinydesk--directory-location "~/.emacs-tinydesk/")

; Making some aliases to make tab completion easier:
(defalias 'gmd-tinydesk-save-state 'tinydesk-save-state)
(defalias 'gmd-tinydesk-recover-state 'tinydesk-recover-state)

(defun gmd-tinydesk-recover-state-by-name (name)
  "Load state from NAME then kill the Tinydesk buffer with all the files."
  (tinydesk-recover-state (format "~/.emacs-tinydesk/%s" name))
  (switch-to-buffer name)
  (set-buffer-modified-p nil)
  (kill-buffer))

(defun gmd-tinydesk-recover-state-all ()
  "For use with -f FUNCTION-NAME."
  (interactive)
  (gmd-tinydesk-recover-state-by-name "all"))

(defun gmd-tinydesk-recover-state-yellowleaf-trips ()
  "For use with -f FUNCTION-NAME."
  (interactive)
  (gmd-tinydesk-recover-state-by-name "yellowleaf-trips"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SQL

;; Rename the SQL buffer to include user and DB name -- even if it is
;; the only SQL buffer.
(add-hook 'sql-interactive-mode-hook 'sql-rename-buffer)

(defun my-sql-save-history-hook()
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

(defun gmd-refactor-1 ()
  "CORE-13436"
  (interactive)
  (progn
    (goto-char (point-min))
    (insert " ") ;; run Prettier
    (save-buffer)

    ;; M-x global-disable-mouse-mode

    ;; First do the ones that end in two newlines
    (goto-char (point-min))
    (while (re-search-forward "[a-zA-Z0-9]+\\.set\\([A-Z]\\)\\([A-Za-z]+\\)([\n ]*\\(.+\\)[\n ]*);\n\n"  nil t)
      (replace-match (concat (downcase (match-string 1)) (match-string 2) ": " (match-string 3) ",})\n\n")) )

    (goto-char (point-min))
    (while (re-search-forward "[a-zA-Z0-9]+\\.set\\([A-Z]\\)\\([A-Za-z]+\\)([\n ]*\\(.+\\)[\n ]*);"  nil t)
      (replace-match (concat (downcase (match-string 1)) (match-string 2) ": " (match-string 3) ",")) )

    (goto-char (point-min))
    (while (re-search-forward "\\(const \\)?\\([a-zA-Z]+\\): \\([A-Za-z]+\\) = {};"  nil t)
      (if (not (string-match "Histor" (match-string 2)))
	  (replace-match "\\1\\2 = \\3Factory.build({"))
      )

    ;; *History *Histories
    (goto-char (point-min))
    (while (re-search-forward "\\(const \\)?\\([a-zA-Z]+\\): \\([A-Za-z]+\\) = {};"  nil t)
      (replace-match "\\1\\2: \\3 = {")
      )

    (goto-char (point-min))
    (while (re-search-forward "batch"  nil t)
      (replace-match "batch"))

    (goto-char (point-min))
    (while (re-search-forward "WrapperFactory.build({"  nil t)
      (replace-match "WrapperFactory.build({")
      )

    (goto-char (point-min))
    (while (re-search-forward "new \\(Command\\|Designation\\|Desk\\|Employee\\|Floor\\|Move\\|Room\\|SeatAvailabilit\\|Site\\|User\\)\\(\\w+\\)()"  nil t)
      (replace-match "\\1\\2Factory.build()")
      )

    )
  )


(defun gmd-refactor-2 ()
  "CORE-13436."
  (interactive)
  (progn
    ;; M-x global-disable-mouse-mode

    (goto-char (point-min))
    (query-replace-regexp
     "\\([a-zA-Z]*\\([wW]rapper\\|[wW]rapped\\)[a-zA-Z0-9]*\\??\\)\\.\\(users?\\|commands?\\|designations?\\|employees?\\|moves?\\|users?\\|sites?\\|floors?\\|rooms?\\|desks?\\|logHistoryRequested\\|deskBookings?\\|shifts?\\|deskShifts?\\|seats?\\|seatAvailability\\|seatAvailabilities\\)\\(MovedToRoom\\|Bound\\|Unbound\\|Created\\|Updated\\|Scheduled\\|Deleted\\|Migrated\\|Promoted\\|Demoted\\|Approved\\|Canceled\\|Completed\\|Declined\\|Requested\\|Commands\\)"
     "\\1.message?.$case === \"\\3\\4\""
     )

    (goto-char (point-min))
    (while (re-search-forward "\\([a-zA-Z]*\\([wW]rapper\\|[wW]rapped\\)[a-zA-Z0-9]*\\??\\)\\.\\(users?\\|commands?\\|designations?\\|employees?\\|moves?\\|users?\\|sites?\\|floors?\\|rooms?\\|desks?\\|logHistoryRequested\\|deskBookings?\\|shifts?\\|deskShifts?\\|seats?\\|seatAvailability\\|seatAvailabilities\\)\\(MovedToRoom\\|Bound\\|Unbound\\|Created\\|Updated\\|Scheduled\\|Deleted\\|Migrated\\|Promoted\\|Demoted\\|Approved\\|Canceled\\|Completed\\|Declined\\|Requested\\|Commands\\)" nil t)
      (replace-match (concat (match-string 1) ".message." (match-string 3) (match-string 4)))
      )
    )
  )


(defun gmd-refactor-unfactory-history ()
  "CORE-13436."
  (interactive)
  (progn
    (goto-char (point-min))
  (while (re-search-forward "const \\(\\w+\\)\s*=\s*\\(\\w+History\\)Factory\.build({" nil t)
      (replace-match "const \\1: \\2 = {"))
    )
  )

(defun gmd-format-sql()
  "Format SQL queries"
  (interactive)
  (save-excursion
    (while (re-search-forward "\\\(\\<left\\>\\\|\\<from\\>\\\|\\<where\\>\\\|\\<values\\>\\\|\\<group by\\>\\\|\\<values\\>\\\|\\<order by\\>\\\|\\<inner join\\>\\\|\\<left outer join\\\)" nil t)
      (replace-match "\n\\1")))
  (save-excursion
    (while (re-search-forward "\\\(\\<and\\>\\\|\\<on\\>\\\)" nil t)
      (replace-match "\n\t\\1"))))

(defun eat-sqlplus-junk(str)
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
(defun install-eat-sqlplus-junk()
  "Install `comint-preoutput-filter-functions' if appropriate.
    Add this function to `sql-interactive-mode-hook' in your .emacs:
    \(add-hook 'sql-mode-hook 'install-eat-sqlplus-junk)"
      (add-to-list 'comint-preoutput-filter-functions
		   'eat-sqlplus-junk))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set up default modes for different file types
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq auto-mode-alist (cons '("[Mm]akefile" . makefile-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.mk$" . makefile-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.ps$" . postscript-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.proto$" . protobuf-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.t$" . perl-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.pl$" . perl-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.PL$" . perl-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.pm$" . perl-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.cgi$" . perl-mode) auto-mode-alist))

(autoload 'markdown-mode "markdown-mode")
(setq auto-mode-alist (cons '("\\.md$" . markdown-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.sh$" . sh-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.bash[^/]*" . sh-mode) auto-mode-alist))

(autoload 'web-mode "web-mode") ; https://github.com/fxbois/web-mode
(setq auto-mode-alist (cons '("\\.php$" . php-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.erb$" . web-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.es6$" . web-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.jsx$" . web-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.js$" . web-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.tsx$" . web-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.graphql$" . graphql-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.rbs$" . rbs-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.rb$" . ruby-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.rake$" . ruby-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("Gemfile" . ruby-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("Rakefile" . ruby-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.h$" . c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.c$" . c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.cpp$" . c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.xs$" . c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("typemap" . c++-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.yml$" . yaml-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.yaml$" . yaml-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.java$" . java-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.json$" . json-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.css$" . css-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.m$" . html-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.html$" . web-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.emacs$" . emacs-lisp-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.el$" . emacs-lisp-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\<Cask$" . emacs-lisp-mode) auto-mode-alist))
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Settings for GUI mode:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq mouse-yank-at-point t)

(global-disable-mouse-mode)

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
    (setq x-select-enable-clipboard t))
(if (boundp 'x-cut-buffer-or-selection-value)
    (setq interprogram-paste-function 'x-cut-buffer-or-selection-value))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Misc settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(ws-butler-global-mode)

(load-theme `zenburn t)

;; Disable emacs beeping
(setq visible-bell t)

(defun gmd-prettify ()
  "Run linter."
  (interactive)
  (rubocop-autocorrect-current-file))

(defun query-replace-regexp-json-to-ruby (start end)
  "Convert JSON to Ruby between START and END."
  (interactive "r")
  (save-excursion
    (if (= start end)
	(message "Select a region")
      (save-excursion
	(replace-regexp "\"\\([[:alnum:]_]+\\)\":" "\\1:"
			nil
			start
			end)
	(replace-regexp "\"" "'"
			nil
			start
			end)
	(indent-region start end)
	(untabify start end)
      ))))

;; Buffers that should be opened in the current window:
(add-to-list 'same-window-regexps "*Buffer List*")
(add-to-list 'same-window-regexps "*magit")
(add-to-list 'same-window-regexps "magit: ")
(add-to-list 'same-window-regexps "*rails console*")

;; Because I can't get Karma to ignore .#*Spec.es6 files.  :(
(setq create-lockfiles nil)

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

(defun gmd-console-log-json ()
  "Insert Javascript to log JSON."
  (interactive)
  (insert "console.log(JSON.stringify(, null, 2));")
  (backward-char 12))

(defun sort-lines-nocase ()
  "Case-insensitive line sorting."
  (interactive)
  (let ((sort-fold-case t))
    (call-interactively 'sort-lines)))

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

(defun gmd-lcase-first-character()
  (interactive)
  (save-excursion
    (let ((char-to-ucase (buffer-substring (point) (+ 1 (point)))))
      (delete-char 1)
      (insert (downcase char-to-ucase)))))

;; I can't get byte-compile-directory to work.
(defun gmd-byte-compile-directory()
  ""
  (interactive)
  (gmd-internal-byte-compile-files
   (directory-files
    (read-file-name "Directory name: ")
    't
    ".el$")))
(defun gmd-internal-byte-compile-files(files)
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

(defun no-coloring()
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

(add-hook 'after-init-hook 'inf-ruby-switch-setup)

(add-hook 'web-mode-hook
	  (lambda()
	    (if (string-match "\\.\\(tsx\\)$" (buffer-file-name))
		(gmd-setup-typescript))
	    (if (string-match "\\.\\(js\\|jsx\\|tsx\\)$" (buffer-file-name))
		(prettier-js-mode))))

(add-hook 'ruby-mode-hook 'rubocop-mode)
(add-hook 'ruby-mode-hook #'lsp) ;; gem install solargraph
(add-hook 'ruby-mode-hook
	  (lambda ()
	    ;; Nice idea, but it is too slow even with the Rubocop daemon.
	    ;; gem install rubocop-daemon
	    ;; rubocop-daemon start
	    ;; (setq rubocop-autocorrect-command "rubocop-daemon exec -- -a --format emacs")
	    ;; (setq rubocop-prefer-system-executable 't)
	    ;; (setq rubocop-autocorrect-on-save 't)
;;	    (flycheck-add-next-checker 'ruby-rubocop 'lsp  'append)
	    (setq rubocop-autocorrect-command "bin/rubocop -a --format emacs")
	    (setq rubocop-prefer-system-executable 't)
	    (setq ruby-insert-encoding-magic-comment nil)))

(autoload 'enable-paredit-mode "paredit" nil t)
(add-hook 'emacs-lisp-mode-hook 'enable-paredit-mode)

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

;; Hack note: I had to create ~/local/bin/eslint-hack to get flycheck to
;; use the eslint from package.json.
(add-hook 'after-init-hook #'global-flycheck-mode)
(eval-after-load "flycheck"
  '(progn
     (setq-default flycheck-disabled-checkers
		   (append flycheck-disabled-checkers '(javascript-jshint)))
     (flycheck-add-mode 'javascript-eslint 'web-mode)
     (setq flycheck-shellcheck-follow-sources nil)
     (setq flycheck-check-syntax-automatically (quote (idle-change)))
     (setq flycheck-javascript-eslint-executable
	   (concat (clever-cmd-ec--vc-root-dir) "node_modules/eslint/bin/eslint.js"))
     (setq flycheck-eslintrc (concat (clever-cmd-ec--vc-root-dir) ".eslintrc.js"))))


;; This variable must be defined before web-mode is autoloaded in
;; order for the first file to be recognized correctly.
(setq web-mode-content-types-alist '(("jsx" . "\\.js\\'")))
(add-hook 'web-mode-hook
	  (function (lambda()
		      (setq web-mode-enable-auto-quoting nil)
		      (setq web-mode-enable-auto-indentation nil)
		      (setq web-mode-markup-indent-offset 2)
		      (setq web-mode-attr-indent-offset nil)
		      (setq web-mode-css-indent-offset 2)
		      (setq indent-tabs-mode nil)
		      (setq web-mode-code-indent-offset 2)
		      )))

(defun gmd-setup-typescript ()
  (flycheck-mode +1)
  (eldoc-mode +1)
  (company-mode +1)
  (setq indent-tabs-mode nil)
  (setq typescript-indent-level 2)
  (prettier-js-mode)
  (lsp)
  (flycheck-add-next-checker 'lsp 'javascript-eslint  'append)
)

(require 'company)
(add-hook 'typescript-mode-hook 'gmd-setup-typescript)

(add-hook 'graphql-mode-hook
	  (lambda ()
	    (prettier-js-mode)))

(add-hook 'json-mode-hook
	  (lambda ()
	    (prettier-js-mode)))

(add-hook 'markdown-mode-hook
	  (lambda ()
	    (prettier-js-mode)
	    (setq indent-tabs-mode nil)))

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
		      (setq sgml-indent-step 4))))

(add-hook 'nxml-mode-hook
	  (function (lambda()
		      (font-lock-mode)
		      (setq nxml-child-indent 4))))

(add-hook 'postscript-mode-hook
	  (function (lambda()
		      (font-lock-mode)
		      (setq ps-indent-level 4))))

(add-hook 'nxml-mode-hook
	  (lambda()
	    (setq indent-tabs-mode nil)))


(add-hook 'js-mode-hook
	  (function (lambda()
		      (font-lock-mode)
		      (setq js-indent-level 2)
		      (setq indent-tabs-mode nil))))

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
		      (modify-syntax-entry ?@ "< b" java-mode-syntax-table))))

(defun gmd-indent-buffer()
  (interactive "")
  (untabify (point-min) (point-max))
  (indent-region (point-min) (point-max) nil)
)

(defun gmd-indent-test-buffer()
  (interactive "")
  (gmd-indent-buffer)
  (replace-string "    public" "public" nil (point-min) (point-max)))

(defun natalien-java-mode()
  ""
  (interactive)
  (setq indent-tabs-mode 't)
  (setq c-basic-offset 8)
  (setq tab-width 8))
(defun jameyer-java-mode()
  ""
  (interactive)
  (setq indent-tabs-mode 't)
  (setq c-basic-offset 4)
  (setq tab-width 4))
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
		      (cwarn-mode)
		      (setq indent-tabs-mode nil
			    c-default-style "user"
			    c-basic-offset 4)
		      (c-set-offset 'substatement-open '0)
		      (c-set-offset 'inline-open '0)
		      (define-key c-mode-base-map "" 'backward-kill-word))))

(add-hook 'c-mode-hook
	  (function (lambda ()
		      (font-lock-mode))))

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
	 (set-face-background 'cperl-array-face "white"))
(setq cperl-mode-hook
      '(lambda()
	 (gmd-perl-mode-hook)))
(setq perl-mode-hook
      '(lambda()
	 (gmd-perl-mode-hook)))

(setq compilation-mode-hook
      '(lambda()
	 (font-lock-mode 1)
	 (setq compilation-scroll-output 'first-error)))

(setq inf-ruby-mode-hook
      '(lambda ()
	 (setq inf-ruby-prompt-format
               (concat inf-ruby-prompt-format "\\|\\(^(rdbg) *\\)"))
	 (setq inf-ruby-first-prompt-pattern (format inf-ruby-prompt-format ">" ">"))
	 (setq inf-ruby-prompt-pattern (format inf-ruby-prompt-format "[?>]" "[\]>*\"'/`]"))))

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
	 (define-key gdb-mode-map "\M-d" 'gdb-down)))

(add-hook 'emacs-lisp-mode-hook 'font-lock-mode)

(setq shell-script-mode-hook
      '(lambda()
	 (font-lock-mode 't)))
(setq sh-mode-hook shell-script-mode-hook)
(add-hook 'sh-mode-hook #'lsp) ;; M-x lsp-install-server bash-ls

(setq makefile-mode-hook
      '(lambda()
	 (font-lock-mode)
	 (define-key makefile-mode-map "\M-n" 'scroll-one-line-ahead)
	 (define-key makefile-mode-map "\M-p" 'scroll-one-line-behind)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; From http://www.emacswiki.org/emacs/CamelCase
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun un-camelcase-string(s &optional sep start)
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

(defun extract-class-variables(&rest modifiers)
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

(defun generate-class-getter-setter(should-return-this
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

(defun make-hibernate-hbm-properties-format(should-return-this type var)
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

(defun make-oracle-ddl-format(should-return-this type var)
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

(defun make-java-mutators-format(should-return-this type var)
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

(defun make-java-builders-format(should-return-this-not-used type var)
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
		  "    }\n")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Define macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fset 'gmd-tab "   ")
(fset 'gmd-whack-leading-space-then-go-down "\C-a\\\C-n")

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
(define-key ctl-x-6-map "p" 'gmd-prettify)

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
(define-key esc-map "z" 'zap-up-to-char)

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
	(if (re-search-forward "^(byebug\\|rdbg)" nil t)
	    (progn
	      (clever-cmd-convert-to-ruby-console)
	      (make-local-variable 'clever-cmd-ruby-byebug-compilation-filter-is-done))))))

(add-hook 'compilation-filter-hook 'clever-cmd-ruby-byebug-compilation-filter)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Compile & grep customizations

; grep-null-device=nil keep M-x grep from appending "/dev/null" to the
; end of my grep commands (needs to happen before the mode hook is
; called):
(setq grep-null-device nil)

(setq grep-command "grep -nr ")

(require 'clever-cmd-example-config)

(defun gmd-get-filepath-from-jasmine-compilation-error-regexp-match()
  (concat (match-string 1) "/" (match-string 2)))

(eval-after-load "compile"
  '(progn
     ;; For RSpec:
     (add-to-list 'compilation-error-regexp-alist
		  '("^ +HTML screenshot: \\([0-9A-Za-z@_./:-]+\\.html\\)" 1 nil nil 0 1))
     (add-to-list 'compilation-error-regexp-alist
		  '("^ +\\(Image \\)?\\[?[sS]creenshot\\]?: \\(.+\\.png\\)" 2 nil nil 0 2))
     (add-to-list 'compilation-error-regexp-alist
		  '("^ +# \\([0-9A-Za-z@_./:-]+\\.rb\\):\\([0-9]+\\):in" 1 2 nil 2 1))
     (add-to-list 'compilation-error-regexp-alist
		  '("^ +# \\([0-9A-Za-z@_./:-]+\\.rb\\):\\([0-9]+\\)" 1 2 nil 1 1))
     (add-to-list 'compilation-error-regexp-alist
		  '("^rspec \\([0-9A-Za-z@_./:-]+\\.rb\\):\\([0-9]+\\)" 1 2 nil 2 1))
     ;; For Jasmine:
     (add-to-list 'compilation-error-regexp-alist
		  '("\\(/[^\":\n]+\\)/[^/]+ <- webpack:///\\([^\":\n]+\\):\\([0-9]+\\):"
		    gmd-get-filepath-from-jasmine-compilation-error-regexp-match
		    3))
     ;; For Babel/Babylon JS parser:
     (add-to-list 'compilation-error-regexp-alist
		  '("SyntaxError: \\(/[^\":\n]+\\): .* (\\([0-9]+\\):[0-9]+)$" 1 2))
     ;; For eslint:
     (add-to-list 'compilation-error-regexp-alist
		  '("^\\(/[^\":\n]+\\)\n *\\([0-9]+\\):[0-9]+ +\\(error\\|warning\\) +" 1 2))))

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

(defun show-kill-ring()
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
(defalias 'gmd-show-kill-ring 'show-kill-ring)

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
(defun p4-noinput-buffer-action(cmd
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
;; OSS UI helpers

(defun gmd-start-interactive-shell-with-command (buffer-name command &optional switch-to-buffer)
  "Start an interactive shell, or switch to it if it is already running.
BUFFER-NAME - the name of the buffer running COMMAND.
COMMAND - the command the shell is started with.
SWITCH-TO-BUFFER - whether to switch to the buffer if it is already running."
  (if (get-buffer buffer-name)
      (if switch-to-buffer
	  (switch-to-buffer buffer-name))
    (let* ((default-directory (clever-cmd-ec--vc-root-dir))
	   (buffer (shell buffer-name))
	   (process (get-buffer-process buffer)))
      (ansi-color-for-comint-mode-on)
      (comint-send-string process (concat "echo Starting...;" command "\n")))))

(defun gmd-kill-buffer-unconditionally (buffer-name)
  "Kill BUFFER-NAME without prompting for confirmation."
  (if (get-buffer buffer-name)
      (let ((kill-buffer-query-functions (delq 'process-kill-buffer-query-function kill-buffer-query-functions)))
	(kill-buffer buffer-name))))

;; This requires customization of comint-output-filter-functions to
;; eliminate some escape sequences that ansi-color-for-comint-mode-on
;; doesn't handle.
(defun gmd-start-js-repl ()
  (interactive)
  (gmd-start-interactive-shell-with-command "*shell* js repl"
					    "./node_modules/babel-cli/bin/babel-node.js"
					    't))

(defun gmd-start-rails-console ()
  (interactive)
  (gmd-start-interactive-shell-with-command "*rails console*"
					    "rails console"
					    't))

(defun gmd-start-karma-webserver ()
  (interactive)
  (gmd-start-interactive-shell-with-command "*karma webserver*"
					    "yarn run test:watch"
					    't))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This comint filter strips the escape sequences that the
;; ansi-color-for-comint-mode-on doesn't know about.  For example
;; [3G.  This code is from
;; https://oleksandrmanzyuk.wordpress.com/2011/11/05/better-emacs-shell-part-i/

(defun regexp-alternatives(regexps)
  "Return the alternation of a list of regexps."
  (mapconcat (lambda (regexp)
               (concat "\\(?:" regexp "\\)"))
             regexps "\\|"))

(defvar non-sgr-control-sequence-regexp nil
  "Regexp that matches non-SGR control sequences.")

(setq non-sgr-control-sequence-regexp
      (regexp-alternatives
       '(;; icon name escape sequences
         "\033\\][0-2];.*?\007"
         ;; non-SGR CSI escape sequences
         "\033\\[\\??[0-9;]*[^0-9;m]"
         ;; noop
	 "\012\033\\[2K\033\\[1F")))

(defun comint-filter-non-sgr-control-sequences-in-region(begin end)
  (save-excursion
    (goto-char begin)
    (while (re-search-forward
            non-sgr-control-sequence-regexp end t)
      (replace-match ""))))

(defun compilation-filter-non-sgr-control-sequences-in-region()
  (comint-filter-non-sgr-control-sequences-in-region compilation-filter-start
						     (point)))

(defun comint-filter-non-sgr-control-sequences-in-output(ignored)
  (let ((start-marker
         (or comint-last-output-start
             (point-min-marker)))
        (end-marker
         (process-mark
          (get-buffer-process (current-buffer)))))
    (comint-filter-non-sgr-control-sequences-in-region
     start-marker
     end-marker)))

(add-hook 'comint-output-filter-functions 'comint-filter-non-sgr-control-sequences-in-output)
(add-hook 'compilation-filter-hook 'compilation-filter-non-sgr-control-sequences-in-region)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; M-x customize

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("0fffa9669425ff140ff2ae8568c7719705ef33b7a927a0ba7c5e2ffcfac09b75" "e6df46d5085fde0ad56a46ef69ebb388193080cc9819e2d6024c9c6e27388ba9" default))
 '(package-selected-packages
   '(yasnippet protobuf-mode rbs-mode rspec-mode ruby-test-mode rvm dockerfile-mode plantuml-mode lsp-mode ws-butler ox-gfm js-import dracula-theme solarized-theme zenburn-theme anti-zenburn-theme company typescript-mode disable-mouse org yaml-mode php-mode graphql-mode prettier-js rjsx-mode web-mode rubocop paredit nxml-mode markdown-mode magit json-mode flycheck clever-cmd)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(flycheck-error ((t (:underline (:color "orange red" :style wave)))))
 '(lazy-highlight ((t (:background "#383838" :foreground "#D0BF8F" :box (:line-width 2 :color "grey75" :style released-button) :weight bold))))
 '(region ((t (:background "gray" :distant-foreground "black"))))
 '(show-paren-match ((t (:foreground "#8be9fd" :inverse-video t :weight bold))))
 '(web-mode-doctype-face ((t (:foreground "magenta"))))
 '(web-mode-html-attr-name-face ((t (:foreground "black"))))
 '(web-mode-html-tag-bracket-face ((t (:foreground "forest green"))))
 '(web-mode-html-tag-face ((t (:foreground "forest green"))))
 '(web-mode-variable-name-face ((t (:foreground "magenta")))))
