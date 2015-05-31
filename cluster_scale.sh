#!/bin/sh
#
#
THRESHOLD=30
SLEEP=10
DOCKER_COMPOSE=/home/stalker/DEVEL/ducc/docker/docker-compose

while true; do
	agent_nodes=`$DOCKER_COMPOSE ps | grep 'agent' | wc -l`

	cluster_util=`curl -s http://localhost:42133/ducc-servlet/cluster-utilization | sed 's/%//g'`
	we_need_more=`echo "$cluster_util > $THRESHOLD" | bc -l`

	if [ $we_need_more = "1" ]; then
		echo "ACTION: Increasing count of agents to $agent_nodes + 1 and sleep for a minute: "
		$DOCKER_COMPOSE scale agent=`echo "$agent_nodes + 1" | bc -q`
		sleep 60
	fi

	jobs_active=`curl -s http://localhost:42133/ducc-servlet/classic-jobs-data | sed 's/tr/\n/g' | grep active_state | wc -l`
	if [ "$jobs_active" = "0" ] && [ $agent_nodes -gt 1  ]; then
		echo "ACTION: No active jobs for the moment, so shutdowning all agents:"
		$DOCKER_COMPOSE scale agent=1
	fi

	echo `date +%r` "Cluster utilization: $cluster_util%; Active agent nodes: $agent_nodes; Active jobs: $jobs_active"
	sleep $SLEEP
done
