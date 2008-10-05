; Copyright (c) 2008 Dissegna Stefano

; do whatever you want with this

; bridge between a tcl/tk process and Arc

; import scheme's 'process
($ (require (lib "process.ss")))
(= process ($ process)) ; used to read and write to the tcl process

; full wish path
(= tk-wish* "~/tcltk/bin/wish8.5")

(deftem wish
  in nil
  out nil
  err nil
  ctrl nil
  event-tbl (table))

(def run-wish ()
  "run the wish shell, return an handler"
  (let (in out id err ctrl-f) (process tk-wish*)
    (inst 'wish 'in in 'out out 'err err 'ctrl ctrl-f)))

(def close-wish (w)
  "close the wish shell"
  (close w!in)
  (close w!out)
  (close w!err)
  (w!ctrl 'kill))

(def tcl-conv (x level)
  "emit code to convert x to a proper tcl representation
   lists are interpreted as sub-expressions
   e.g.: (expr \"5+6\") -> \"{[expr {5+6}]}\""
  (if (and (acons x) (is (car x) 'do))
        (cadr x)
      (and (acons x) (is (car x) 'blk))
        `(string #\{ ,@(intersperse (string #\; #\newline)
                                    (map [tcl-conv _ 0] (cdr x))) #\})
      (and (> level 0) (acons x))
        `(string #\[ ,@(intersperse " " (map [tcl-conv _ 1] x)) #\])
      (acons x)
        `(string ,@(intersperse " " (map [tcl-conv _ 1] x))) 
      (and (isa x 'sym) (is ((string x) 0) #\$))
        (sym (cut (string x) 1))
      (isa x 'string)
        `(string #\" ,x #\")
      `(string #\{ ',x #\})))

(def send-wish (w . args)
  "send args to wish"
  (let out (tostring
             (map [pr  _ " "] args)
             (pr ";" #\newline))
    (prn "sending: " out)
    (w/stdout w!out (pr out))))

(def read-wish (w)
  "read from the wish ouput"
  (aif (readline w!in)
    it
    (err "Connection to wish closed!")))

(mac dowish (w . body)
  "exec body as wish commands
   expression starting with 'do are treated as arc expressions
   symbols starting with #\\$ are treated as variables (#\\$ is stripped)
   (blk ...) is translated as a block of commands (to { ... })"
  (w/uniq ws
    `(let ,ws ,w
       ,@(map (fn (e) `(send-wish ,ws ,@(map [tcl-conv _ 1] e))) body))))

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
