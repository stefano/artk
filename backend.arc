; Copyright (c) 2008 Dissegna Stefano

; do whatever you want with this

; bridge between a tcl/tk process and Arc

; import scheme's 'process
($ (require (lib "process.ss")))
(= process ($ process)) ; used to read and write to the tcl process

; full wish path
(= tk-wish* "~/tcltk/bin/wish8.5")

(def run-wish ()
  "run the wish shell, return an handler"
  (let (in out id err ctrl-f) (process tk-wish*)
    (annotate 'wish (list in out err ctrl-f))))

(def close-wish (w)
  "close the wish shell"
  (let l (rep w)
    (close (l 0))
    (close (l 1))
    (close (l 2))
    ((l 3) 'kill)))

(def tcl-conv (x)
  "emit code to convert x to a proper tcl representation
   lists are interpreted as sub-expressions
   e.g.: (expr \"5+6\") -> \"{[expr {5+6}]}\""
  (if (and (acons x) (is (car x) 'do))
        (cadr x)
      (acons x)
        `(string #\[ ,@(intersperse " " (map tcl-conv x)) #\]) 
      `(string #\{ ',x #\})))

(def send-wish (w . args)
  "send args to wish"
  (w/stdout (cadr:rep w)
    (map [pr _ " "] args)
    (pr ";" #\newline)))

(def read-response (w)
  (readline (car:rep w)))

(mac dowish (w . body)
  "exec body as wish commands
   expression starting with 'do are treated as arc expressions"
  (w/uniq ws
    `(let ,ws ,w
       ,@(map (fn (e) `(do (send-wish ,ws ,@(map tcl-conv e))
                           (read-response ,ws))) body))))

(mac w/wish (w . body)
  (unless (is (type w) 'sym) (err "wish var must be a symbol!"))
  `(let ,w (run-wish)
     (protect (fn () ,@body)
              (fn () (close-wish ,w)))))

; a simple interaction:
; (w/wish w
;   (dowish w
;     (puts (expr 5 + (do (+ 4 3))))))
; --> 12
