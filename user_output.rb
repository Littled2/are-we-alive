require 'terminal-table'

require_relative "status"
require_relative "database"


# Print the status of the network
def print_cluster_status

    nodes = get_nodes

    states = multiple_node_status nodes

    formatted = [ "Name", "Host", "Port", "Status" ]

    states.each do |server|
        formatted << [
            server["name"],
            server["host"],
            server["port"],
            server["status"]
        ]
    end

    table = Terminal::Table.new :rows => formatted

    puts table

end