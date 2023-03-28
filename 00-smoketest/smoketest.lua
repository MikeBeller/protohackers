local copas = require("copas")
local socket = require("socket")

local address = "*"
local port = 9999

local server_socket = assert(socket.bind(address, port))

local function connection_handler(skt)
    while true do
        local data, err = skt:receivepartial("*a")
        if err ~= nil then
            skt:close()
            break
        end
        skt:send(data)
    end
end

copas.addserver(server_socket, copas.handler(connection_handler), "smoketest")

copas()
