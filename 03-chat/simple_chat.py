# Create an asynchronous TCP chat server in Python 3 that can handle multiple clients
# in a single room.  The server will announce the arrival and departure of clients,
# and will echo messages from clients to all other clients.
# This is a simple chat server that does not use threads or processes.
# It uses the coroutines capability of the asyncio module to handle multiple
# clients in a single process.

import asyncio
import logging
import sys

logging.basicConfig(level=logging.DEBUG, format='%(name)s: %(message)s', stream=sys.stderr)

writers = []

async def handle_client(reader, writer):
    logging.debug('client connected: {}'.format(writer.get_extra_info('peername')))
    writer.write('Welcome to the chat server! -- Enter name: '.encode())
    await writer.drain()
    name = (await reader.readline()).decode().strip()
    message = '*** {} has joined the chat ***'.format(name)
    logging.debug('sending: {!r}'.format(message))
    for writer in writers:
        writer.write(message.encode())
        await writer.drain()
    writers.append(writer)

    # wait for messages from client
    while True:
        message = (await reader.readline()).decode().strip() + "\n"
        if not message:
            break
        message = '<{}> {}'.format(name, message)
        logging.debug('sending: {!r}'.format(message))
        for writer in writers:
            writer.write(message.encode())
            await writer.drain()

    # client disconnected
    logging.debug('client disconnected: {}'.format(writer.get_extra_info('peername')))
    writers.remove(writer)
    message = '*** {} has left the chat ***'.format(name)
    logging.debug('sending: {!r}'.format(message))
    for writer in writers:
        writer.write(message.encode())
        await writer.drain()
    writer.close()

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

if __name__ == '__main__':
    # run event loop
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())
    loop.close()
