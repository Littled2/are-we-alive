# Gets the name of the cluster from the cluster file
def cluster_info
    file_path = Dir.pwd << "/cluster_info.json"
    return JSON.parse(File.read(file_path))
end

# cluster_info.name