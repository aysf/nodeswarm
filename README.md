# NodeSwarm: Learning Docker Swarm with NodeJS

**Swarm** is the entirety of your cloud deployment: the workers, the management nodes etc. You deploy to a **swarm** 
and then the swarm takes care on which machines your containers will end up running.

**Service** is the swarm equivalent of a container. It represents one single container, running on one or more machines.

**Stacks** is the swarm equivalent of Docker Compose. It represents a number of services, linked up to each other and 
deployed using a single configuration.

**Nodes**, Computers in a Swarm cluster are called nodes. Nodes can play two roles in a Swarm:
- **manager nodes** is to manage the cluster; you can execute Swarm management command on this node
- **worker nodes** is to run your containers that do the actual job (like running a web server)

source: 
- https://takacsmark.com/docker-swarm-tutorial-for-beginners/
- https://github.com/g0t4/course2-swarm-gs
- https://engineering.issuu.com/2018/09/12/confident-deployments

## Getting Started


### Running in single node

For your first deployment, we use your own laptop as single node to run node app. 

1. `docker swarm init` is to turn your local computer into a one machine Swarm cluster.
2. `docker compose build` to build an image
3. `docker stack deploy nodeapp -c docker-compose.yml` to create stack

Where `docker stack` is the management command to manage your stack deployments in the Swarm. We used 
the `deploy` subcommand to deploy the stack and we named the stack `nodeapp`. The rest of the command, 
`-c docker-compose.yml`, specifies the Compose file that describe the deployment.

Docker created the network that we defined in the Compose file and prefixed the network name with the name 
of the stack, hence the final name, `nodeapp_mynet`. Docker also created a service called `nodeapp_web`.

#### Your first scaled service

- run `docker service scale nodeapp_web=4`
- check the result `docker service ls`

#### Cleanup labs

- run `docker stack rm nodeapp`
- run `docker swarm leave --force`

## Highlight Snippets

### Explore the stack

- `docker stack ls`
- `docker stack services nodeapp`
- `docker stack ps nodeapp`

### To know docker node info

- option 1

1. check what node is on the list? `docker context ls`
2. check what current node selection? `docker context show`
3. choose what node that you want to get the info? `docker context use <hostname>`
4. run `docker info | grep -E '(Swarm|Name|Nodes|Cluster|NodeID|Node Address).*'`

- option 2

in this option, we skip context selection `context use <hostname>` with `-c <hostname>` and put command after directly.

```sh
docker -c <hostname> info | grep -E '(Swarm|Name|Nodes|Cluster|NodeID|Node Address).*'
```


### Join worker node to manager node

1. context into worker node `docker context use <worker_node>`
2. run `docker -c <master_node> swarm join-token worker`
3. copy paste and run the code like `docker swarm join --token ??? 000.000.000.000:1223`
4. to confirm run `docker system info` or `docker -c m1 node ls`