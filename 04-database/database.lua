local socket = require("socket")
local PORT = 9999

function main(port)
    data = {}
    local sock = socket.udp()
    sock:setsockname("*", port)
    while true do
        local msg, ip, port = sock:receivefrom()
        print("received", msg, ip, port)
        local key, val = msg:match("([^=]*)=?(.*)")
        if val ~= nil and val ~= "" then
            data[key] = val
        else
            val = (key == "version") and "1.0" or (data[key] or "")
            msg = key .. "=" .. val
            print("sending", msg, ip, port)
            sock:sendto(msg, ip, port)
        end
    end
end

main(PORT)


