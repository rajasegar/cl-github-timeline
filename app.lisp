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

(defvar *months* '("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"))

(djula:def-filter :format-date (val)
  (let ((year (subseq val 0 4))
        (month (subseq val 5 7))
        (date (subseq val 8 10)))
    (concatenate 'string date " " (nth (1- (parse-integer month)) *months*) " " year)))

(defun increment-page (page)
  (1+ (parse-integer page)))

(defvar *app* (make-instance 'ningle:app))

(setf (ningle:route *app* "/")  (render #P"index.html"))

(setf (ningle:route *app* "/repos"
                    :method :POST)
      #'(lambda (params)
          (let* ((user (cdr (assoc "user" params :test #'string=)))
                 (repos (cl-json:decode-json-from-string (dex:get (concatenate 'string "https://api.github.com/users/" user "/repos?sort=created&direction=desc")))))
          (render #P"_timeline.html" (list :repos repos :user user)))))

(setf (ningle:route *app* "/more")
      #'(lambda (params)
          (let* ((user (cdr (assoc "user" params :test #'string=)))
                 (page (cdr (assoc "page" params :test #'string=)))
                 (repos (cl-json:decode-json-from-string (dex:get (concatenate 'string "https://api.github.com/users/" user "/repos?sort=created&direction=desc&page=" page)))))
          (render #P"_timeline-secondary.html" (list :repos repos :user user :page (increment-page page))))))

*app*
