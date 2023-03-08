import socket

PORT = 9999

def main(port):
    data = {}
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(('0.0.0.0', port))

    while True:
        msg, addr = sock.recvfrom(1024)
        msg = msg.decode()
        f = msg.split('=', 1)
        if len(f) == 2:
            data[f[0]] = f[1]
        else:
            key = f[0]
            if key == 'version':
                val = "1.0"
            else:
                val = data.get(f[0], '')
            sock.sendto(f"{f[0]}={val}".encode(), addr)

if __name__ == '__main__':
    main(PORT)