#!/bin/sh -l
# SPDX-FileCopyrightText: 2022 Comcast Cable Communications Management, LLC
# SPDX-License-Identifier: Apache-2.0

# Fail on error
set -e

# Set up the rpm development tree.
rpmdev-setuptree

# Switch to the directory with the mounted repo.
cd /mnt/repo

# Install the build time dependencies based on the spec file needs.
yum-builddep -y $INPUTS_SPEC_FILE

# Copy the directory of files into the source location so they are ready for use.
cp -r * ~/rpmbuild/SOURCES/.

touch ~/.rpmmacros

if [ ! -z "$INPUTS_ARTIFACTS_TOKEN" ]; then
    # Enable checking out potentially private github repositories too
    git config --global url."https://$INPUTS_ARTIFACTS_TOKEN:x-oauth-basic@github.com".insteadOf "https://github.com"

    echo "$INPUTS_ARTIFACTS_TOKEN" >  ~/.gh_token

    # Add all the standard fields in case they aren't present.
    echo "%__urlhelpercmd         $HOME/.gh_curl.sh"                                                                        >> ~/.rpmmacros
    echo "%__urlhelperopts        --silent --show-error --fail --globoff --location -o"                                     >> ~/.rpmmacros
    echo "%__urlhelper_proxyopts  %{?_httpproxy:--proxy %{_httpproxy}%{?_httpport::%{_httpport}}}%{!?_httpproxy:%{nil}}"    >> ~/.rpmmacros
    # This is the one field the tools will look for
    echo "%_urlhelper             %{__urlhelpercmd} %{?__urlhelper_localopts} %{?__urlhelper_proxyopts} %{__urlhelperopts}" >> ~/.rpmmacros

    # 'EOF' makes sure not to expand any variables/etc.
    cat <<'EOF' > ~/.gh_curl.sh
#!/bin/bash

args=("$@")

arg_count=${#args[@]}
url_index=$((arg_count - 1))
url=${args[${url_index}]}

token=$(cat ~/.gh_token)

# URLS are not case sensative, convert to all lowercase
# the string 'https://github.comcast.com/' is 19 characters long.
url_match=$(echo ${url::19} | tr '[:upper:]' '[:lower:]')

# Only add the credentials if we are requesting from github.com
if [[ $url_match == "https://github.com/" ]] ; then
    echo "gh_curl.sh: Adding authorization header."
    curl -H "Authorization: token ${token}" ${@:1}
else
    curl ${@:1}
fi
EOF
    chmod uga+x ~/.gh_curl.sh

fi

if [ ! -z "$INPUTS_BUILD_HOST" ]; then
    echo "%_buildhost $INPUTS_BUILD_HOST" >> ~/.rpmmacros
fi

# Build the RPM and SRPM files.
if [ ! -z "$INPUTS_TARGET_PROCESSOR_ARCH" ] ; then
    rpmbuild --undefine=_disable_source_fetch --target $INPUTS_TARGET_PROCESSOR_ARCH -ba $INPUTS_SPEC_FILE
else
    rpmbuild --undefine=_disable_source_fetch -ba $INPUTS_SPEC_FILE
fi

if [ ! -z "$INPUTS_GPG_KEY" ] ; then
    echo "Signing the RPMs."

    # Import the private key & be quiet about it.
    echo "$INPUTS_GPG_KEY" > private.key
    gpg -q --allow-secret-key-import --import private.key

    # Don't try to accept a password for the GPG.
    export GPG_TTY=""

    # Configure the .rpmmacro file for signing.
    echo "%_signature gpg"                  >> ~/.rpmmacros
    echo "%_gpg_path  ~/.gnupg"             >> ~/.rpmmacros
    echo "%_gpg_name  ${INPUTS_GPG_NAME}"   >> ~/.rpmmacros
    echo "%_gpg       /usr/bin/gpg"         >> ~/.rpmmacros

    # Find and sign all the RPMs.
    find ~/rpmbuild/RPMS -name *.rpm -exec rpmsign --addsign {} \;
fi

# Make the output directory and copy the output artifacts RPMS/SRPMS over.
mkdir -p $INPUTS_OUTPUT_DIR
find ~/rpmbuild -name *.rpm -exec cp {} /mnt/repo/$INPUTS_OUTPUT_DIR/. \;

#set the permissions on the output directory and its contents to public for downstream jobs to CRUD
chmod -R 777 $INPUTS_OUTPUT_DIR
