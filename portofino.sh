#!/usr/bin/env bash

source nginx/utils.sh

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

#######################################
# Prompt for a value from user input
# Returns:
#   The prompted value
#######################################
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

#######################################
# Return existing variable or prompt
# Arguments:
#   Name of the requested variable
# Returns:
#   The existing or prompted value
#######################################
get_var() {
  local test=${!1}
  if [ -z "$test" ]; then
    echo $(prompt "Enter $1: ")
  else
    echo $test
  fi
}

#######################################
# Return existing variable or default
# Arguments:
#   Name of the requested variable
#   Default value for the variable
#   Boolean: disable log output
# Returns:
#   The existing or default value
#######################################
get_var_or_default() {
  local test=${!1}
  if [ -z "$test" ]; then
    if $3; then >&2 echo "$1: '$2'"; fi
    echo $2
  else
    if $3; then >&2 echo "$1: '$test'"; fi
    echo $test
  fi
}

docker::build() {
  docker build --rm -t $1 $2
}

docker::rmi() {
  if $(docker::image_exists $1); then
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
  if $(docker::image_exists $1); then
    >&2 echo $1" already installed. Re-install?";
    echo $(ask_yes_no)
  else
    >&2 echo $1" not yet installed.";
    echo true
  fi
}

docker::stop_container() {
  if $(docker::container_exists $1); then
    echo "kill "$1
    docker kill $1 && docker rm $1
  else
    echo $1" already stopped"
  fi
}

docker::cleanup() {
  echo "Cleaning up images..."
  local images=$(docker images --no-trunc=true --filter dangling=true --quiet)
  if [ ! -z "$images" ]; then
    docker rmi $images
  fi
}

start_prompt() {
  case $1 in
    build)
      echo "Build and install Portofino private Docker registry. Continue?";
      if $(ask_yes_no); then do_build else exit 1; fi
      ;;
    start)
      echo "Start Portofino private Docker registry?";
      if $(ask_yes_no); then do_run else exit 1; fi
      ;;
    stop)
      echo "Stop Portofino private Docker registry?";
      if $(ask_yes_no); then do_stop else exit 1; fi
      ;;
    install)
      echo "Install Portofino private Docker registry?";
      if $(ask_yes_no); then do_install else exit 1; fi
      ;;
    uninstall)
      echo "Uninstall Portofino private Docker registry?";
      if $(ask_yes_no); then do_uninstall else exit 1; fi
      ;;
    -y)
      # yes-flag
      ;;
    *)
      echo $USAGE
      exit 1
      ;;
  esac
}

install_prompt() {
  if $(docker::should_install $1); then
    docker::build $1 $2
  fi
}

########################################
# Build docker images from source
########################################
do_build() {
  install_prompt $REGISTRY_IMAGE "registry/"
  install_prompt $NGINX_IMAGE "nginx/"
  docker::cleanup
}

########################################
# Install docker images from hub
########################################
do_install() {
  echo "Downloading Portofino images..."
  docker pull $REGISTRY_IMAGE:latest
  docker pull $NGINX_IMAGE:latest
}

########################################
# Uninstall Portofino docker containers
########################################
do_uninstall() {
  do_stop
  docker::rmi $REGISTRY_IMAGE
  docker::rmi $NGINX_IMAGE
}

########################################
# Stop Portofino docker containers
########################################
do_stop() {
  echo "Stopping Docker containers..."
  docker::stop_container $REGISTRY_NAME
  docker::stop_container $NGINX_NAME
}

########################################
# Run Portofino docker containers
########################################
do_run() {
  local registry_exists=$(docker::image_exists $REGISTRY_IMAGE)
  local nginx_exists=$(docker::image_exists $NGINX_IMAGE)

  if $registry_exists && $nginx_exists; then
    if [ -f "./portofino.cfg" ]; then
      echo "Using ./portofino.cfg"
      source "./portofino.cfg"
    else
      echo "Warning: no config-file 'portofino.cfg'"
    fi

    do_stop
    docker run -d --name $REGISTRY_NAME $REGISTRY_IMAGE:latest && \
    docker run -d \
               -e HTPASSWD_USER=$(get_var HTPASSWD_USER) \
               -e HTPASSWD_PASS=$(get_var HTPASSWD_PASS) \
               -e SSL_COUNTRY=$(get_var SSL_COUNTRY) \
               -e SSL_STATE=$(get_var SSL_STATE) \
               -e SSL_LOCATION=$(get_var SSL_LOCATION) \
               -e SSL_ORGANISATION=$(get_var SSL_ORGANISATION) \
               -e SSL_ORGANISATION_UNIT=$(get_var SSL_ORGANISATION_UNIT) \
               -e SSL_COMMON_NAME=$(get_var SSL_COMMON_NAME) \
               -e SSL_EXPIRY=$(get_var SSL_EXPIRY) \
               -e SSL_CERTS_DIR=$NGINX_CERTS_DIR \
               -p $NGINX_PORT:5000 \
               -v $LOCAL_CERTS_DIR:$NGINX_CERTS_DIR \
               --link $REGISTRY_NAME:registry-alias \
               --name $NGINX_NAME \
               $NGINX_IMAGE:latest
  else
    echo $REGISTRY_IMAGE" or "$NGINX_IMAGE" not installed. Aborting."
  fi
}

#=======================================
require "docker"

readonly USAGE="Usage: portofino.sh (build|start|stop|install|uninstall)"

if [ -z "$@" ]; then echo $USAGE; exit 1; fi

# Skip prompts if '-y' flag was set
#=======================================
if [[ $@ == *-y* ]]; then
  echo "Skip all prompt with 'yes'"
  readonly SKIP_YES=true
else
  readonly SKIP_YES=false
fi

# Set global Portofino variables
#=======================================
echo "Set environment variables:"
readonly DOCKER_USER=$(get_var_or_default "DOCKER_USER" "portofino")
readonly REGISTRY_NAME=$(get_var_or_default "REGISTRY_NAME" "portofino")
readonly NGINX_NAME=$(get_var_or_default "NGINX_NAME" "portofino-proxy")
readonly NGINX_PORT=$(get_var_or_default "NGINX_PORT" "5000")
readonly LOCAL_CERTS_DIR=$(get_var_or_default "LOCAL_CERTS_DIR" $(pwd)"/certs" false)
readonly NGINX_CERTS_DIR="/etc/portofino/certs"
readonly REGISTRY_IMAGE=$DOCKER_USER/$REGISTRY_NAME
readonly NGINX_IMAGE=$DOCKER_USER/$NGINX_NAME

# Inspect local certificate directory.
#=======================================
if $(dir_exists $LOCAL_CERTS_DIR); then
  if [ $(file_count $LOCAL_CERTS_DIR/{*.crt,*.key}) -gt 2 ]; then
    echo "Ambiguous files in $LOCAL_CERTS_DIR. Aborting."; exit 1;
  fi
  echo "Using certificates from local directory "$LOCAL_CERTS_DIR;
else
  echo "Creating local certificate directory "$LOCAL_CERTS_DIR;
  mkdir -p $LOCAL_CERTS_DIR
fi

# Start Portofino script
#=======================================
for var in "$@"
do
  start_prompt $var
done
