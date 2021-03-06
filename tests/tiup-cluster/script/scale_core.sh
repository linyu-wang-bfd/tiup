#!/bin/bash

function scale_core() {
    mkdir -p ~/.tiup/bin/

    version=$1
    test_tls=$2
    native_ssh=$3

    client=""
    if [ $native_ssh == true ]; then
        client="--native-ssh"
    fi

    name="test_scale_core_$RANDOM"
    if [ $test_tls = true ]; then
        topo=./topo/full_tls.yaml
    else
        topo=./topo/full.yaml
    fi

    tiup-cluster $client --yes deploy $name $version $topo -i ~/.ssh/id_rsa

    tiup-cluster $client list | grep "$name"

    tiup-cluster $client --yes start $name

    tiup-cluster $client _test $name writable

    tiup-cluster $client display $name

    tiup-cluster $client reload $name --skip-restart

    if [ $test_tls = true ]; then
        total_sub_one=18
    else
        total_sub_one=21
    fi

    echo "start scale in tidb"
    tiup-cluster $client --yes scale-in $name -N 172.19.0.101:4000
    wait_instance_num_reach $name $total_sub_one $native_ssh
    echo "start scale out tidb"
    tiup-cluster $client --yes scale-out $name ./topo/full_scale_in_tidb.yaml

    # echo "start scale in tikv"
    # tiup-cluster --yes scale-in $name -N 172.19.0.103:20160
    # wait_instance_num_reach $name $total_sub_one $native_ssh
    # echo "start scale out tikv"
    # tiup-cluster --yes scale-out $name ./topo/full_scale_in_tikv.yaml

    echo "start scale in pd"
    tiup-cluster $client --yes scale-in $name -N 172.19.0.103:2379
    wait_instance_num_reach $name $total_sub_one $native_ssh
    echo "start scale out pd"
    tiup-cluster $client --yes scale-out $name ./topo/full_scale_in_pd.yaml

    tiup-cluster $client _test $name writable
}
