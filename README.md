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

### Creating Context

- option 1

1. append `vagrant ssh-config <hostname>` output into `~/.ssh/config.d/vagrant_swarmgs ` (or `~/.ssh/config`)
2. run
```
  docker context create \
    --docker "host=ssh://<hostname>" \
    --default-stack-orchestrator swarm \
    <hostname>
```

- option 2:

    - use shell script `./labs/vagrants/host/host-setup.sh`

### Show docker node info

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

### Visualizing Cluster

1. context master node `docker context use <nodemaster>` or use `vagrant ssh m1` if contexts aren't setup
2. run 
```
docker -c m1 \
  container run -d \
  -p "8080:8080/tcp" \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  dockersamples/visualizer
```
3. for portainer, download `curl -L https://downloads.portainer.io/ce2-18/portainer-agent-stack.yml -o portainer-agent-stack.yml` and run `docker stack deploy -c portainer-agent-stack.yml portainer`
4. for swarmpit, run
```
docker run -it --rm \
  --name swarmpit-installer \
  --volume /var/run/docker.sock:/var/run/docker.sock \
swarmpit/install:1.9
```


### Testing visualization of node addition

1. add another worker node `vagrant up w2`
2. create context `./labs/vagrants/host/host-setup.sh`
3. join `w2` to master node
    - context master `docker context use m1` node
    - run `docker swarm join-token worker`, copy the token and ip address
    - context `docker context use w2` worker node
    - paste the token and ip address
4. check portainer and visualizer dashboard or run `docker node ls`

### Simulating power loss and Observing node status

1. run `vagrant halt w1`
2. check `docker node ls` and visualizer dashboard
3. bring it back online `vagrant halt w1`
4. and check again

### Adding another manager node

1. add manager node `vagrant up m2`
2. create context
3. join `m2` to `m1`
  - context to m1 `docker context use m1`
  - run `docker swarm join-token manager` and copy the token
  - context to m2 and paste it
4. check `docker node ls`

### Play with Docker

1. go to https://labs.play-with-docker.com/
2. create some instances or use template
3. copy `ssh ip*@direct.labs.play-with-docker.com` 
4. create context by running `docker context create --docker "host=ssh://ip172-18-0-53-chdtmsae69v000f9aou0@direct.labs.play-with-docker.com" man1`
5. check node list in the lab,  `docker -c man1 node ls`

### Updating service

``` 
docker service update --force <service_name>
```

### Watch service

- option 1

```
watch -t -d -n -0.5 docker service ps viz
```

- option 2

```
watch -t -d -n -0.5 docker service ps --format "table {{.ID}}\t{{.Name}}\t{{.Node}}\t{{.DesiredState}}\t{{.CurrentState}}" viz
```

- option 3

```
docker service ps --format "{{json .}}" viz | jq
```

### Kill container

1. context to node where service place
2. run `docker container ps` and get the container name
3. run `docker container kill <container-name>`

## DEPLOYING APPS WITH STACKS

**Fully automate creating node**

1. go to `./labs/autos/Vagrantfile` and run `vagrant up`
2. create context using script `./labs/vagrants/host/host-setup.sh`


### Understanding reconciliation by draining a manager node

```
docker node update --availability ("active"|"pause"|"drain") hostname
```

pause means don't add any work to me
drain means don't give me any new work

### Install visualization service

```
docker service create \
  --name=viz \
  --publish=8081:8080/tcp \
  --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  dockersamples/visualizer

```

### Creating service

```
docker service create \
  --name=viz \
  --publish=8081:8080/tcp \
  --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  dockersamples/visualizer

```

### Updating service

```
docker service update \
  --constraint-add node.role==manager \
  viz
```

check the updated service: `docker service inspect viz`


### Troubleshooting/Check log

***option 1***

```
docker service logs --follow <name service>
```

***option 2***

```
docker events --since 50m
```

***option 3***
```
docker stack ps <stack name> --no-trunc
```

### Testing Replicated Stack

1. chrome://net-internals/#sockets
