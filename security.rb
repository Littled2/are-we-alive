require "json"

# Check a request has a cluster header and the cluster is valid
def valid_cluster?(text_name)
    if(test_name == cluster_info["name"])
        return true
    else
        return false
    end
end


# Does the request have the correct security headers
def check_request?(req)
    # Check for Cluster header
    if req["Cluster"]
        # Check Cluter header
        return valid_cluster(req["Cluster"])
    else
        return false
    end
end