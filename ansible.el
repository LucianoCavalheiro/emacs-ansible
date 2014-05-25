;;; ansible.el --- Ansible minor mode
;; -*- Mode: Emacs-Lisp -*-

;; Copyright (C) 2014 by 101000code/101000LAB

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

;; Version: 0.0.1
;; Author: k1LoW (Kenichirou Oyama), <k1lowxb [at] gmail [dot] com> <k1low [at] 101000lab [dot] org>
;; URL: http://101000lab.org
;; Package-Requires: ((dash "2.6.0") (s "1.9.0") (f "0.16.2") (helm "1.6.1"))

;;; Install
;; Put this file into load-path'ed directory, and byte compile it if
;; desired.  And put the following expression into your ~/.emacs.
;;
;; (require 'ansible)
;;
;; If you use default key map, Put the following expression into your ~/.emacs.
;;
;; (ansible::set-default-keymap)

;;; Commentary:

;;; Commands:
;;
;; Below are complete command list:
;;
;;  `ansible'
;;    Ansible minor mode.
;;  `ansible::find-playbooks'
;;    Find YAML files.
;;
;;; Customizable Options:
;;
;; Below are customizable option list:
;;
;;  `ansible::dir-search-limit'
;;    Search limit
;;    default = 5

;;; Code:

;;require
(require 'dash)
(require 's)
(require 'f)
(require 'cl)
(require 'helm-config)
(require 'easy-mmode)

(defgroup ansible nil
  "Ansible minor mode"
  :group 'languages
  :prefix "ansible::")

(defcustom ansible::dir-search-limit 5
  "Search limit"
  :type 'integer
  :group 'ansible)

;;;###autoload
(defvar ansible::key-map
  (make-sparse-keymap)
  "Keymap for Ansible.")

(defvar ansible::root-path nil
  "Ansible spec directory path.")

(defvar ansible::hook nil
  "Hook.")

;;;###autoload
(define-minor-mode ansible
  "Ansible minor mode."
  :lighter " Ansible"
  :group 'ansible
  (if ansible
      (progn
        (setq minor-mode-map-alist
              (cons (cons 'ansible ansible::key-map)
                    minor-mode-map-alist))
        (run-hooks 'ansible::hook))
    nil))

(defun ansible::set-default-keymap ()
  "Set default key-map."
  (setq ansible::key-map
        (let ((map (make-sparse-keymap)))
          (define-key map (kbd "C-c s") 'ansible::find-playbooks)
          map)))

(defun ansible::update-root-path ()
  "Update ansible::root-path"
  (let ((spec-path (ansible::find-root-path)))
    (unless (not spec-path)
      (setq ansible::root-path spec-path))
    (if ansible::root-path
        t
      nil)))

(defun ansible::find-root-path ()
  "Find ansible directory."
  (let ((current-dir (f-expand default-directory)))
    (loop with count = 0
          until (f-exists? (f-join current-dir "roles"))
          ;; Return nil if outside the value of
          if (= count ansible::dir-search-limit)
          do (return nil)
          ;; Or search upper directories.
          else
          do (incf count)
          (unless (f-root? current-dir)
            (setq current-dir (f-dirname current-dir)))
          finally return current-dir)))

(defun ansible::list-playbooks ()
  (if (ansible::update-root-path)
      (-map
       (lambda (file) (f-relative file ansible::root-path))
       (f-files ansible::root-path (lambda (file) (s-matches? ".yml" (f-long file))) t))
    nil))

(defun ansible::helm-playbooks-display-to-real (file)
  (f-expand file ansible::root-path))

;;;###autoload
(defvar ansible::helm-playbooks-source
  '((name . "Ansible playbooks.")
    (candidates . ansible::list-playbooks)
    (display-to-real . ansible::helm-playbooks-display-to-real)
    (action . find-file))
    "Ansible playbook helm source.")

;;;###autoload
(defun ansible::find-playbooks ()
  "Find YAML files."
  (interactive)
  (helm-other-buffer `(ansible::helm-playbooks-source) "*helm yml*"))

(defconst ansible::dir (file-name-directory (or (buffer-file-name)
                                                            load-file-name)))

;;;###autoload
(defun ansible::snippets-initialize ()
  (let ((snip-dir (expand-file-name "snippets" ansible::dir)))
    (add-to-list 'yas-snippet-dirs snip-dir t)
    (yas-load-directory snip-dir)))

;;;###autoload
(eval-after-load 'yasnippet
  '(ansible::snippets-initialize))

;;;###autoload
(defun ansible::dict-initialize ()
  (let ((dict-dir (expand-file-name "dict" ansible::dir)))
    (add-to-list 'ac-dictionary-files (f-join dict-dir "ansible") t)))

;;;###autoload
(add-hook 'ansible::hook
  'ansible::dict-initialize)

(provide 'ansible)

;;; end
;;; ansible.el ends here
