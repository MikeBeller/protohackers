import socket
from threading import Thread

# attempt to combine server and test client into one program using threads

def server(sock):
  try:
    while True:
      conn, addr = sock.accept()
      print('Connection address:', addr)
      th = Thread(target=client, args=(conn, ))
      th.start()
  except:
    print('End of server')

def start_server(port):
  sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
  sock.bind(('', port))
  sock.listen(5)
  t = Thread(target=server, args=(sock, ))
  t.start()
  return sock, t
    
def client(conn):
    while True:
      data = conn.recv(1024)
      if not data: break
      conn.sendall(data)
    conn.close()

def test(port):
  sock, thr = start_server(port)
  
  s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
  s.connect(('localhost', port))
  s.sendall(b'Hello!')
  data = s.recv(1024)
  s.close()
  assert data == b'Hello!'
  print("Test passed.")
  sock.close()
  thr.join()


if __name__ == "__main__":
   test(8000)
  
