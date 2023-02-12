import asyncio

async def tcp_echo_server():
    server = await asyncio.start_server(connect, host="0.0.0.0", port=9999)
    async with server:
        await server.serve_forever()

async def connect(reader, writer):
    while True:
        data = await reader.read(-1)
        if not data:
            break
        writer.write(data)
        await writer.drain()
    writer.close()
    await writer.wait_closed()

print("Starting server")
asyncio.run(tcp_echo_server())
