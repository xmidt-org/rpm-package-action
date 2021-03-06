# Github Action - RPM Package Action

This Github Action provides a simple and flexible way to package and sign rpms
for different platforms.

## Usage

### Inputs

- `path`: The path to the directory containing all the files needed to build the RPM. [**required**]
- `spec`: The spec file to build.  The spec file must be located in the `path` above. [**required**]
- `distro`: The distribution to build on and target, or `custom` to provide your own dockerfile.  The docker files are found in the `distros` repo and this value is the filename suffix. [**optional, default:** `custom`]
- `output-dir`: The destination directory to place the RPM and SRPM files. [**optional, default:** `output`]
- `build-host`: The build host to specify for inclusion into the RPM information. [**optional**]
- `gpg-key`: The GPG key used to sign the RPM if you want to sign your RPM. [**optional, requires:** `gpg-name`]
- `gpg-name`: The GPG key name used to sign the RPM. [**optional, requires:** `gpg-key`]
- `dockerfile-slug`: The github owner/repo where the dockerfile can be found.  Defaults to looking in the present repo unless specified. [**optional**]
- `dockerfile-path`: The path from the repo to the file including the filename.  [**optional, required if** `distro`**=**`custom`]
- `dockerfile-access-token`: The access token if needed to download the dockerfile from a protected repo. [**optional**]
- `container-registry-url`: If specified, the non-dockerhub container URL.  For Github Containers specify 'ghcr.io' [**optional**]
- `container-registry-user`: The username to login to the container registry with if present. [**optional**]
- `container-registry-token`: The token to use as the password to the container registry with if present. [**optional**]
- `artifacts-token`: The token to use to download private git repos or release objects if present. [**optional**]

### Outputs

- None

### Example workflow - use existing docker image from the action

```yaml
name: RPM Package
on: push

jobs:
    package_rpm:
        runs-on: ubuntu-latest
        steps:
        - uses: actions/checkout@v2

        - name: Package RPM and SRPM
          uses: xmidt-org/rpm-package-action@v1
          with:
            path: .
            spec: example.spec
            distro: rocky-8
```

In this example the repo using this workflow contains the files needed to
build the rpm (including the example.spec file).  The output will be placed in
the default location of `output` and will not be signed.

### Example workflow - use existing docker image from the action and sign the package

```yaml
name: RPM Package
on: push

jobs:
    package_rpm:
        runs-on: ubuntu-latest
        steps:
        - uses: actions/checkout@v2

        - name: Package RPM and SRPM
          uses: xmidt-org/rpm-package-action@v1
          with:
            path: .
            spec: example.spec
            distro: rocky-8
            gpg-key: ${{ secrets.RPM_GPG_PRIVATE_SIGNING_KEY }}
            gpg-name: 'My Signing Key'
```

Everything in this example is the same as the one above it except that it is
signed using the GPG private key you provide.  **DO NOT SHARE YOUR PRIVATE KEY.**
But do share the public key portion.  The `gpg-name` is the name of the key you
are providing and is a known fact that will show up in the final RPM, so it does
not need to be secret.

### Example workflow - use a dockerfile your repo provides

```yaml
name: RPM Package
on: push

jobs:
    package_rpm:
        runs-on: ubuntu-latest
        steps:
        - uses: actions/checkout@v2

        - name: Package RPM and SRPM
          uses: xmidt-org/rpm-package-action@v1
          with:
            path: .
            spec: example.spec
            dockerfile-path: rpm-builder-dockerfile
```

This will look for a file in your repo named `rpm-builder-dockerfile` and use that
to package the rpm in.  Your dockerfile needs to have the following two lines:

```
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
```

Beyond that you can use any image you want provided github is able to download it.


## References

* [RPM Packaging Guide](https://rpm-packaging-guide.github.io/)
* [RPM Site](https://rpm.org)
* [Excellent Presentation](http://pdwaterman.com/wp-content/uploads/2016/08/RPM-ifying-System-Configurations.pdf) that has several valuable solutions to common problems.

## Contribute

See [this file](CONTRIBUTING.md) for details.

## License

This project is released under the [Apache 2.0 license](LICENSE).
