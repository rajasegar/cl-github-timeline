(ql:quickload '(:ningle :djula :dexador :cl-json))

(djula:add-template-directory  #P"templates/")
(defparameter *template-registry* (make-hash-table :test 'equal))

;; render template - copied & modified from caveman
(defun render (template-path &optional data)
  (let ((html (make-string-output-stream))
	(template (gethash template-path *template-registry*)))
    (unless template
      (setf template (djula:compile-template* (princ-to-string template-path)))
      (setf (gethash template-path *template-registry*) template))
    (apply #'djula:render-template* template html data)
    `(200 (:content-type "text/html")
	  (,(format nil "~a" (get-output-stream-string html))))))

(djula:def-filter :direction-class (val)
  (if (evenp val)
      "direction-l"
      "direction-r"))

(defvar *app* (make-instance 'ningle:app))

(setf (ningle:route *app* "/")  (render #P"index.html"))

(setf (ningle:route *app* "/repos"
                    :method :POST)
      #'(lambda (params)
          (let* ((user (cdr (assoc "user" params :test #'string=)))
                 (repos (cl-json:decode-json-from-string (dex:get (concatenate 'string "https://api.github.com/users/" user "/repos")))))
          (render #P"_timeline.html" (list :repos repos)))))

*app*
