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

docker::rmi() {
  local image_exists=$(docker::image_exists $1)
  if $image_exists; then
    echo "uninstall "$1
    docker rmi $1
  else
    echo $1" is not installed"
  fi
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
    build)
      echo "Build and install Portofino private Docker registry. Continue?";
      local yn=$(ask_yes_no)
      if $yn; then do_build else exit 1; fi
      ;;
    start)
      echo "Start Portofino private Docker registry?";
      local yn=$(ask_yes_no)
      if $yn; then do_run else exit 1; fi
      ;;
    stop)
      echo "Stop Portofino private Docker registry?";
      local yn=$(ask_yes_no)
      if $yn; then do_stop else exit 1; fi
      ;;
    uninstall)
      echo "Uninstall Portofino private Docker registry?";
      local yn=$(ask_yes_no)
      if $yn; then do_uninstall else exit 1; fi
      ;;
    *)
      echo "Usage: portofino.sh (build|start|stop|uninstall)"
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

########################################
# Install Portofino docker containers
########################################
do_build() {
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
# Uninstall Portofino docker containers
########################################
do_uninstall() {
  do_stop
  docker::rmi $registry_name
  docker::rmi $nginx_name
}

########################################
# Stop Portofino docker containers
########################################
do_stop() {
  echo "Stopping Docker containers..."
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

# Set DOCKER_USER variable
#=======================================
if [ -z "$DOCKER_USER" ]; then
  echo "Set \$DOCKER_USER to 'portofino'"
  readonly DOCKER_USER="portofino"
else
  echo "Set \$DOCKER_USER to '$DOCKER_USER'"
fi

# Set global Portofino variables
#=======================================
readonly registry_name=$DOCKER_USER"/portofino"
readonly nginx_name=$DOCKER_USER"/portofino-proxy"
readonly nginx_port="5000" # Must be same as in Docker- and config-files.

# Start Portofino script
#=======================================
start_prompt $1
