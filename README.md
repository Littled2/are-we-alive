# are-we-alive

A simple tool for quickly assessing the status of multiple servers, within a cluster.

## Quick Start

### Prerequisites
- *Ruby must be installed on the nodes for are-we-alive to run.*
- Before running are-we-alive, you must add a `cluster_info.json` file. This is where we define the hostname, port and name of a node.

The `cluster_info.json` file must contain the following properties:
```json
{
    "my_name": "<node_name>",
    "my_host": "<hostname>",
    "my_port": "<port>"
}
```
Adapt these for your use case.


### Running in `server` mode
The `server` mode is used for nodes that exist on your cluster. To run are-we-alive in `server` mode, clone the repo to the node machine, navigate into the repo directory and then run the command:
```
ruby ./main.rb server
```
The software will ask you if this is the first node in a cluster or not. Follow the prompts wo wither sync the node with an existing cluster or set up a new one.

### Running in `status` mode
`status` mode is used to check the status of each node in a cluster. When run in this mode, are-we-alive will output a table displaying the statuses of each node in the cluster.

To run are-we-alive in `status` mode, run the command:
```
ruby ./main.rb status
```

Example output:




## How it works

The program runs on all servers, forming a cluster.

When the program is contacted by an administrator, it pings all other servers in the cluster for their statuses and returns it.


### How all nodes hold the same data
1. Assume the cluster can only be edited from one place at a time

This way, a single integer can be used to track all changes to the database.

When a node is updated, then it sends out this update to all other nodes on the network.

When a node `p` is added to the network, it broadcasts its db `state(p)` to a random other node `x`.

If `state(p) < state(x)`, then node `x` responds with all updates it has received singe that time.


### Database schema

The database holds a list of `nodes` (servers). It also holds a list of sequential updates to this list `nodes_changes`.


| `nodes_changes` |                  |
| --------------- | ---------------- |
| id              | The incremental ID of the update |
| action          | Can be 'UPDATE', 'CREATE' or 'DELETE' |
| data            | The data in question, NULL if action is 'DELETE' | 


| action | properties that `data` must contain |
| ------ | ----------------------------------- |
| CREATE | name, host, port |
| UPDATE | id, name, host, port |
| DELETE | id |



## Planning how to code the database bits

1. Lets first deal with how a new node will sync with existing nodes when it is added to the network

- In this case the new node MUST know about the existence of at least one other node.

- If the node already has a node in the database, it should select a random one from there, otherwise it will ask the user for the hostname & port of the existing host

- The new node will ask the existing host for its db state. If this state is greater than its current, then the existing node should return all changes to the database since that point.