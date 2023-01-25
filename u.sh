#!/bin/env bash

set -euo pipefail
IFS=$'\n\t'

CLUSTER_NAME="k8s-func"

main(){
	validate_tools "k3d" "jq" "kubectl" "git"

	local clusters
	clusters=$(k3d_list_clusters)
	if [[ " ${clusters[@]} " =~ " ${CLUSTERNAME} " ]]; then
		echo "${CLUSTERNAME} already running"
		if [ "$(kubectl_current_context)" != "${CLUSTER_NAME}" ]; then
			echo "changing kubectl context to ${CLUSTER_NAME}"
			kubectl_use_context "${CLUSTER_NAME}"
		fi
	fi

	echo "creating local ${CLUSTER_NAME} k8s cluster"
	k3d_create_cluster "${CLUSTER_NAME}"

	echo "starting git daemon"
	git_daemon
}

git_daemon(){
	echo "press [CTRL]+C to exit"
	git daemon --base-path=. --export-all --reuseaddr --informative-errors --verbose
}

kubectl_current_context(){
	kubectl config current-context
}

kubectl_use_context(){
	local context="${1}"
	kubectl config use-context "${context}"
}

k3d_list_clusters(){
	k3d cluster list -o json | jq -r '.[].name'
}

k3d_create_cluster(){
	local name="${1}"
	k3d cluster create "${name}"
}

validate_tools() {
  local toolsInstalled=true

  for tool in "$@"; do
    local exists
    exists=$(which "${tool}" || true)
    if [ -z "${exists}" ]; then
      LogWarn "You do not currently have \"${tool}\" installed."
      toolsInstalled=false
    fi
  done

  if [ "${toolsInstalled}" == false ]; then
    LogErr "You are missing the required tools to proceed"
    exit 1
  fi
}

if ! (return 0 2> /dev/null); then
  (main "$@")
fi