(defn htonl [num]
  (def buf (buffer/new 4))
  (buffer/push-word buf num)
  (reverse! buf))

(defn ntohl [buf]
  (def bcpy (buffer/slice buf))
  (reverse! bcpy)
  (read-int32 bcpy))

(defn mean [prices start end]
  (error "fix me"))


(defn handler [conn]
  (defer (:close conn)
    (def prices @{})
    (loop [msg :iterate (ev/read conn 9) :while msg]
      (def [cmd n1 n2] (parse msg))
      (case cmd
        73 (put prices n1 n2)
        81 (ev/write (htonl (mean prices n1 n2)))))))


(defn main [&]
  (def my-server (net/listen "0.0.0.0" 9999))
  (forever
    (def conn (net/accept my-server))
    (ev/call handler conn)))
