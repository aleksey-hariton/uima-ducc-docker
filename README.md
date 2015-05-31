# uima-ducc-docker

## Finished tasks

**Check points**
- [x] Container for DUCC (follow best practices for Docker build file)
- [ ] Data persistence for experiment results and logs (after DUCC agent removal)
- [ ] Support multi-user mode with duccling
- [x] Script to spin up cluster with arbitrary configuration (docker-compose preferably or bash)
- [x] Run simple UIMA job (from samples) which will be distributed across several agent nodes
- [ ] Configure 3 agent node pools (compute-optimized, memory-optimized, general-use).
- [x] Cluster should support automatic detection of agent addition/removal
- [ ] Implement autoscaling based on currently running jobs (when there is starvation of memory shares - add more nodes; remove nodes when there are no jobs running)
- [ ] Propose testing solution for containers, write some tests for this infrastructure
 
**Documentation**
- [ ] Architecture high-level design
- [x] User guides (how to bootstrap cluster, how to modify configuration, how to run jobs, how autoscaling works)

## Architecture high-level design

*img of arch*


## User guides

This project help you to setup UIMA DUCC cluster locally with Docker

### Prerequisites

* Install Docker - https://docs.docker.com/installation/#installation
* Install Docker Compose (not mandatory) - https://docs.docker.com/compose/install/#install-compose

Clone this repository to your PC:

```shell
git clone https://github.com/aleksey-hariton/uima-ducc-docker.git
```

And use simple Docker or Docker compose instructions

### How to bootstrap cluster with Docker

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

### How to bootstrap cluster with Docker-compose

First of all ensure that you have installed docker-compose (check *Prerequisites* section of this doc).

For cluster spin-up just run two commands:

```shell
docker-compose up -d
```

This command will setup one DUCC head node and one agent node (you will have 2 agent nodes, one already installed on head server)

To increase count of agent nodes up to 3, run folowing command:

```shell
docker-compose scale agent=3
```

*OR*

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

### How to run jobs

You can place your jobs into ./jobs/ folder (*/tmp/jobs/* in **head** container) or use example provided with DUCC distro.
Login to **head** container and submit new job:

```bash session
ssh -p 2222 -i res/id_rsa root@localhost
cd /home/ducc/apache-uima-ducc/bin/
./ducc_submit -f ../examples/simple/1.job --log_directory /tmp/res/ --working_directory /tmp/res/
```

You can check [**Jobs**](http://localhost:42133/jobs.jsp) section of DUCC web interface or check [**Viz**](http://localhost:42133/viz.jsp) section for visualisation where your job placed.

Please note that results will be placed into /tmp/res/ folder of **head** container, which equal to local folder ./results/ of this repository.
