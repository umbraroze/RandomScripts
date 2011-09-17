;;;; Will turn normal emacslike paragraphs of text into long-lines
;;;; paragraphs. Bound to "C-c RET".
;;;;
;;;; (c) Urpo Lankinen 2005,2011. Do what you want with this, as long
;;;; as this copyright notice is present. No warranty expressed or
;;;; implied.
;;;;
;;;; Written by wwwwolf, 2005-07-06
;;;; Bugfix by wwwwolf, 2005-08-07
;;;; Further bugfix by wwwwolf, 2011-05-02
;;;; tested on xemacs 21.5.18-carbon-b1 on macosx
;;;;       and gnu emacs 23.2.1 on macosx

(defun melt-paragraph ()
  "Combines the paragraph under the point, separated by blank lines
on either side, into a single line."
  (interactive)
  (let ((parabeg 0)
	(paraend 0))
    ;; Find beginning of the paragrapg - back up until we hit a blank line
    ;; or the beginning of the buffer.
    (beginning-of-line)
    (if (> (point) (point-min)) ; Not at the beginning of buffer?
	(let ()
	  (while
	      (not (= (following-char) ?\n))
	    (forward-line -1))
	  (forward-line 1)))
    (setq parabeg (point))
    ;; Then, let's find the end, same way
    (while (and
	    (not (= (following-char) ?\n))
	    (> (count-lines (point) (point-max)) 0))
      (forward-line 1))
    ;; Back up, unless we're in the end of the buffer...
    (if (> (count-lines (point) (point-max)) 0)
	(forward-line -1))
    (end-of-line)
    (setq paraend (point))
    ;; Then, replace stuff
    (narrow-to-region parabeg paraend)
    (goto-char (point-min))
    (while (search-forward (string ?\n) nil t)
      (replace-match " " nil t))
    (goto-char (point-min))
    (widen)))

(define-key global-map "\C-c\C-m" 'melt-paragraph)
(provide 'melt-paragraph)
