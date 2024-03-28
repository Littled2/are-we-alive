require "sqlite3"
require "json"

require_relative "user_input"
require_relative "status"


$db = SQLite3::Database.new 'data.db'


# Initialise the database

puts "Initialising database"

$db.execute <<~SQL

    CREATE TABLE IF NOT EXISTS `nodes` (
        id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
        name TEXT,
        host TEXT,
        port TEXT
    )

SQL

$db.execute <<~SQL

    CREATE TABLE IF NOT EXISTS `nodes_changes` (
        id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
        action TEXT,
        data TEXT   
    )

SQL









def get_nodes

    rows = $db.execute('SELECT * FROM nodes')

    servers = []

    rows.each do |row|

        server = {
            "id" => row[0],
            "name" => row[1],
            "host" => row[2],
            "port" => row[3]
        }

        servers << server

    end

    return servers
end



def get_node(name, desc, address)
    insert_statement = $db.prepare('INSERT INTO nodes (name, desc, address) VALUES (?, ?, ?)')
    insert_statement.execute(name, desc, address)
    insert_statement.close
end



def edit_node(id, name, desc, address)
    $db.execute('UPDATE nodes SET name = ?, desc = ?, address = ? WHERE id = ?', name, desc, address)
    $db.execute('INSERT INTO nodes_changes (action, data) VALUES (?, ?)', "UPDATE", "DATA BLOB HERE")
end


# Returns the state of the local database
def db_state

    res = $db.execute("SELECT MAX(id) as state FROM nodes_changes")

    if res[0][0] == nil
        return -1
    else
        return res[0][0]
    end
end


def sync_state_with_network

    puts "Syncing node with network"

    nodes = get_nodes

    to_sync_with = {
        "name" => "unknown node",
        "host" => "",
        "port" => ""
    }


    puts "Gettign sync data from host:" + to_sync_with["host"] + " port:" + to_sync_with["port"]

    current_state = db_state

    synced = false
    sample_index = 0

    while !synced

        # Are there any nodes in the database?
        if nodes.length === 0
            puts "No existing nodes!"
            to_sync_with["host"] = gets_string("Please input the hostname of an existing node:")
            to_sync_with["port"] = gets_string("Please input the port for this hostname:")
        else
            random_node = nodes[sample_index]
            puts "Existing node detected. Using host:" + random_node["host"] + " port:" + random_node["port"]
            to_sync_with["host"] = random_node["host"]
            to_sync_with["port"] = random_node["port"]
        end

        begin
            changes = network_changes_since_state(current_state, to_sync_with["host"], to_sync_with["port"])
            synced = true
            sample_index += 1
        rescue => error
            puts "Error syncing with network"
            puts error
            throw "sync_failed"
        end
        
    end
    
    

    puts "Changes detected: " + changes.length.to_s

    changes.each do |change|
        begin
            puts "Applying change id: " + change[0].to_s

            apply_change(change[0], change[1], change[2])
        rescue => error
            puts "ERROR APPLYING CHANGES, CANNOT CONTINUE"
            puts error
            throw "sync_failed"
        end
    end

    puts "Sync OK :)"

end


# Gets the changes since a particular change ID
def nodes_changes_since(change_id)
    return $db.execute("SELECT * FROM nodes_changes WHERE id > ?", change_id)
end

# Get changes to db since current state
def network_changes_since_state(state, host, port)
    response = Net::HTTP.get_response(host, path = "/sync?state=" + state.to_s, port = port).body
    return JSON.parse(response)
end


def apply_change(change_id, action, raw_data)

    parsed_data = JSON.parse(raw_data)

    if action == "CREATE"
        apply_create_change(parsed_data["name"], parsed_data["host"], parsed_data["port"])
    elsif action == "UPDATE"
        apply_update_change(parsed_data["id"], parsed_data["name"], parsed_data["host"], parsed_data["port"])
    elsif action == "DELETE"
        apply_delete_change(parsed_data["id"])
    end

    # Record the change
    record_change(change_id, action, raw_data)
end



def apply_create_change(name, host, port)
    $db.execute("INSERT INTO nodes ( name, host, port ) VALUES ( ?, ?, ? )", name, host, port)
end



def apply_update_change(id, name, host, port)
    $db.execute("UPDATE nodes SET name = ?, host = ?, port = ? WHERE id = ?", id, name, host, port)
end



def apply_delete_change(id)
    $db.execute("DELETE FROM nodes WHERE id = ?", id)
end



# Writes a change to the nodes_changes table
def record_change(id, action, data)
    if id != -1
        $db.execute("INSERT INTO nodes_changes ( id, action, data ) VALUES ( ?, ?, ? )", id, action, data)
    else
        $db.execute("INSERT INTO nodes_changes ( action, data ) VALUES ( ?, ? )", action, data)
    end
end



# Sync the rest of the cluster with a recent change
def push_change(id, action, data)

    nodes = get_nodes

    nodes.each do |node|
        begin
            puts "Pushing change to #{node["host"]}:#{node["port"]}"
            push_change_to_node(node["host"], node["port"], id, action, data)
        rescue => error
            puts "Error whilst pushing change to #{node["host"]}:#{node["port"]}"
            puts error
        end
    end
end


# Push change to specific node
def push_change_to_node(host, port, id, action, data)

    json_data = {
            "id" => id,
            "action" => action,
            "data" => data
    }.to_json

    uri = URI('http://' + host + ":" + port + "/push")
    headers = { 'Content-Type': 'application/json' }
    response = Net::HTTP.post(uri, json_data, headers)

    puts "Pushed change id:#{id} to #{host}:#{port} OK"

end