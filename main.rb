require "sqlite3"
require "webrick"
require 'json'


runmode = ARGV.first

if runmode == nil || (runmode != "server" && runmode != "status")
    puts "No/invalid runmode specified! Please pass either server or status as an argument"
    exit
end

puts "Running in " + runmode + " mode"

require_relative "status"
require_relative "database"
require_relative "security"
require_relative "user_input"
require_relative "user_output"
require_relative "cluster.rb"


# Get config info

cluster_info = nil

if !File.exist?(Dir.pwd << "/cluster_info.json")
    puts "cluster_info.json file does not exist! This must be in the root directory"
    exit
end

begin
    cluster_info = read_cluster_info
rescue
    puts "Error reading + parsing cluster_info.json file"
    exit
end



server = WEBrick::HTTPServer.new(Port: cluster_info["my_port"])




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



# If server, listen for requests
if runmode == "server"
    
    is_first_node = gets_bool? "Is this the first node in the cluster?"

    if !is_first_node

        sync_state_with_network

    end

    # Has this node been added before?
    add_self_if_not_in_db(cluster_info["my_name"], cluster_info["my_host"], cluster_info["my_port"])
    

    trap('INT') { server.shutdown }

    server.start

end



# If status, get node status
if runmode == "status"

    sync_state_with_network

    print_cluster_status
    
    exit

end