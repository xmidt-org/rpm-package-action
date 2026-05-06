# SPDX-FileCopyrightText: 2022 Comcast Cable Communications Management, LLC
# SPDX-License-Identifier: Apache-2.0

DISTROS := $(patsubst distros/Dockerfile.%,%,$(wildcard distros/Dockerfile.*))

PLATFORM ?=
DOCKER_BUILD_ARGS := $(if $(PLATFORM),--platform $(PLATFORM),)

.PHONY: help build clean

help:
	@echo "Targets:"
	@echo "  build               Build all distro images"
	@echo "  build-<distro>      Build one distro image (e.g. build-rocky-9)"
	@echo "  clean               Remove all built distro images"
	@echo "  clean-<distro>      Remove one built distro image"
	@echo ""
	@echo "Available distros: $(DISTROS)"
	@echo ""
	@echo "Cross-build with PLATFORM, e.g.:"
	@echo "  make build-rocky-9 PLATFORM=linux/arm64"

build: $(addprefix build-,$(DISTROS))

build-%: distros/Dockerfile.%
	docker build $(DOCKER_BUILD_ARGS) -t rpm-package-action:builder-$* -f $< .

clean: $(addprefix clean-,$(DISTROS))

clean-%:
	-docker rmi rpm-package-action:builder-$*
