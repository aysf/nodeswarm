docker service create \
  --name=viz \
  --publish=8081:8080/tcp \
  --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  dockersamples/visualizer

docker service update \
  --constraint-add node.role==manager \
  viz