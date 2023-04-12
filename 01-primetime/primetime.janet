(import spork/json)

(defn prime? [n]
  (cond
    (not= n (math/trunc n)) false
    (< n 2) false
    (= n 2) true
    (= 0 (% n 2)) false
    (= n 3) true
    (label result
      (def mx (math/trunc (math/sqrt n)))
      (loop [d :range-to [2 mx]]
        (when (= 0 (% n d))
          (return result false)))
      (return result true))))

(assert (not (prime? 2.5)))
(assert (not (prime? 1)))
(assert (prime? 2))
(assert (prime? 3))
(assert (prime? 17))
(assert (not (prime? 18)))


(defn primetime [js]
  (print "received json: " js)
  (def msg
    (try
      (json/decode (string/trim js) true)
      ([err] nil)))
  (print "decoded: " msg)
  (match msg
    @{:method "isPrime" :number num}
        (json/encode @{:method "isPrime" :prime (prime? num)})
    (json/encode @{:error "invalid"})))

(defn handler [conn]
  (defer (:close conn)
    (loop [js :iterate (ev/read conn 1024) :while js]
      (def resp (primetime js))
      (ev/write conn resp)
      (ev/write conn "\n"))))

(defn main [&]
  (def my-server (net/listen "0.0.0.0" 9999))
  (forever
    (def conn (net/accept my-server))
    (ev/call handler conn)))
