#!/bin/bash
#
# The aim of this script is changing pubilc image to privte harbor's
# example: bash auto_image_push.sh kolla/ubuntu-binary-fluentd:train

set -e

input_info=$1
image_name=`echo $input_info | awk -F ':' '{ print $(NF-1) }'  | awk  -F '/' '{ print $NF }'`
image_tag=`echo $input_info | awk -F ':' '{ print $NF }'`
harbor_registry='10.0.0.10:4000/kolla'

function  docker_pull(){
   sudo docker pull $input_info
}
function  docker_tag(){
   sudo docker tag $input_info ${harbor_registry}/${image_name}:${image_tag}
}
function docker_push(){
   sudo docker push ${harbor_registry}/${image_name}:${image_tag}
}
function docker_rmi(){
   #delete the pubilc image
   sudo docker rmi $input_info
}

#docker_pull
docker_tag
docker_push
docker_rmi

if [[ $? -eq 0 ]];then echo -e "Changing pubilc image to privte harbor's is done!\n";fi
