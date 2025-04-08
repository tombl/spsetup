#!/bin/sh
cd "$(dirname "$0")"

# the platform arg here requires you've got cross-arch emulation setup, otherwise
# you'll have to split it up and run it on separate machines.
#
# on nixos this is as simple as adding this to your config:
#     boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
#     boot.binfmt.preferStaticEmulators = true;
#
# otherwise, I suspect you can run something like
#     podman run --privileged --rm tonistiigi/binfmt --install arm64
podman build --platform linux/amd64,linux/arm64 . -t ghcr.io/tombl/spsetup:ubuntu24.04
