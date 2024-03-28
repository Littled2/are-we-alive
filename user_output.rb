require 'rainbow/refinement'

require_relative "status"
require_relative "database"



# Print the status of the network
def print_cluster_status

    nodes = get_nodes

    states = multiple_node_status nodes

    formatted = [ [ "Name", "Host", "Port", "Status" ] ]

    states.each do |server|
        formatted.push([
            server["name"],
            server["host"],
            server["port"],
            server["status"] != nil ? Rainbow("Online").green : Rainbow("Offline").red
        ])
    end

    print_table(formatted)

end

def print_table(rows)

    puts "\n\n"

    greatest_len = 0

    rows.each do |cols|
        cols.each do |cell|
            if cell.to_s.length > greatest_len
                greatest_len = cell.to_s.length
            end
        end
    end

    rows.each_with_index do |cols, index|

        row = ""

        cols.each do |cell|
            
            if index == 0
                row << Rainbow(cell.to_s.ljust(greatest_len + 2)).bright
            else
                row << cell.to_s.ljust(greatest_len + 2)
            end

        end

        puts row
    end

    puts "\n\n"

end