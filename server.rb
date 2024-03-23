require "sqlite3"
require "webrick"
require 'json'

require_relative "status"
require_relative "database"
require_relative "security"



server = WEBrick::HTTPServer.new(Port: 2500)




server.mount_proc '/ping' do |req, res|

    res['Content-Type'] = 'application/json'

    res.body = { "status" => self_status }.to_json

end




server.mount_proc '/status' do |req, res|
    
    res['Content-Type'] = 'application/json'

    servers = get_nodes

    res.body = multiple_node_status(servers).to_json

end


server.mount_proc '/sync' do |req, res|

    # Called by another node who wants to sync with us

    # 1. Get the node's state from their request
    if req.query.key?("state")
        
        # If the other node's state is less than this node's, send all changes since then

        changes = nodes_changes_since req.query["state"].to_i

        res['Content-Type'] = 'application/json'

        res.body = changes.to_json
    end
end


server.mount_proc '/sync' do |req, res|

    # Called by another node who wants to sync with us

    # 1. Get the node's state from their request
    if req.query.key?("state")
        
        # If the other node's state is less than this node's, send all changes since then

        changes = nodes_changes_since req.query["state"].to_i

        res['Content-Type'] = 'application/json'

        res.body = changes.to_json
    end
end



# ON START:
# Sync with network

# sync_state_with_network



trap('INT') { server.shutdown }

server.start





