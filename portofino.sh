#!/usr/bin/env bash

require() {
  hash $1 2>/dev/null || { echo >&2 $1" is not installed. Aborting."; exit 1; }
}

ask_yes_no() {
  if $SKIP_YES; then
    echo true
  else
    select yn in "Yes" "No"; do
        case $yn in
          Yes ) echo true; break;;
          No ) echo false; break;;
        esac
    done
  fi
}

file_exists() {
  if [ -f $1 ]; then echo true; else echo false; fi
}

prompt() {
  >&2 echo $1
  while true; do
    read -p "" input
    if [ -z "$input" ]; then
      >&2 echo "Invalid input."
    else
      echo $input
      exit
    fi
  done
}

get_var() {
  local test=${!1}
  if [ -z "$test" ]; then
    echo $(prompt "Enter $1: ")
  else
    echo $test
  fi
}

docker::build() {
  docker build --rm -t $1 $2
}

docker::image_exists() {
  local count=$(docker images | grep -oc $1)
  if [ $count -gt 0 ]; then echo true; else echo false; fi
}

docker::container_exists() {
  local count=$(docker ps -a | grep -oc '\s'$1'\s')
  if [ $count -gt 0 ]; then echo true; else echo false; fi
}

docker::should_install() {
  local image_exists=$(docker::image_exists $1)

  if $image_exists; then
    >&2 echo $1" already installed. Re-install?";
    local yn=$(ask_yes_no)
    echo $yn
  else
    >&2 echo $1" not yet installed.";
    echo true
  fi
}

docker::stop_container() {
  local container_runs=$(docker::container_exists $1)
  if $container_runs; then
    echo "kill "$1
    docker kill $1 && docker rm $1
  else
    echo $1" already stopped"
  fi
}

start_prompt() {
  case $1 in
    install)
      echo "Build and install portofino private docker registry. Continue?";
      local yn=$(ask_yes_no)
      if $yn; then do_install else exit 1; fi
      ;;
    run)
      echo "Run portofino private docker registry?";
      local yn=$(ask_yes_no)
      if $yn; then do_run else exit 1; fi
      ;;
    stop)
      echo "Stopping docker containers..."
      do_stop
      ;;
    *)
      echo "Usage: portofino.sh (install|run|stop)"
      exit 1
      ;;
  esac
}

install_prompt() {
  local should_install=$(docker::should_install $1)

  if $should_install; then
    docker::build $1 $2
  fi
}

get_var_or_prompt() {
  if [ -z "$$1" ]; then
    echo $$1
  else
    echo "fuck"
  fi
}

# Global Portofino variables
#=======================================
readonly registry_name="portofino"
readonly nginx_name="portofino-proxy"
readonly nginx_port="5000"

########################################
# Install Portofino docker containers
########################################
do_install() {
  # Install Portofino Docker registry
  #=====================================
  local registry_dir="registry/"

  install_prompt $registry_name $registry_dir

  # Install Portofino nginx proxy
  #=====================================
  local nginx_dir="nginx/"

  install_prompt $nginx_name $nginx_dir

  echo "Cleaning up images..."
  docker rmi $(docker images --no-trunc=true --filter dangling=true --quiet)
}

########################################
# Stop Portofino docker containers
########################################
do_stop() {
  docker::stop_container $registry_name
  docker::stop_container $nginx_name
}

########################################
# Run Portofino docker containers
########################################
do_run() {
  local registry_exists=$(docker::image_exists $registry_name)
  local nginx_exists=$(docker::image_exists $nginx_name)

  if $registry_exists && $nginx_exists; then
    if [ -f "./portofino.cfg" ]; then
      echo "Using ./portofino.cfg"
      source "./portofino.cfg"
    else
      echo "Warning: no config-file 'portofino.cfg'"
    fi

    do_stop
    docker run -d --name $registry_name $registry_name:latest && \
    docker run -d \
               -e HTPASSWD_USER=$(get_var HTPASSWD_USER) \
               -e HTPASSWD_PASS=$(get_var HTPASSWD_PASS) \
               -e SSL_COUNTRY=$(get_var SSL_COUNTRY) \
               -e SSL_STATE=$(get_var SSL_STATE) \
               -e SSL_LOCATION=$(get_var SSL_LOCATION) \
               -e SSL_ORGANISATION=$(get_var SSL_ORGANISATION) \
               -e SSL_ORGANISATION_UNIT=$(get_var SSL_ORGANISATION_UNIT) \
               -e SSL_COMMON_NAME=$(get_var SSL_COMMON_NAME) \
               -p $nginx_port:$nginx_port \
               --link $registry_name:registry-alias \
               --name $nginx_name \
               $nginx_name:latest
  else
    echo $registry_name" or "$nginx_name" not installed. Aborting."
  fi
}

# Start Portofino script
#=======================================
require "docker"

# Skip prompts if '-y' flag was set
#=======================================
if [ "$2" == "-y" ]; then
  echo "Skip all prompt with 'yes'"
  readonly SKIP_YES=true
else
  readonly SKIP_YES=false
fi

start_prompt $1
