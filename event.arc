; Copyright (c) 2008 Dissegna Stefano

; do whatever you want with this

; event handling

(= queue* nil)

(def next-event (w)
  (if queue* 
    (pop queue*)
    (read-event w)))

(def read-event (w)
  (let event (read (instring (read-response w)))
    (push event queue*)))
