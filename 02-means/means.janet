

(defn htonl [num]
  (def sint (int/s64 num))
  (def buf (int/to-bytes sint :be))
  (buffer/slice buf 4 8))

(defn read-int32 [buf off]
  #(printf "buf: %j" buf)
  (var r 0)
  (loop [i :range [off (+ off 4)]]
    (set r (blshift r 8))
    (+= r (get buf i)))
  r)

(assert (= 31297 (read-int32 (htonl 31297) 0)))
(assert (= -1 (read-int32 (htonl -1) 0)))

(defn zeronan [x] (if (nan? x) 0 x))

(defn mean-of-range [prices start end]
  (zeronan
    (mean
      (seq [[ts val] :pairs prices
            :when (and (>= ts start) (<= ts end))]
        val))))

(defn parse [msg]
  [(get msg 0) (read-int32 msg 1) (read-int32 msg 5)])

(defn handler [conn]
  (defer (:close conn)
    (def prices @{})
    (loop [msg :iterate (ev/chunk conn 9) :while msg]
      (def [cmd n1 n2] (parse msg))
      (case cmd
        73 (put prices n1 n2)
        81 (ev/write conn (htonl (mean-of-range prices n1 n2)))))))

(defn main [&]
  (def my-server (net/listen "0.0.0.0" 9999))
  (forever
    (def conn (net/accept my-server))
    (ev/call handler conn)))
