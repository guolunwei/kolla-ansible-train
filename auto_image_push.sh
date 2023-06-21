#!/bin/bash
# source: https://cloud.tencent.com/developer/article/2059697
# The aim of this script is changing pubilc image to privte harbor's
# example: bash auto_image_push.sh kolla/ubuntu-binary-fluentd:train

set -ex
input_info=$1
image_name=`echo $input_info | awk -F ':' '{ print $1 }'  | awk  -F '/' '{ print $NF }'` 
image_tag=`echo $input_info | awk -F ':' '{ print $2 }'` 
harbor_registry='10.0.0.10:4000/kolla'

function  docker_pull(){
   docker pull $input_info
}
function  docker_tag(){
   docker tag $input_info ${harbor_registry}/${image_name}:${image_tag}
}
function docker_push(){
   docker push ${harbor_registry}/${image_name}:${image_tag}
}
function docker_rmi(){
    #delete the pubilc image
   docker rmi $input_info
}

# docker_pull
docker_tag
docker_push
docker_rmi
if [[ $? -eq 0 ]] ;then echo "changing pubilc image to privte harbor's is done!"; fi

