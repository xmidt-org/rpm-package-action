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

if [ ! -z "$INPUTS_ARTIFACT_TOKEN" ]; then
    # Enable checking out potentially private github repositories too
    git config --global url."https://$INPUTS_ARTIFACT_TOKEN:x-oauth-basic@github.com".insteadOf "https://github.com"
fi

if [ ! -z "$INPUTS_BUILD_HOST" ]; then
    echo "%_buildhost $INPUTS_BUILD_HOST" >> ~/.rpmmacros
fi

# Build the RPM and SRPM files.
rpmbuild --undefine=_disable_source_fetch -ba $INPUTS_SPEC_FILE

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
