; Copyright (c) 2008 Dissegna Stefano

; do whatever you want with this

(in-package artk)
(using <arc>v3)

; event handling

(def next-event ((o w wish-shell*))
  (read-event w))

(def event-key (path id)
  (string path #\~ id))

; an event is a list: ('event widget-path event-id . args)
(def read-event ((o w wish-shell*))
  "read an event and dispatch it"
  (withs (re (read-wish w)
          event (do (prn re) (read (instring re))))
    (unless (and (acons event) (is (car event) 'event))
      (err:string "Item read isn't an event: " re))
    (let (ignore widget-path event-id . args) event
      (aif (w!event-tbl (event-key widget-path event-id))
        (apply it args)
        (err:string "No such event: " event)))))

(def main-loop ((o w wish-shell*))
  "create an event dispatch loop (in a separate thread?)"
  (while t (read-event w)))

(def tcl-event-dispatcher (widget-path event-id (o w wish-shell*))
  "create a tcl procedure that prints a given event
   return the procedure name"
  (let name (uniq)
    (dowish w
      (proc $name (blk args)
        (blk 
          (puts (do (string #\" "(" 'event " " widget-path " " 
                            event-id " $args)" #\"))))))
    name))

(def tk-bind (widget-path event-id f (o w wish-shell*))
  "do the binding"
  (let name (tcl-event-dispatcher widget-path event-id w)
    (dowish w (bind $widget-path $event-id $name))
    (= (w!event-tbl (event-key widget-path event-id)) f)
    t))
    
; Hello, World!
; (w/wish w
;   (dowish w
;     (grid (button .b -text "Hello, World!") -column 0 -row 0))
;   (tk-bind ".b" "<1>" (fn () (prn "Hello, World!")))
;   (main-loop))
