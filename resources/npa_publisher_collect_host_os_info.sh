#!/bin/bash
source .npa_publisher_cronjob_env

CURRENT_DIR=$(dirname "$0")

host_os_version=`hostnamectl status | grep "Operating System" | sed "s/\s*Operating System:\s//"`
kernel_version=`hostnamectl status | grep "Kernel" | sed "s/\s*Kernel:\s//"`
docker_version=`docker version --format '{{.Server.Version}}'`
publisher_image_created_time=`docker inspect -f '{{.Created}}' new_edge_access:latest`
load_average=`cat /proc/loadavg`
if [ -d /infroot ]; then
    deployment="BWAN"
    # BWAN hostnamectl: Operating System: Netskope SASE Gateway
    host_os_version="Ubuntu $(grep '^VERSION=' /etc/os-release | cut -d= -f2 | tr -d '"' | sed 's/ (.*)//')"
else
    deployment_method=$(hostnamectl status | grep "Deployment")
    if [ -z "$deployment_method" ]; then
        deployment="Script"
    else
        deployment=$(echo "$deployment_method" | sed "s/\s*Deployment:\s//")
    fi
fi

tcp_sent=`nstat -a | grep TcpOutSegs | awk -v OFS='\t' '{print $2}'`
tcp_recv=`nstat -a | grep TcpInSegs | awk -v OFS='\t' '{print $2}'`
tcp_retrans=`nstat -a | grep TcpRetransSegs | awk -v OFS='\t' '{print $2}'`
udp_sent=`nstat -a | grep UdpOutDatagrams | awk -v OFS='\t' '{print $2}'`
udp_recv=`nstat -a | grep UdpInDatagrams | awk -v OFS='\t' '{print $2}'`

if [ -z $tcp_sent ]; then
    tcp_sent=-1
fi

if [ -z $tcp_recv ]; then
    tcp_recv=-1
fi

if [ -z $tcp_retrans ]; then
    tcp_retrans=-1
fi

if [ -z $udp_sent ]; then
    udp_sent=-1
fi

if [ -z $udp_recv ]; then
    udp_recv=-1
fi

tmp_file=$(mktemp)

cat > $tmp_file << END
{
    "host_os_version":"$host_os_version",
    "kernel_version":"$kernel_version",
    "docker_version":"$docker_version",
    "deployment":"$deployment",
    "publisher_image_created_time":"$publisher_image_created_time",
    "load_average":"$load_average",
    "tcp_sent":$tcp_sent,
    "tcp_recv":$tcp_recv,
    "tcp_retrans":$tcp_retrans,
    "udp_sent":$udp_sent,
    "udp_recv":$udp_recv
}
END

mv $tmp_file $CURRENT_DIR/host_os_info