#!/bin/bash
# SPDX-FileCopyrightText: 2022 Comcast Cable Communications Management, LLC
# SPDX-License-Identifier: Apache-2.0

# Colors
SWITCH="\033["

BOLD="\033[1m"
DIM="\033[2m"
RESET="\033[22m"

NORMAL="${SWITCH}0m"
CYAN="${SWITCH}1;36m"
RED="${SWITCH}1;31m"
YELLOW="${SWITCH}1;33m"

usage() {
    echo -e "Usage: $0 requres the following env vars to be set:"
    if [[ -z "$GITHUB_WORKSPACE" ]]; then
        echo -e "    ${RED}GITHUB_WORKSPACE                 (required) missing${NORMAL}"
    else
        echo -e "    GITHUB_WORKSPACE                 (required) ${CYAN}present${NORMAL} $GITHUB_WORKSPACE"
    fi

    if [[ -z "$GITHUB_ACTION_PATH" ]]; then
        echo -e "    ${RED}GITHUB_ACTION_PATH               (required) missing${NORMAL}"
    else
        echo -e "    GITHUB_ACTION_PATH               (required) ${CYAN}present${NORMAL} $GITHUB_ACTION_PATH"
    fi

    if [[ -z "$INPUTS_PATH" ]]; then
        echo -e "    ${RED}INPUTS_PATH                      (required) missing${NORMAL}"
    else
        echo -e "    INPUTS_PATH                      (required) ${CYAN}present${NORMAL} $INPUTS_PATH"
    fi

    if [[ -z "$INPUTS_SPEC" ]]; then
        echo -e "    ${RED}INPUTS_SPEC                      (required) missing${NORMAL}"
    else
        echo -e "    INPUTS_SPEC                      (required) ${CYAN}present${NORMAL} $INPUTS_SPEC"
    fi
    if [[ -z "$INPUTS_DISTRO" ]]; then
        echo -e "    ${RED}INPUTS_DISTRO                    (required) missing${NORMAL}"
    else
        echo -e "    INPUTS_DISTRO                    (required) ${CYAN}present${NORMAL} $INPUTS_DISTRO"
    fi
    if [[ -z "$INPUTS_OUTPUT_DIR" ]]; then
        echo -e "    ${RED}INPUTS_OUTPUT_DIR                (required) missing${NORMAL}"
    else
        echo -e "    INPUTS_OUTPUT_DIR                (required) ${CYAN}present${NORMAL} $INPUTS_OUTPUT_DIR"
    fi
    if [[ -z "$INPUTS_GPG_KEY" ]]; then
        echo -e "    INPUTS_GPG_KEY                   (optional) ${YELLOW}missing${NORMAL}"
    else
        echo -e "    INPUTS_GPG_KEY                   (optional) ${CYAN}present${NORMAL}"
    fi
    if [[ -z "$INPUTS_GPG_NAME" ]]; then
        echo -e "    INPUTS_GPG_NAME                  (optional) ${YELLOW}missing${NORMAL}"
    else
        echo -e "    INPUTS_GPG_NAME                  (optional) ${CYAN}present${NORMAL}"
    fi
    if [[ -z "$INPUTS_DOCKERFILE_SLUG" ]]; then
        echo -e "    INPUTS_DOCKERFILE_SLUG           (optional) ${YELLOW}missing${NORMAL}"
    else
        echo -e "    INPUTS_DOCKERFILE_SLUG           (optional) ${CYAN}present${NORMAL} $INPUTS_DOCKERFILE_SLUG"
    fi
    if [[ -z "$INPUTS_DOCKERFILE_PATH" ]]; then
        echo -e "    INPUTS_DOCKERFILE_PATH           (optional) ${YELLOW}missing${NORMAL}"
    else
        echo -e "    INPUTS_DOCKERFILE_PATH           (optional) ${CYAN}present${NORMAL} $INPUTS_DOCKERFILE_PATH"
    fi
    if [[ -z "$INPUTS_DOCKER_ACCESS_TOKEN" ]]; then
        echo -e "    INPUTS_DOCKER_ACCESS_TOKEN       (optional) ${YELLOW}missing${NORMAL}"
    else
        echo -e "    INPUTS_DOCKER_ACCESS_TOKEN       (optional) ${CYAN}present${NORMAL}"
    fi
    if [[ -z "$INPUTS_CONTAINER_REGISTRY_URL" ]]; then
        echo -e "    INPUTS_CONTAINER_REGISTRY_URL    (optional) ${YELLOW}missing${NORMAL}"
    else
        echo -e "    INPUTS_CONTAINER_REGISTRY_URL    (optional) ${CYAN}present${NORMAL} $INPUTS_CONTAINER_REGISTRY_URL"
    fi
    if [[ -z "$INPUTS_CONTAINER_REGISTRY_USER" ]]; then
        echo -e "    INPUTS_CONTAINER_REGISTRY_USER   (optional) ${YELLOW}missing${NORMAL}"
    else
        echo -e "    INPUTS_CONTAINER_REGISTRY_USER   (optional) ${CYAN}present${NORMAL} $INPUTS_CONTAINER_REGISTRY_USER"
    fi
    if [[ -z "$INPUTS_CONTAINER_REGISTRY_TOKEN" ]]; then
        echo -e "    INPUTS_CONTAINER_REGISTRY_TOKEN  (optional) ${YELLOW}missing${NORMAL}"
    else
        echo -e "    INPUTS_CONTAINER_REGISTRY_TOKEN  (optional) ${CYAN}present${NORMAL}"
    fi
    if [[ -z "$INPUTS_BUILD_HOST" ]]; then
        echo -e "    INPUTS_BUILD_HOST                (optional) ${YELLOW}missing${NORMAL}"
    else
        echo -e "    INPUTS_BUILD_HOST                (optional) ${CYAN}present${NORMAL} $INPUTS_BUILD_HOST"
    fi
    if [[ -z "$INPUTS_TARGET_PROCESSOR_ARCH" ]]; then
        echo -e "    INPUTS_TARGET_PROCESSOR_ARCH     (optional) ${YELLOW}missing${NORMAL}"
    else
        echo -e "    INPUTS_TARGET_PROCESSOR_ARCH     (optional) ${CYAN}present${NORMAL} $INPUTS_TARGET_PROCESSOR_ARCH"
    fi
    if [[ -z "$INPUTS_ARTIFACTS_TOKEN" ]]; then
        echo -e "    INPUTS_ARTIFACTS_TOKEN           (optional) ${YELLOW}missing${NORMAL}"
    else
        echo -e "    INPUTS_ARTIFACTS_TOKEN           (optional) ${CYAN}present${NORMAL}"
    fi
}

