import asyncio

# Combined server and test client

async def server(port):
  "async tcp listener"
  server = await asyncio.start_server(echo_handler, '127.0.0.1', port)
  print('serving on port', server.sockets[0].getsockname()[1])
  async with server:
    await server.serve_forever()
    
async def echo_handler(reader, writer):
  "echo handler"
  while True:
    data = await reader.read(1024)
    if not data:
      break
    writer.write(data)
    await writer.drain()
  writer.close()

async def client(port):
  "async tcp client"
  rd,wr = await asyncio.open_connection('127.0.0.1', port)
  wr.write(b'hello')
  await wr.drain()
  data = await rd.read(1024)
  assert data == b'hello'
  wr.close()
  await wr.wait_closed()
  print("OK")

async def test(port):
  stask = asyncio.create_task(server(port))
  await asyncio.sleep(0.1)
  ctask = asyncio.create_task(client(port))
  await asyncio.wait([ ctask])
  stask.cancel()
  await asyncio.wait([ stask])

if __name__ == "__main__":
   asyncio.run(test(8080))
  
