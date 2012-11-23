;; (c) 2012 Urpo "WWWWolf" Lankinen. GNU GPL v3, for whatever
;; it's worth.

(defun nanowrimo-cleanup-org-html-export ()
  "Clean up the NaNoWriMo novel org-mode HTML export. This is a
   bit hackish and assumes that your HTML-export is in current
   buffer and is pretty handled as a text mass. Also assumes you
   have a story as a <h2> element named 'Story', and you have
   chapters as <h3> elements and scenes as <h4> elements. Chapter
   titles are part of the text, but scene titles are assumed to
   be working titles, so scene titles will be removed and
   replaced with <hr/> where applicable. The end result should be
   something that can be just opened in web browser and
   copypasted to the NaNoWriMo validator."
  (interactive)
  (let* ((begpos nil)
	 (endpos nil))
    ; Delete the HTML header garbage.
    (beginning-of-buffer)
    (search-forward "<meta http-equiv")
    (next-line)
    (beginning-of-line)
    (setq begpos (point))
    (search-forward "</head>")
    (previous-line)
    (beginning-of-line)
    (setq endpos (point))
    (kill-region begpos endpos)

    ; Delete note ramblings
    (search-forward "</h1>")
    (next-line)
    (beginning-of-line)
    (setq begpos (point))
    (search-forward "Story</h2>")
    (beginning-of-line)
    (next-line)
    (setq endpos (point))
    (kill-region begpos endpos)

    ; Delete postamble.
    (beginning-of-buffer)
    (search-forward "<div id=\"postamble\"")
    (beginning-of-line)
    (setq begpos (point))
    (search-forward "</div>")
    (next-line)
    (beginning-of-line)
    (setq endpos (point))
    (kill-region begpos endpos)

    ; Delete all <div>s.
    (beginning-of-buffer)
    (replace-regexp "</?div.*>" "")

    ; Remove all story sections headlines, replace them with <hr>
    (beginning-of-buffer)
    (replace-regexp "<h4.*>.*</h4>" "<hr/>")

    ; Remove all IDs and classes and whatnot.
    (beginning-of-buffer)
    (replace-regexp " \\(id\\|class\\)=\".*\">" ">")

    ; Tons of newlines? No more.
    (beginning-of-buffer)
    (replace-regexp "\n\n\n+" "\n\n")

    ; First scene breaks? Also no more.
    (beginning-of-buffer)
    (replace-regexp "</h3>\n\n<hr/>\n\n" "</h3>\n\n")

    ; Also wrong level of headings.
    (beginning-of-buffer)
    (replace-regexp "<\\(/?\\)h3>" "<\\1h2>")

    ; Go to the beginning.
    (beginning-of-buffer)))
