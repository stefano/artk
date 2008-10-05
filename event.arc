; Copyright (c) 2008 Dissegna Stefano

; do whatever you want with this

; event handling

(def next-event (w)
  (read-event w))

(def event-key (path id)
  (string path #\~ id))

; an event is a list: ('event widget-path event-id . args)
(def read-event (w)
  "read an event and dispatch it"
  (withs (re (read-wish w)
          event (do (prn re) (read (instring re))))
    (unless (and (acons event) (is (car event) 'event))
      (err:string "Item read isn't an event: " re))
    (let (ignore widget-path event-id . args) event
      (aif (w!event-tbl (event-key widget-path event-id))
        (apply it args)
        (err:string "No such event: " event)))))

(def main-event-loop (w)
  "create an event dispatch loop (in a separate thread?)"
  (while t (read-event w)))

(def tcl-event-dispatcher (w widget-path event-id)
  "create a tcl procedure that prints a given event
   return the procedure name"
  (let name (uniq)
    (dowish w
      (proc $name (blk args)
        (blk 
          (puts (do (string #\" "(event " widget-path 
                            " " event-id " $args)" #\"))))))
    name))

(def tk-bind (w widget-path event-id f)
  "do the binding"
  (let name (tcl-event-dispatcher w widget-path event-id)
    (dowish w (bind $widget-path $event-id $name))
    (= (w!event-tbl (event-key widget-path event-id)) f)
    t))
    
; Hello, World!
; (w/wish w
;   (dowish w
;     (grid (button .b -text "Hello, World!") -column 0 -row 0))
;   (tk-bind w ".b" "<1>" (fn () (prn "Hello, World!")))
;   (main-event-loop w))
