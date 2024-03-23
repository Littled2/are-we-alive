require "sqlite3"
require "json"

require_relative "user_input"
require_relative "status.rb"


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

puts "nodes table OK"

$db.execute <<~SQL

    CREATE TABLE IF NOT EXISTS `nodes_changes` (
        id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
        action TEXT,
        data TEXT   
    )

SQL

puts "nodes_changes table OK"









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

    # are there any nodes in the database?
    if nodes.length === 0
        puts "No existing nodes!"
        to_sync_with["host"] = gets_string("Please input the hostname of an existing node:")
        to_sync_with["port"] = gets_string("Please input the port for this hostname:")
    else
        random_node = nodes.sample
        puts "Existing node detected. Using host:" + random_node["host"] + " port:" + random_node["port"]
        to_sync_with["host"] = random_node["host"]
        to_sync_with["port"] = random_node["port"]
    end

    puts "Gettign sync data from host:" + to_sync_with["host"] + " port:" + to_sync_with["port"]

    current_state = db_state

    # Now we have a node, we need to ask the node for their status
    puts network_changes_since_state(current_state, to_sync_with["host"], to_sync_with["port"])

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


def apply_change(change_id, action, data)

    if action == "CREATE"
        apply_create_change(data["name"], data["host"], data["port"])
    elsif action == "UPDATE"
        apply_update_change(data["id"], data["name"], data["host"], data["port"])
    elsif action == "DELETE"
        apply_delete_change(data["id"])
    end
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