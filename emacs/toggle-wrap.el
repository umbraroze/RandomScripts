(defun toggle-wrap-modes ()
  "Toggles between auto-fill and visual-line modes. The command assumes only
one is active at the time."
  (interactive)
  (auto-fill-mode)
  (visual-line-mode))
