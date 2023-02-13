import asyncio

async def tcp_echo_server():
    server = await asyncio.start_server(echo_server, host="127.0.0.1", port=9999)
    async with server:
        await server.serve_forever()

async def echo_server(reader, writer):
    print("Connection from:", writer.get_extra_info("peername"))
    while True:
        data = await reader.read(1024)
        if not data:
            break
        print("received:", data.decode())
        writer.write(data)
        await writer.drain()
        print("sent: %r" % data.decode())
    writer.close()
    await writer.wait_closed()

print("Starting server")
asyncio.run(tcp_echo_server())
