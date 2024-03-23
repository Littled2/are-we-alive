require 'net/http'
require 'json'
require 'macaddr'

require_relative "security"
require_relative "database"


$mac_addr = Mac.addr


# Get self status
def self_status
    return {
        "macaddr" => $mac_addr,
        "db_state" => db_state,
        "time" => Time.now.to_i
    }
end


# Get the status of other servers
def server_status(host, port)
    begin
        response = Net::HTTP.get_response(host, "/ping", port = port).body
        return JSON.parse(response)
    rescue => e
        puts e
        return nil
    end
end


def multiple_node_status(servers)

    puts "Getting multiple node status"

    statuses = []

    servers.each do |server|

        puts "Getting server status for:  ADDRESS: " + server["host"] + "  PORT: " + server["port"]

        statuses << {
            **server,
            "status" => server_status(server["host"], server["port"])
        }
    end

    return statuses
end
