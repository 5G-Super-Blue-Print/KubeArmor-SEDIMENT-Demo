#/bin/bash -f

# PRE-REQUISITE: create the sediment network using the following command
# $ docker network create --subnet=192.168.2.0/24 sediment
# assuming the subnet is 192.168.2.0/24

usage_exit() {
  [[ -n "$1" ]] && echo $1
  echo "Usage: $0 [ -acmrstwh ] "
  echo "    -c <component>    { prover | verifier | firewall | app_server }"
  echo "    -m                Run in manual mode"
  echo "    -r <repo:tag>     Docker image repo:tag"
  echo "    -h                Help"
  exit 1
}

handle_opts() {
  local OPTIND
  while getopts "c:mr:h" options; do
    case "${options}" in
      c) component="${OPTARG}"  ;;
      m) manual=-m              ;;
      r) repo="${OPTARG}"       ;;
      
      h) usage_exit             ;;
      :) usage_exit "Error: -${OPTARG} requires an argument." ;;
      *) usage_exit "" ;;
    esac
  done
  
  shift $((OPTIND -1))
}

component=prover
handle_opts "$@"

if [ -z $component ]; then
    echo "missing component"
    usage_exit
fi

case $component in
    "firewall")
        addr=192.168.2.100
        in_port=8000
        
        #out_addr=192.168.2.102  # to app_server
        #out_port=8001
        
        ;;
    "verifier")
        addr=192.168.2.101
        in_port=8100

        #out_addr=192.168.2.100  # to firewall
        #out_port=8000

        #svc_port=8102
        #gui_port=8101
        ;;
    "app_server")
        addr=192.168.2.102
        in_port=8001
        #gui_port=8201
        ;;
    "prover")
        addr=192.168.2.200
        #out_addr=192.168.2.100
        #out_port=8000
        ;;
    *)
        echo "invalid component: $component"
        exit;;
esac    

if [ -z $repo ]; then
    repo=sediment:demo
fi

if [ ! -z $in_port ]; then
    publish="--publish $in_port"
fi

TTY="--tty --interactive"

if [ -z "$manual" ]; then
  ENTRY="--entrypoint /home/sediment/build/${component}"
else
  ENTRY="--entrypoint /bin/bash"
fi

CMD="docker run \
       $TTY \
       --privileged \
       --net sediment \
       --hostname ${component} \
       --name "sediment_${component}" \
       --ip ${addr} \
       --env "SEDIMENT=/home/sediment" \
       ${publish} \
       $ENTRY \
       -d \
       ${repo}"

echo $CMD

eval "$CMD"
