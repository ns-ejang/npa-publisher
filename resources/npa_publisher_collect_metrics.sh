#!/bin/bash

CURRENT_DIR=$(dirname "$0")

num_opened_fds=`lsof -p $(pidof npa_publisher) | wc -l`
num_tcp_conns=`netstat -tapn | grep npa_publisher | wc -l`
num_udp_conns=`netstat -uapn | grep npa_publisher | wc -l`
num_snat_conns=`conntrack -L -s 191.1.0.0 --mask-src 255.255.0.0 | wc -l`

if [ -z $num_opened_fds ]; then
    num_opened_fds=-1
fi

if [ -z $num_tcp_conns ]; then
    num_tcp_conns=-1
fi

if [ -z $num_udp_conns ]; then
    num_udp_conns=-1
fi

if [ -z $num_snat_conns ]; then
    num_snat_conns=-1
fi

tmp_file=$(mktemp)

cat > $tmp_file << END
{
    "num_opened_fds":$num_opened_fds,
    "num_tcp_conns":$num_tcp_conns,
    "num_udp_conns":$num_udp_conns,
    "num_snat_conns":$num_snat_conns
}
END

mv $tmp_file $CURRENT_DIR/publisher_metrics