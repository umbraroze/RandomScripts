;;;; Written by WWWWolf, 2005-07-06
;;;; Bugfix by WWWWolf, 2005-08-07
;;;; tested on xemacs 21.5.18-carbon-b1 on macosx
;;;; Note that this might be slightly over-engineered.

(defun melt-paragraph ()
"Combines the paragraph, separated by blank lines on either side, on
current buffer, into a single line."
  (interactive)
  (let ((parabeg 0)
	(paraend 0))
    ;; Find beginning - back up until we hit a blank line
    (beginning-of-line)
    (while (not (= (following-char) ?\n))
      (forward-line -1))
    (forward-line 1)
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
