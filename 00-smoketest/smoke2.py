import asyncio

async def server(port):
  "async tcp listener"
  server = await asyncio.start_server(echo_handler, '127.0.0.1', port)
  print('serving on port', server.sockets[0].getsockname()[1])
  async with server:
    await server.wait_closed()
    
async def echo_handler(conn):
  "echo handler"
  while True:
    data = await conn.recv(1024)
    if not data:
      break
    await conn.send(data)
  conn.close()

async def test(port):
  stask = asyncio.create_task(server(port))
  ctask = asyncio.create_task(client(port))
  await asyncio.wait([ ctask])
  stask.cancel()
  

async def client(port):
  "async tcp client"
  rd,wr = await asyncio.open_connection('127.0.0.1', port)
  await wr.send(b'hello')
  data = await rd.recv(1024)
  assert data == b'hello'

if __name__ == "__main__":
   asyncio.run(test(8080))
  
