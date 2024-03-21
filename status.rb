require 'net/http'
require 'json'
require 'macaddr'

require_relative "security"


$mac_addr = Mac.addr


# Get self status
def self_status
    return {
        "macaddr" => $mac_addr,
        "time" => Time.now.to_i
    }
end


# Get the status of other servers
def server_status(host, port)
    begin
        response = Net::HTTP.get_response(host, "/ping", { "Cluster" => cluster_name }, port = port).body
        return JSON.parse(response)
    rescue => e
        puts e
        return nil
    end
end


def multiple_node_status(servers)

    statuses = []

    servers.each do |server|
        statuses << {
            **server,
            "status" => server_status(server["address"], server["port"])
        }
    end

    return statuses
end
