; Copyright (c) 2008 Dissegna Stefano

; do whatever you want with this

; bridge between a tcl/tk process and Arc

(in-package artk)
(using <arc>v3)
(using <arc>v3-packages)
(using <arc>v3-on-mzscheme)
(interface v1 blk w/wish dowish tk-bind main-loop mk-widget)

; import scheme's 'process
(<arc>seval (list (unpkg 'require) (list (unpkg 'lib) "process.ss")))
(= process $.process) ; used to read and write to the tcl process

; full wish path
(= tk-wish* "~/tcltk/bin/wish8.5")

; default wish shell
(= wish-shell* nil)

(deftem wish
  in nil
  out nil
  err nil
  ctrl nil
  event-tbl (table))

(def run-wish ()
  "run the wish shell, return an handler"
  (let (in out id err ctrl-f) (process tk-wish*)
    (= wish-shell* (inst 'wish 'in in 'out out 'err err 'ctrl ctrl-f
                               'event-tbl (table)))))

(def close-wish ((o w wish-shell*))
  "close the wish shell"
  (when (is w wish-shell*)
    (= wish-shell* nil))
  (close w!in)
  (close w!out)
  (close w!err)
  (w!ctrl (unpkg 'kill)))

(def tcl-conv (x)
  (tcl-conv-real x 1))

(def rem-$ (x)
  (withs (x (string x)
          p (<arc>pos #\$ x))
    (sym:string (cut x 0 p) (cut x (+ p 1)))))

(def tcl-conv-real (x level)
  "emit code to convert x to a proper tcl representation
   lists are interpreted as sub-expressions
   e.g.: (expr \"5+6\") -> \"{[expr {5+6}]}\""
  (if (and (acons x) (is (car x) 'do))
        (cadr x)
      (and (acons x) (is (car x) 'blk))
        `(string #\{ ,@(intersperse (string #\; #\newline)
                                    (map [tcl-conv-real _ 0] (cdr x))) #\})
      (and (> level 0) (acons x))
        `(string #\[ ,@(intersperse " " (map [tcl-conv-real _ 1] x)) #\])
      (acons x)
        `(string ,@(intersperse " " (map [tcl-conv-real _ 1] x))) 
      (and (isa x 'sym) (is ((string (unpkg x)) 0) #\$))
        `(string #\{ ,(rem-$ x) #\})
      (isa x 'string)
        `(string #\" ,x #\")
      (isa x 'sym)
        `(string #\{ (unpkg ',x) #\})
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
       ,@(map (fn (e) `(send-wish ,ws ,@(map tcl-conv e))) body))))

(mac w/wish (w . body)
  (unless (is (type w) 'sym) (err "wish var must be a symbol!"))
  `(let ,w (run-wish)
     (protect (fn () ,@body)
              (fn () (close-wish ,w)))))

; a simple interaction:
; (w/wish w
;   (dowish w
;     (puts (expr 5 + (do (+ 4 3)))))
;   (read-wish w))
; --> "12"
