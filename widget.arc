; Copyright (c) 2008 Dissegna Stefano

; do whatever you want with this

(in-package artk)
(using <arc>v3)

; widget objects

(deftem widget
  parent nil
  path nil)

(def mk-widget (type (o parent) (o w wish-shell*))
  (let widget (w/uniq name
                (inst 'widget 'parent parent 
                      'path (aif parent 
                              (string it!path #\. name)
                              (string #\. name))))
    (dowish w
      (<arc>$type (do widget!name)))
    widget))

(mac cmd (widget cmd . args)
  "send a command to a widget"
  `(dowish wish-shell*
     (,cmd (do (,widget 'path)) 
           ,(map (fn (arg) `(do (let s ,arg (if (isa s 'widget) s!path s))))
                 args))))

(defcall widget (cmd . args)
  (dowish wish-shell*
    ($cmd 