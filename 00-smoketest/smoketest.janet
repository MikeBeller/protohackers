(defn handler [conn]
  (defer (:close conn)
    (loop [msg :iterate (ev/read conn 1024) :while msg]
      (net/write conn msg))))

(defn main [&]
  (def my-server (net/listen "0.0.0.0" 9999))
  (forever
    (def conn (net/accept my-server))
    (ev/call handler conn)))
