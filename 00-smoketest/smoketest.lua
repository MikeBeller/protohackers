local copas = require("copas")
local socket = require("socket")

local address = "*"
local port = 9999

local server_socket = assert(socket.bind(address, port))

local function connection_handler(skt)
    print("got new connection")
    while true do
        local data, err, partial = skt:receivepartial("*a")
        --print("got data: ", data, err, partial)
        if err == "closed" then
            skt:close()
            print("connection closed")
            break
        end
        if data then
            skt:send(data)
        end
        if partial then
            skt:send(partial)
        end
    end
end

copas.addserver(server_socket, copas.handler(connection_handler), "smoketest")

copas()
