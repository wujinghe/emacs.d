;; -*- coding: utf-8; lexical-binding: t; -*-

;; Without this comment emacs25 adds (package-initialize) here
;; (package-initialize)

(let* ((minver "25.1"))
  (when (version< emacs-version minver)
    (error "Emacs v%s or higher is required." minver)))

(defvar best-gc-cons-threshold
  4000000
  "Best default gc threshold value.  Should NOT be too big!")

(defvar my-debug nil "Enable debug mode.")

;; don't GC during startup to save time
(setq gc-cons-threshold most-positive-fixnum)

(setq emacs-load-start-time (current-time))

;; {{ emergency security fix
;; https://bugs.debian.org/766397
(with-eval-after-load 'enriched
  (defun enriched-decode-display-prop (start end &optional param)
    (list start end)))
;; }}
;;----------------------------------------------------------------------------
;; Which functionality to enable (use t or nil for true and false)
;;----------------------------------------------------------------------------
(setq *is-a-mac* (eq system-type 'darwin))
(setq *win64* (eq system-type 'windows-nt))
(setq *cygwin* (eq system-type 'cygwin) )
(setq *linux* (or (eq system-type 'gnu/linux) (eq system-type 'linux)) )
(setq *unix* (or *linux* (eq system-type 'usg-unix-v) (eq system-type 'berkeley-unix)) )
(setq *emacs24* (>= emacs-major-version 24))
(setq *emacs25* (>= emacs-major-version 25))
(setq *emacs26* (>= emacs-major-version 26))
(setq *no-memory* (cond
                   (*is-a-mac*
                    ;; @see https://discussions.apple.com/thread/1753088
                    ;; "sysctl -n hw.physmem" does not work
                    (<= (string-to-number (shell-command-to-string "sysctl -n hw.memsize"))
                        (* 4 1024 1024)))
                   (*linux* nil)
                   (t nil)))

(defconst my-emacs-d (file-name-as-directory user-emacs-directory)
  "Directory of emacs.d")

(defconst my-site-lisp-dir (concat my-emacs-d "site-lisp")
  "Directory of site-lisp")

(defconst my-lisp-dir (concat my-emacs-d "lisp")
  "Directory of lisp")

;; @see https://www.reddit.com/r/emacs/comments/55ork0/is_emacs_251_noticeably_slower_than_245_on_windows/
;; Emacs 25 does gc too frequently
(when *emacs25*
  ;; (setq garbage-collection-messages t) ; for debug
  (setq best-gc-cons-threshold (* 64 1024 1024))
  (setq gc-cons-percentage 0.5)
  (run-with-idle-timer 5 t #'garbage-collect))

(defun my-vc-merge-p ()
  "Use Emacs for git merge only?"
  (boundp 'startup-now))

(defun require-init (pkg &optional maybe-disabled)
  "Load PKG if MAYBE-DISABLED is nil or it's nil but start up in normal slowly."
  (when (or (not maybe-disabled) (not (my-vc-merge-p)))
    (load (file-truename (format "%s/%s" my-lisp-dir pkg)) t t)))

(defun local-require (pkg)
  "Require PKG in site-lisp directory."
  (unless (featurep pkg)
    (load (expand-file-name
           (cond
            ((eq pkg 'go-mode-load)
             (format "%s/go-mode/%s" my-site-lisp-dir pkg))
            (t
             (format "%s/%s/%s" my-site-lisp-dir pkg pkg))))
          t t)))

;; @see https://www.reddit.com/r/emacs/comments/3kqt6e/2_easy_little_known_steps_to_speed_up_emacs_start/
;; Normally file-name-handler-alist is set to
;; (("\\`/[^/]*\\'" . tramp-completion-file-name-handler)
;; ("\\`/[^/|:][^/|]*:" . tramp-file-name-handler)
;; ("\\`/:" . file-name-non-special))
;; Which means on every .el and .elc file loaded during start up, it has to runs those regexps against the filename.
(let* ((file-name-handler-alist nil))

  ;; ;; {{
  ;; (require 'benchmark-init-modes)
  ;; (require 'benchmark-init)
  ;; (benchmark-init/activate)
  ;; ;; `benchmark-init/show-durations-tree' to show benchmark result
  ;; ;; }}

  (require-init 'init-autoload)
  ;; `package-initialize' takes 35% of startup time
  ;; need check https://github.com/hlissner/doom-emacs/wiki/FAQ#how-is-dooms-startup-so-fast for solution
  (require-init 'init-modeline)
  (require-init 'init-utils)
  (require-init 'init-file-type)
  (require-init 'init-elpa)
  (require-init 'init-exec-path t) ;; Set up $PATH
  ;; Any file use flyspell should be initialized after init-spelling.el
  (require-init 'init-spelling t)
  (require-init 'init-uniquify t)
  (require-init 'init-ibuffer t)
  (require-init 'init-ivy)
  (require-init 'init-hippie-expand)
  (require-init 'init-windows)
  (require-init 'init-markdown t)
  ;(require-init 'init-javascript t)
  (require-init 'init-org t)
  ;(require-init 'init-css t)
  (require-init 'init-python t)
  (require-init 'init-lisp t)
  (require-init 'init-elisp t)
  (require-init 'init-yasnippet t)
  (require-init 'init-cc-mode t)
  (require-init 'init-gud t)
  (require-init 'init-linum-mode)
  (require-init 'init-git t)
  (require-init 'init-gtags t)
  (require-init 'init-clipboard)
  (require-init 'init-ctags t)
  ;(require-init 'init-bbdb t)
  ;(require-init 'init-gnus t)
  (require-init 'init-lua-mode t)
  ;(require-init 'init-workgroups2 t) ; use native API in lightweight mode
  (require-init 'init-term-mode t)
  ;(require-init 'init-web-mode t)
  (require-init 'init-company t)
  ;(require-init 'init-chinese t) ;; cannot be idle-required
  ;; need statistics of keyfreq asap
  (require-init 'init-keyfreq t)
  ;(require-init 'init-httpd t)

  ;; projectile costs 7% startup time

  ;; don't play with color-theme in light weight mode
  ;; color themes are already installed in `init-elpa.el'
  (require-init 'init-theme)

  ;; misc has some crucial tools I need immediately
  (require-init 'init-essential)
  ;; handy tools though not must have
  ;(require-init 'init-misc t)

  ;(require-init 'init-emacs-w3m t)
  ;(require-init 'init-shackle t)
  (require-init 'init-dired t)
  (require-init 'init-writting t)
  (require-init 'init-hydra) ; hotkey is required everywhere
  ;; use evil mode (vi key binding)
  (require-init 'init-evil) ; init-evil dependent on init-clipboard

  ;; ediff configuration should be last so it can override
  ;; the key bindings in previous configuration
  ;(require-init 'init-ediff)

  ;; @see https://github.com/hlissner/doom-emacs/wiki/FAQ
  ;; Adding directories under "site-lisp/" to `load-path' slows
  ;; down all `require' statement. So we do this at the end of startup
  ;; NO ELPA package is dependent on "site-lisp/".
  (setq load-path (cdr load-path))
  (my-add-subdirs-to-load-path (file-name-as-directory my-site-lisp-dir))

  (unless (my-vc-merge-p)
    ;; my personal setup, other major-mode specific setup need it.
    ;; It's dependent on *.el in `my-site-lisp-dir'
    (load (expand-file-name "~/.custom.el") t nil)

    ;; @see https://www.reddit.com/r/emacs/comments/4q4ixw/how_to_forbid_emacs_to_touch_configuration_files/
    ;; See `custom-file' for details.
    (load (setq custom-file (expand-file-name (concat my-emacs-d "custom-set-variables.el"))) t t)))

(setq gc-cons-threshold best-gc-cons-threshold)

(when (require 'time-date nil t)
  (message "Emacs startup time: %d seconds."
           (time-to-seconds (time-since emacs-load-start-time))))

;;; Local Variables:
;;; no-byte-compile: t
;;; End:
(put 'erase-buffer 'disabled nil)

(setq neo-window-width 55)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set up code completion with company
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar my:byte-compile-init t)
(defvar my:use-prescient t)

(mapc #'(lambda (add) (add-to-list 'load-path add))
      (eval-when-compile
        (require 'package)
        ;(package-initialize)
        ;; Install use-package if not installed yet.
        (unless (package-installed-p 'use-package)
          (package-refresh-contents)
          (package-install 'use-package))
        ;; (require 'use-package)
        (let ((package-user-dir-real (file-truename package-user-dir)))
          ;; The reverse is necessary, because outside we mapc
          ;; add-to-list element-by-element, which reverses.
          (nreverse
           (apply #'nconc
                  ;; Only keep package.el provided loadpaths.
                  (mapcar #'(lambda (path)
                              (if (string-prefix-p package-user-dir-real path)
                                  (list path)
                                nil))
                          load-path))))))

;; (use-package company
;;   :ensure t
;;   :diminish company-mode
;;   ;:hook (prog-mode . global-company-mode)
;;   :commands (company-mode company-indent-or-complete-common)
;;   :init
;;   (setq company-minimum-prefix-length 2
;;         company-tooltip-limit 14
;;         company-tooltip-align-annotations t
;;         company-require-match 'never
;;         company-global-modes '(not erc-mode message-mode help-mode gud-mode)

;;         ;; These auto-complete the current selection when
;;         ;; `company-auto-complete-chars' is typed. This is too magical. We
;;         ;; already have the much more explicit RET and TAB.
;;         company-auto-complete nil
;;         company-auto-complete-chars nil

;;         ;; Only search the current buffer for `company-dabbrev' (a backend that
;;         ;; suggests text your open buffers). This prevents Company from causing
;;         ;; lag once you have a lot of buffers open.
;;         company-dabbrev-other-buffers nil

;;         ;; Make `company-dabbrev' fully case-sensitive, to improve UX with
;;         ;; domain-specific words with particular casing.
;;         company-dabbrev-ignore-case nil
;;         company-dabbrev-downcase nil)

;;   :config
;;   (defvar my:company-explicit-load-files '(company company-capf))
;;   (when my:byte-compile-init
;;     (dolist (company-file my:company-explicit-load-files)
;;       (require company-file)))
;;   ;; Zero delay when pressing tab
;;   (setq company-idle-delay 0)
;;   ;; remove backends for packages that are dead
;;   (setq company-backends (delete 'company-eclim company-backends))
;;   (setq company-backends (delete 'company-clang company-backends))
;;   (setq company-backends (delete 'company-xcode company-backends))
;;   )

;; Use prescient for sorting results with company:
;; https://github.com/raxod502/prescient.el
;; (when my:use-prescient
;;   (use-package company-prescient
;;     :ensure t
;;     :after company
;;     :config
;;     (company-prescient-mode t)
;;     (prescient-persist-mode t)
;;     )
;;   )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Configure flycheck
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Note: For C++ we use flycheck with LSP mode

(use-package lsp-java
  :init
  (defun jmi/java-mode-config ()
    (setq-local tab-width 4
                c-basic-offset 4)
    (toggle-truncate-lines 1)
    (setq-local tab-width 4)
    (setq-local c-basic-offset 4)
    (lsp))

  :config
  ;; Enable dap-java
  (require 'dap-java)

  ;; Support Lombok in our projects, among other things
  (setq lsp-java-vmargs
        (list "-noverify"
              "-Xmx2G"
              "-XX:+UseG1GC"
              "-XX:+UseStringDeduplication"
              (concat "-javaagent:" jmi/lombok-jar)
              (concat "-Xbootclasspath/a:" jmi/lombok-jar))
        lsp-file-watch-ignored
        '(".idea" ".ensime_cache" ".eunit" "node_modules" ".git" ".hg" ".fslckout" "_FOSSIL_"
          ".bzr" "_darcs" ".tox" ".svn" ".stack-work" "build")

        lsp-java-import-order '["" "java" "javax" "#"]
        ;; Don't organize imports on save
        lsp-java-save-action-organize-imports nil

        ;; Formatter profile
        lsp-java-format-settings-url (concat "file://" jmi/java-format-settings-file)
        lsp-enable-on-type-formatting t
        lsp-enable-indentation t)
  (setq lsp-java-server-install-dir "/home/wujinghe/opt/jdtls")

  :hook (java-mode . jmi/java-mode-config)

  :demand t
  :after (lsp lsp-mode dap-mode jmi-init-platform-paths))

(setq lsp-restart 'auto-restart)
