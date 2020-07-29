;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Ingvar Listard"
      user-mail-address "vlzvoice@ya.ru")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; (setq doom-font (font-spec :family "monospace" :size 12 :weight 'semi-light)
;;       doom-variable-pitch-font (font-spec :family "sans" :size 13))

(setq doom-font (font-spec :family "JetBrains Mono" :size 17 :weight 'semi-light)
      doom-variable-pitch-font (font-spec :family "sans" :size 18))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/MEGA/Последний виток/org")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
;; (setq display-line-numbers-type 'visual)
(setq display-line-numbers-type nil)

;; Cursor speed up
(setq auto-window-vscroll nil)

;; Scrolling speed up
(setq scroll-conservatively 101)

(defvar personal/org-agenda-bulk-process-key ?f
  "Default key for bulk processing inbox items.")

;; Strike-throw done tasks in org mode
;; https://emacs.stackexchange.com/a/10614
(defun personal/modify-org-done-face ()
  (setq org-fontify-done-headline t)
  (set-face-attribute 'org-done nil :strike-through t)
  (set-face-attribute 'org-headline-done nil
                      :strike-through t))

(defvar personal/org-current-effort "1:00"
  "Current effort for agenda items.")

(defun personal/my-org-agenda-set-effort (effort)
  "Set the effort property for the current headline."
  (interactive
   (list (read-string (format "Effort [%s]: " personal/org-current-effort) nil nil personal/org-current-effort)))
  (setq personal/org-current-effort effort)
  (org-agenda-check-no-diary)
  (let* ((hdmarker (or (org-get-at-bol 'org-hd-marker)
                       (org-agenda-error)))
         (buffer (marker-buffer hdmarker))
         (pos (marker-position hdmarker))
         (inhibit-read-only t)
         newhead)
    (org-with-remote-undo buffer
      (with-current-buffer buffer
        (widen)
        (goto-char pos)
        (org-show-context 'agenda)
        (funcall-interactively 'org-set-effort nil personal/org-current-effort)
        (end-of-line 1)
        (setq newhead (org-get-heading)))
      (org-agenda-change-all-lines newhead hdmarker))))

(defun personal/org-agenda-process-inbox-item ()
  "Process a single item in the org-agenda."
  (org-with-wide-buffer
   (org-agenda-set-tags)
   (org-agenda-priority)
   (call-interactively 'personal/my-org-agenda-set-effort)
   ;; (call-interactively 'org-agenda-schedule)
   (org-agenda-refile nil nil t)))

(defun personal/bulk-process-entries ()
  (if (not (null org-agenda-bulk-marked-entries))
      (let ((entries (reverse org-agenda-bulk-marked-entries))
            (processed 0)
            (skipped 0))
        (dolist (e entries)
          (let ((pos (text-property-any (point-min) (point-max) 'org-hd-marker e)))
            (if (not pos)
                (progn (message "Skipping removed entry at %s" e)
                       (cl-incf skipped))
              (goto-char pos)
              (let (org-loop-over-headlines-in-active-region) (funcall 'personal/org-agenda-process-inbox-item))
              ;; `post-command-hook' is not run yet.  We make sure any
              ;; pending log note is processed.
              (when (or (memq 'org-add-log-note (default-value 'post-command-hook))
                        (memq 'org-add-log-note post-command-hook))
                (org-add-log-note))
              (cl-incf processed))))
        (org-agenda-redo)
        (unless org-agenda-persistent-marks (org-agenda-bulk-unmark-all))
        (message "Acted on %d entries%s%s"
                 processed
                 (if (= skipped 0)
                     ""
                   (format ", skipped %d (disappeared before their turn)"
                           skipped))
                 (if (not org-agenda-persistent-marks) "" " (kept marked)")))))

(defun personal/org-process-inbox ()
  "Called in org-agenda-mode, processes all inbox items."
  (interactive)
  (org-agenda-bulk-mark-regexp "inbox:")
  (personal/bulk-process-entries))

(defun personal/org-agenda-redo ()
  (interactive)
  (with-current-buffer "*Org Agenda*"
    (org-agenda-maybe-redo)
    (message "[org agenda] refreshed!")))

(defun personal-org-agenda-skip-all-siblings-but-first ()
  "Skip all but the first non-done entry."
  (let (should-skip-entry)
    (unless (org-current-is-todo)
      (setq should-skip-entry t))
    (save-excursion
      (while (and (not should-skip-entry) (org-goto-sibling t))
        (when (org-current-is-todo)
          (setq should-skip-entry t))))
    (when should-skip-entry
      (or (outline-next-heading)
          (goto-char (point-max))))))

(defun org-current-is-todo ()
  (string= "TODO" (org-get-todo-state)))


;; Org and org's related packages configurations section
(setq org-journal-dir "~/MEGA/Последний виток/org/roam/"
      org-journal-date-prefix "#+TITLE: "
      org-journal-file-format "%Y-%m-%d.org"
      org-journal-date-format "%A, %d %B %Y")

(after! org-roam
  (use-package! org-roam-server)
  (setq org-roam-directory "~/MEGA/Последний виток/org/roam"
        org-roam-db-location "~/.roam/org-roam.db"))
;;
;; Russian keyboard layout support
(use-package! reverse-im
    :config
    (reverse-im-activate "russian-computer"))

;; Backups
(setq backup-by-copying t      ; don't clobber symlinks
      backup-directory-alist
      '(("." . "~/.emacs.d/backups/"))    ; don't litter my fs tree
      delete-old-versions t
      kept-new-versions 6
      kept-old-versions 2
      version-control t)       ; use versioned backups

;; разворот длинных строк
(global-visual-line-mode)
;; Make evil-mode up/down operate in screen lines instead of logical lines
(define-key evil-motion-state-map "j" 'evil-next-visual-line)
(define-key evil-motion-state-map "k" 'evil-previous-visual-line)
;; Also in visual mode
(define-key evil-visual-state-map "j" 'evil-next-visual-line)
(define-key evil-visual-state-map "k" 'evil-previous-visual-line)

(setq deft-directory "~/MEGA/Последний виток/org/roam/")

;; Cycle blocks view in org mode
(after! evil-org
  (remove-hook 'org-tab-first-hook #'+org-cycle-only-current-subtree-h))

(eval-after-load "org"
  (add-hook 'org-add-hook 'personal/modify-org-done-face))

(defun personal/org-inbox-capture ()
  (interactive)
  "Capture a task in agenda mode."
  (org-capture nil "i"))

(after! org
  (defun personal/org-archive-done-tasks ()
    "Archive all done tasks."
    (interactive)
    (org-map-entries 'org-archive-subtree "/DONE" 'file))
  (setq personal/org-agenda-directory "~/MEGA/Последний виток/org/gtd/")
  (setq org-todo-keywords
      '((sequence "TODO(t!)" "NEXT(n!)" "INPROGRESS(i!)" "WAITING(w!)" "|" "DONE(d!)" "CANCELLED(c!)")))

  (setq org-todo-keyword-faces
    '(("TODO" . org-warning)
      ("NEXT" . "#E35DBF")
      ("INPROGRESS" . "#E35DBF")
      ("CANCELED" . (:foreground "white" :background "#4d4d4d" :weight bold))
      ("WAITING" . "pink")))

  (setq org-tag-alist (quote (("@errand" . ?e)
                              ("@office" . ?o)
                              ("@home" . ?h)
                              ("@school" . ?s)
                              (:newline)
                              ("WAITING" . ?w)
                              ("HOLD" . ?H)
                              ("CANCELLED" . ?c))))

  (setq org-capture-templates
        `(("i" "inbox" entry (file ,(concat personal/org-agenda-directory "inbox.org"))
           "* TODO %?")
          ("e" "email" entry (file+headline ,(concat personal/org-agenda-directory "emails.org") "Emails")
               "* TODO [#A] Reply: %a :@home:@school:"
               :immediate-finish t)
          ("c" "org-protocol-capture" entry (file ,(concat personal/org-agenda-directory "inbox.org"))
               "* TODO [[%:link][%:description]]\n\n %i"
               :immediate-finish t)
          ("w" "Weekly Review" entry (file+olp+datetree ,(concat personal/org-agenda-directory "reviews.org"))
           (file ,(concat personal/org-agenda-directory "templates/weekly_review.org")))
          ("r" "Reading" todo ""
           ((org-agenda-files '(,(concat personal/org-agenda-directory "reading.org")))))))

  (require 'find-lisp)
  (setq org-agenda-files
      (find-lisp-find-files personal/org-agenda-directory "\.org$")))

(map! "<f1>" #'personal/switch-to-agenda)
(setq org-agenda-block-separator nil
      org-agenda-start-with-log-mode t)
(defun personal/switch-to-agenda ()
  (interactive)
  (org-agenda nil " "))

(after! org-agenda

  (setq org-columns-default-format "%40ITEM(Task) %Effort(EE){:} %CLOCKSUM(Time Spent) %SCHEDULED(Scheduled) %DEADLINE(Deadline)"
        org-agenda-custom-commands `((" " "Agenda"
                                      ((agenda ""
                                               ((org-agenda-span 'week)
                                                (org-deadline-warning-days 7)))
                                       (todo "TODO"
                                             ((org-agenda-overriding-header "To Refile")
                                              (org-agenda-files '(,(concat personal/org-agenda-directory "inbox.org")))))
                                       (todo "TODO"
                                             ((org-agenda-overriding-header "Emails")
                                              (org-agenda-files '(,(concat personal/org-agenda-directory "emails.org")))))
                                       (todo "NEXT"
                                             ((org-agenda-overriding-header "In Progress")
                                              (org-agenda-files '(,(concat personal/org-agenda-directory "someday.org")
                                                                  ,(concat personal/org-agenda-directory "projects.org")
                                                                  ,(concat personal/org-agenda-directory "oneoff.org")
                                                                  ,(concat personal/org-agenda-directory "next.org")))
                                              ))
                                       (todo "TODO"
                                             ((org-agenda-overriding-header "Projects")
                                              (org-agenda-files '(,(concat personal/org-agenda-directory "projects.org")))
                                              ))
                                       (todo "TODO"
                                             ((org-agenda-overriding-header "One-off Tasks")
                                              (org-agenda-files '(,(concat personal/org-agenda-directory "next.org")
                                                                  ,(concat personal/org-agenda-directory "oneoff.org")))
                                              (org-agenda-skip-function '(org-agenda-skip-entry-if 'deadline 'scheduled))))))
                                      ("o" "At the office" tags-todo "@office"
                                        ((org-agenda-overriding-header "Office")
                                          (org-agenda-skip-function #'personal-org-agenda-skip-all-siblings-but-first))))
        org-agenda-bulk-custom-functions `((,personal/org-agenda-bulk-process-key personal/org-agenda-process-inbox-item)))


  (map! :map org-agenda-mode-map
        ;; "i" #'org-agenda-clock-in
        "r" #'personal/org-process-inbox
        ;; "r" #'personal/org-agenda-process-inbox-item
        "R" #'org-agenda-refile
        "X" #'personal/org-inbox-capture)


  (setq org-refile-targets '(("next.org" :level . 0)
                             ("oneoff.org" :level . 0)
                             ("someday.org" :level . 1)
                             ("reading.org" :level . 1)
                             ("projects.org" :maxlevel . 2)))

  (add-hook 'org-capture-after-finalize-hook #'personal/org-agenda-redo))

(use-package! org-roam-protocol
  :after org-protocol)

(map! "C-;" #'avy-goto-word-1)

;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
