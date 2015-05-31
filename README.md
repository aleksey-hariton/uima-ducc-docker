# uima-ducc-docker

This project help you to setup UIMA DUCC cluster locally with Docker

## Finished tasks

**Check points**
- [x] Container for DUCC (follow best practices for Docker build file)
- [x] Data persistence for experiment results and logs (after DUCC agent removal)
- [x] Support multi-user mode with duccling
- [x] Script to spin up cluster with arbitrary configuration (docker-compose preferably or bash)
- [x] Run simple UIMA job (from samples) which will be distributed across several agent nodes
- [x] Configure 3 agent node pools (compute-optimized, memory-optimized, general-use).
- [x] Cluster should support automatic detection of agent addition/removal
- [x] Implement autoscaling based on currently running jobs (when there is starvation of memory shares - add more nodes; remove nodes when there are no jobs running)
- [ ] Propose testing solution for containers, write some tests for this infrastructure
 
**Documentation**
- [x] Architecture high-level design
- [x] User guides (how to bootstrap cluster, how to modify configuration, how to run jobs, how autoscaling works)

## Architecture high-level design

**Attention!** in this doc doents describes DUCC architecture, only for clustering solution. For more information about UIMA DUCC arch look at ["UIMA DUCC book"](http://uima.apache.org/d/uima-ducc-1.0.0/duccbook.html#x1-70001.1).

Diagram of solution architecture:

![alt tag](https://raw.githubusercontent.com/aleksey-hariton/uima-ducc-docker/master/res/arch.png)

* **head** - master node in DUCC UIMA cluster
* **agentN** - agent node in DUCC UIMA cluster
* **./jobs/** - shared folder between **head** node and host node for jobs
* **./results/** - shared folder between **head** node and host node for jobs results
* **:2222** - exposed SSH port to get access to **head** via SSH
* **:42133, :42155** - exposed port to get access to DUCC cluster web interface
* **run.sh** - script for preparation of **head** and **agent** nodes. On agent node script also automaically (based on its *hosts* file, change by Docker --link option) determines **head** node, adding itself to head's hosts file and ducc.nodes file and start agent from **head** node.
* **cluster_scale.sh** - scipt for cluster auto scaling, for more information please look at **Cluster autoscaling** section of this guide

**File list**

```bash
# head node files
./ducc-head
# run script (CMD) for head
./ducc-head/run.sh
# Docker doesnt support symlincs for COPY/ADD so archives placed here. Initialy was used 'wget' but it's too slow for testing purposes
./ducc-head/uima-ducc-1.1.0-bin.tar.gz
# Public and private keys (should be the same for head and agent)
./ducc-head/id_rsa
./ducc-head/id_rsa.pub
# Dockerfile
./ducc-head/Dockerfile

# agent node files
./ducc-agent
# run script (CMD) for agent
./ducc-agent/run.sh
# see above
./ducc-agent/uima-ducc-1.1.0-bin.tar.gz
# Public and private keys (should be the same for head and agent)
./ducc-agent/id_rsa
./ducc-agent/id_rsa.pub
# Dockerfile
./ducc-agent/Dockerfile


# Resources for documentation
./res
./res/arch.png
./res/arch.graphml

# jobs and results folders (mounted to head container)
./jobs
./results


# Sample config for docker-compose
./docker-compose.yml

# Cluster auto-scale script
./cluster_scale.sh
```


## Prerequisites

* Install Docker - https://docs.docker.com/installation/#installation
* Install Docker Compose (not mandatory) - https://docs.docker.com/compose/install/#install-compose

Clone this repository to your PC:

```shell
git clone https://github.com/aleksey-hariton/uima-ducc-docker.git
```

And use simple Docker or Docker compose instructions

## How to bootstrap cluster with Docker

To bootstrap new DUCC cluster with pure Docker:
* Build **ducc-head** and **ducc-agent** images:
```shell
docker build -t ducc-head ducc-head/
docker build -t ducc-agent ducc-agent/
```
* Run one *head* server:
```shell
docker run -t -i -p 42133:42133 -p 42155:42155 -p 2222:22 -v $(pwd)/results/:/tmp/res/ -v $(pwd)/jobs/:/tmp/jobs/ -d --name head ducc-head
```
* Then run as much *agent* servers as you wish, all new agent nodes (agent1, agent2... etc.) will be added to cluster automatically:
```shell
docker run -t -i -d --name agent1 ducc-agent
```
* Go to http://localhost:42133/ to open web interface of your new UIMA DUCC cluster

If you want to add new agent nodes, just repeat step 3.

## How to bootstrap cluster with Docker-compose

First of all ensure that you have installed docker-compose (check *Prerequisites* section of this doc).

For cluster spin-up just run two commands:

```shell
docker-compose build
docker-compose up -d
```

This command will setup one DUCC head node and one agent node (you will have 2 agent nodes, one already installed on head server)

To increase count of agent nodes up to 3, run folowing command:

```shell
docker-compose scale agent=3
```

**OR**

you can just change **docker-compose.yml** file to have pre-configured cluster setup:

```yaml
...
agent:
  links:
   - head
  build: ./ducc-agent/
agent1:
  links:
   - head
  build: ./ducc-agent/
agent2:
  links:
   - head
  build: ./ducc-agent/
```

and run *docker-compose up -d*.

## How to run jobs

You can place your jobs into ./jobs/ folder (*/tmp/jobs/* in **head** container) or use example provided with DUCC distro.
Login to **head** container and submit new job:

```shell
ssh -p 2222 -i res/id_rsa root@localhost
cd /home/ducc/apache-uima-ducc/bin/
./ducc_submit -f ../examples/simple/1.job --log_directory /tmp/res/ --working_directory /tmp/res/
```

You can check [**Jobs**](http://localhost:42133/jobs.jsp) section of DUCC web interface or check [**Viz**](http://localhost:42133/viz.jsp) section for visualisation where your job placed.

Please note that results will be placed into */tmp/res/* folder of **head** container, which equal to local folder *./results/* of this repository.

## Cluster autoscaling

Cluster auto scaling implemented with Docker compose and script **cluster_scale.sh**.
Before you run, change in script values:
* **THRESHOLD** - cluster utilization in %, after which script will start new agent node
* **SLEEP** - time in seconds between status update
* **DOCKER_COMPOSE** - path to *docker-compose* binary or set to **docker-compose** if i in $PATH

```bash
./cluster_scale.sh
```

Each $SLEEP seconds (10 by default) script will show status:

```
11:51:58 Cluster utilization: 3.3%; Active agent nodes: 1; Active jobs: 0
```

And if any action needed it will show messages like this:

```
ACTION: Increasing count of agents to 1 + 1 and sleep for a minute
```

If more nodes required or:

```
ACTION: No active jobs for the moment, so shutdowning all agents
```

if no active jobs left and script killall agent nodes.

## Support multi-user mode with duccling

If you want use more secure service with DUCC, you can enable DUCC web interface authorization (based on container system users):

* Login to **head** node and change *ducc.properties* file and enable **ducc.ws.login.enabled** option:
```bash
ssh -p 2222 -i res/id_rsa root@localhost
cd /home/ducc/apache-uima-ducc/resources/
vi ducc.properties


# ducc.ws.login.enabled = false
ducc.ws.login.enabled = true
```
* Now create new user on **head** node and all **agent** nodes:
```bash
useradd -m newuser -s /bin/bash
passwd newuser
```

Now you can use **Login** link in web interface and all your jobs will be submited by newly created user.

## Configuring of additional node pools

For more information please visit ["DUCC book"](http://uima.apache.org/d/uima-ducc-1.0.0/duccbook.html#x1-18800012.3)

To specify new nodepool change file **resources/ducc.classes** on **head** node.
Insert you changes after *default* nodepool defenition.

```json
Nodepool --default--  { }
```

