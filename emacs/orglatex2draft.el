;; (c) 2013 Urpo "WWWWolf" Lankinen. GNU GPL v3, for whatever
;; it's worth.

(defun draft-org-latex-fix ()
  "On org-mode LaTeX export temporary buffer, clean up stuff
   so that it produces a nicely hand-editable manuscript-format
   piece of junk. Will only extract the part of the LaTeX file with
   section \"Story\"."
  (interactive)
  (let* ((begpos nil)
	 (endpos nil))   
    ; Some things are unclear.
    (beginning-of-buffer)
    (insert "% -*- mode:latex; coding: utf-8; -*-\n")

    ; Add manuscript class.
    (beginning-of-buffer)
    (search-forward "\\documentclass")
    (next-line)
    (beginning-of-line)
    ;(insert "\\usepackage{fontspec}\n")
    ;(insert "\\setmonofont{DejaVu Sans Mono}\n")
    ;(insert "\\setromanfont{DejaVu Sans Mono}\n")
    (insert "\\usepackage{manuscript}\n")
    

    ; Delete stuff preceding "Story"
    (beginning-of-buffer)
    (search-forward "\\begin{document}")
    (next-line)
    (beginning-of-line)
    (setq begpos (point))
    (search-forward "\\section*{Story}")
    (previous-line)
    (end-of-line)
    (setq endpos (point))
    (kill-region begpos endpos)

    ; Delete stuff after Story
    (beginning-of-buffer)
    (search-forward "\\section*{Story}")
    (search-forward "\\section*")
    (beginning-of-line)
    (setq begpos (point))
    (search-forward "\\end{document}")
    (previous-line)
    (end-of-line)
    (setq endpos (point))
    (kill-region begpos endpos)

    ; What's with these bloody labels?

    (beginning-of-buffer)
    (replace-regexp "\\\\label{[^}]*}" "")

    ; Font stuff
    (beginning-of-buffer)
    (replace-string "\\documentclass[11pt]" "\\documentclass[10pt,a4paper]")
    (replace-string "\\usepackage[utf8]{inputenc}" "")
    (replace-string "\\usepackage[T1]{fontenc}" "")

    ; Go to the beginning.
    (beginning-of-buffer)))