# Fail on error
set -e

# Validate required are present
if [[ -z "$GITHUB_WORKSPACE"   || \
      -z "$GITHUB_ACTION_PATH" || \
      -z "$INPUTS_PATH"        || \
      -z "$INPUTS_SPEC"        || \
      -z "$INPUTS_DISTRO"      || \
      -z "$INPUTS_OUTPUT_DIR" ]]; then
    usage
    exit 1
fi

# Validate the INPUTS_DISTRO, and get the dockerfile from either the local repo
# or a different repository before continuing on
if [[ "custom" -eq "$INPUTS_DISTRO" ]]; then
    if [[ -z "$INPUTS_DOCKERFILE_SLUG" ]]; then
        if [[ -f "$GITHUB_WORKSPACE/$INPUTS_DOCKERFILE_PATH" ]]; then
            dockerfile="$GITHUB_WORKSPACE/$INPUTS_DOCKERFILE_PATH"
        else
            echo -e "${RED}Could not find the dockerfile named: ${INPUTS_DOCKERFILE_PATH}${NORMAL}."
            usage
            exit 1
        fi
    else
        if [[ -z "$INPUTS_DOCKERFILE_PATH" ]]; then
            echo -e "${RED}Since 'distro' is 'custom' the 'dockerfile' must be set to a file or owner/repo/path to a valid dockerfile.${NORMAL}"
            usage
            exit 1
        fi

        token=''
        if [[ ! -z "$INPUTS_DOCKER_ACCESS_TOKEN" ]]; then
            token="Authorization: token $INPUTS_DOCKER_ACCESS_TOKEN"
        fi
        dockerfile="$GITHUB_ACTION_PATH/Dockerfile"
        curl -s --fail \
             -H "$token" \
             -H 'Accept: application/vnd.github.v3.raw' \
             -o "$dockerfile" \
             -L "https://api.github.com/repos/$INPUTS_DOCKERFILE_SLUG/contents/$INPUTS_DOCKERFILE_PATH"
    fi
