; Copyright (c) 2008 Dissegna Stefano

; do whatever you want with this

(in-package artk)
(using <arc>v3)
;(interface v1 mk-widget)

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
      (type (do widget!name)))
    widget))
