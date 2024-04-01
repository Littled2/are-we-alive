# Gets the name of the cluster from the cluster file
def read_cluster_info

    file_path = Dir.pwd << "/cluster_info.json"
    info = JSON.parse(File.read(file_path))

    if !info.key?("my_host")
        puts "property my_host not in cluster_info.json"
        raise "property my_host not in cluster_info.json"
    end

    if !info.key?("my_port")
        puts "property my_port not in cluster_info.json"
        raise "property my_port not in cluster_info.json"
    end

    if !info.key?("my_name")
        puts "property my_name not in cluster_info.json"
        raise "property my_name not in cluster_info.json"
    end


    info["my_port"] = info["my_port"].to_i

    return info
end

# cluster_info.name