else
    dockerfile="$GITHUB_ACTION_PATH/distros/Dockerfile.$INPUTS_DISTRO"
    if [[ ! -f "$dockerfile" ]]; then
        echo -e "${RED}INPUTS_DISTRO ${DIM}name(${RESET}${RED}$INPUTS_DISTRO${DIM}) is invalid.  It must be one of following:${RESET}${RED}"
        ls distros | grep -oh "[^.]*$"
        echo -e -n "${NORMAL}"
        exit 1
    fi
fi

# Validate the path
if [[ ! -d "$INPUTS_PATH" ]]; then
    echo -e "${RED}path ${DIM}must be a directory.${NORMAL}"
    exit 1
fi

# Validate the spec file
if [[ ! -f "$INPUTS_PATH/$INPUTS_SPEC" ]]; then
    echo -e "${RED}spec ${DIM}must be a spec file.${NORMAL}"
    exit 1
fi

# Ensure INPUTS_GPG_KEY and INPUTS_GPG_NAME are both valid or empty
if [[ ! -z "$INPUTS_GPG_KEY" && -z "$INPUTS_GPG_NAME" ]]; then
    echo -e "${RED}gpg-key${DIM} must be defined if ${RED}gpg-name${DIM} is defined.${NORMAL}"
    exit 1
fi
if [[ -z "$INPUTS_GPG_KEY" && ! -z "$INPUTS_GPG_NAME" ]]; then
    echo -e "${RED}gpg-name${DIM} must be defined if ${RED}gpg-key${DIM} is defined.${NORMAL}"
    exit 1
fi

docker_name="rpm-package-action:builder-$INPUTS_DISTRO"

if [[ ! -z "$INPUTS_CONTAINER_REGISTRY_URL" || \
      ! -z "$INPUTS_CONTAINER_REGISTRY_USER" || \
      ! -z "$INPUTS_CONTAINER_REGISTRY_TOKEN" ]]; then

    if [[ ! -z "$INPUTS_CONTAINER_REGISTRY_USER" ]]; then
        echo $INPUTS_CONTAINER_REGISTRY_TOKEN | docker login $INPUTS_CONTAINER_REGISTRY_URL -u $INPUTS_CONTAINER_REGISTRY_USER --password-stdin
    else
        echo $INPUTS_CONTAINER_REGISTRY_TOKEN | docker login $INPUTS_CONTAINER_REGISTRY_URL --password-stdin
    fi

fi

echo -e "${CYAN}-- Building the docker image -----${NORMAL}"
# Build the docker image

echo "pwd" pwd
echo GITHUB_WORKSPACE $GITHUB_WORKSPACE
echo GITHUB_ACTION_PATH $GITHUB_ACTION_PATH
ls -Rrlrah

#docker build -t $docker_name -f $dockerfile "$GITHUB_ACTION_PATH"

#to add random things to override the entrypoint of the docker image, use workspace vs. action path 
docker build -t $docker_name -f $dockerfile "$GITHUB_WORKSPACE"


echo -e "${CYAN}-- Running docker ----------------${NORMAL}"

echo "trying to mount GITHUB_WORKSPACE/INPUTS_PATH:"$GITHUB_WORKSPACE/$INPUTS_PATH

# Run the docker image and make the rpm
docker run --name thing \
    --workdir $GITHUB_WORKSPACE \
    --rm \
    -e INPUTS_GPG_KEY="$INPUTS_GPG_KEY" \
    -e INPUTS_GPG_NAME="$INPUTS_GPG_NAME" \
    -e INPUTS_OUTPUT_DIR="$INPUTS_OUTPUT_DIR" \
    -e INPUTS_RPM_PATH="$INPUTS_PATH" \
    -e INPUTS_SPEC_FILE="$INPUTS_SPEC" \
    -e INPUTS_BUILD_HOST="$INPUTS_BUILD_HOST" \
    -e INPUTS_ARTIFACTS_TOKEN="$INPUTS_ARTIFACTS_TOKEN" \
    -e INPUTS_TARGET_PROCESSOR_ARCH="$INPUTS_TARGET_PROCESSOR_ARCH" \
    -v "$GITHUB_WORKSPACE/$INPUTS_PATH:/mnt/repo" \
    $docker_name
