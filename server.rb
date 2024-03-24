require "sqlite3"
require "webrick"
require 'json'

require_relative "status"
require_relative "database"
require_relative "security"



server = WEBrick::HTTPServer.new(Port: 2499)




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


server.mount_proc '/push' do |req, res|
    if req.request_method == 'POST'

        change = JSON.parse(req.body)

        puts "Recived change id:" + change["id"].to_s
        
        # Has this change already been appplied?
        if db_state < change["id"]

            # Apply the change locally
            apply_change(change["id"], change["action"], change["data"])

            push_change(change["id"], change["action"], change["data"])

            res.body = "Change applied"
        else
            # Change has already been applied
            res.body = "Change already applied"
        end
        

      else
        res.status = 405
        res['Allow'] = 'POST'
        res.body = ['Method Not Allowed']
      end
end


# ON START:
# Sync with network

sync_state_with_network



trap('INT') { server.shutdown }

server.start





