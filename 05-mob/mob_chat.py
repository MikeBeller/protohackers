import asyncio
import logging
import sys
import re

TONY_ADDRESS = "7YWHMfk9JZe0LM0g1ZauHuiSxhI"
CHAT_PORT = 16963
CHAT_ADDRESS = "chat.protohackers.com"
BCRE = r'7[0-9a-zA-Z]{25,34}'

logging.basicConfig(level=logging.DEBUG, format='%(name)s: %(message)s', stream=sys.stderr)

connections = set()

async def handle_client(reader, writer):
    peer = writer.get_extra_info('peername')
    logging.debug(f'client connected: {peer}, connections: {connections}')
    (upstream_reader, upstream_writer) = await asyncio.open_connection(CHAT_ADDRESS, CHAT_PORT)
    logging.debug('connected to upstream chat server')
    up_task = asyncio.create_task(pipe(reader, upstream_writer))
    down_task = asyncio.create_task(pipe(upstream_reader, writer))
    connections.add(peer)
    await asyncio.wait([up_task, down_task])
    connections.remove(peer)

def rewrite_message(message):
    words = re.split('(\s+)', message)
    for i, word in enumerate(words):
        if re.fullmatch(BCRE, word):
            words[i] = TONY_ADDRESS
    return ''.join(words)
    
async def pipe(reader, writer):
    while True:
        message = (await reader.readline()).decode()
        if not message:
            break
        rewritten_message = rewrite_message(message)
        writer.write(rewritten_message.encode())
        await writer.drain()

async def main():
    server = await asyncio.start_server(handle_client, 'localhost', 9999)
    addr = server.sockets[0].getsockname()
    logging.debug('serving on {}'.format(addr))
    try:
        await server.serve_forever()
    except KeyboardInterrupt:
        pass

    # close the server
    server.close()
    await server.wait_closed()

assert re.fullmatch(BCRE, TONY_ADDRESS)
assert re.fullmatch(BCRE, "7F1u3wSD5RbOHQmupo9nx4TnhQ")

if __name__ == '__main__':
    asyncio.run(main())
