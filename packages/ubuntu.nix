{ pkgs }:

let
  inherit (pkgs) lib;

  release = "noble";
  # mirror = "http://archive.ubuntu.com/ubuntu/";
  mirror = "http://au.archive.ubuntu.com/ubuntu/";
  debsHash = "sha256-sD5Ckx6O8kaRM+edWRY673sW7A8LXGYjmDbfF0yzR7Y=";

  aptPackages = [
    "gcc"
    "python3"
    "pypy3"
  ];
  aptExtraRepos = [ "universe" ];
  aptHash = "sha256-D9LzGuf+NguWUd3cmkVKcDLNkG/MATIGQkqC3Gkf/UY=";

  debootstrap = pkgs.debootstrap.overrideAttrs {
    postInstall = ''
      substituteInPlace $out/bin/debootstrap \
        --replace-fail "PATH='" "PATH="$PATH":'"
    '';
  };

  debootstrap-args = "--variant=minbase ${release} out ${mirror}";

  basedebs = pkgs.runCommand "ubuntu-packages.tar" {
    nativeBuildInputs = [ debootstrap ];
    outputHashMode = "flat";
    outputHashAlgo = "sha256";
    outputHash = debsHash;
  } "debootstrap --make-tarball=$out ${debootstrap-args}";

  baserootfs = pkgs.vmTools.runInLinuxVM (
    pkgs.runCommand "ubuntu-rootfs.tar"
      {
        nativeBuildInputs = [ debootstrap ];
        disallowedReferences = [ debootstrap ]; # don't allow references to debootstrap in the output
      }
      ''
        debootstrap --unpack-tarball=${basedebs} ${debootstrap-args}
        rm -r $out out/dev/*
        rm out/var/log/bootstrap.log # has references to the debootstrap store path
        tar cf $out -C out .
      ''
  );

  apt-cache =
    pkgs.runCommand "ubuntu-apt-cache.tar"
      {
        nativeBuildInputs = [ pkgs.bubblewrap ];
        outputHashMode = "flat";
        outputHashAlgo = "sha256";
        outputHash = aptHash;
      }
      ''
        mkdir out
        tar xf ${baserootfs} -C out

        bwrap \
          --bind out / \
          --bind /etc/resolv.conf /etc/resolv.conf \
          --setenv PATH /bin \
          bash -c '
            for repo in ${lib.concatStringsSep " " aptExtraRepos}; do
              echo "deb ${mirror} ${release} $repo" >> /etc/apt/sources.list
            done
            apt-get update
            apt-get install --download-only -y ${lib.concatStringsSep " " aptPackages}
          '

        tar cf $out -C out .
      '';

  rootfs = pkgs.vmTools.runInLinuxVM (
    pkgs.runCommand "ubuntu-rootfs" { memSize = 2048; } ''
      mkdir out
      tar xf ${apt-cache} -C out

      chroot out /bin/apt install -y ${lib.concatStringsSep " " aptPackages}

      rm -r out/var/cache/*
      cp -r out/* $out
    ''
  );

  run = pkgs.writeShellApplication {
    name = "ubuntu-run";
    runtimeInputs = [ pkgs.bubblewrap ];
    text = ''
      bwrap \
        --overlay-src ${rootfs} --tmp-overlay / \
        --overlay-src /etc --overlay-src ${rootfs}/etc --tmp-overlay /etc \
        --setenv PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
        --proc /proc \
        --dev /dev \
        --bind /home /home \
        "$@"
    '';
  };

  ldso-source = ''
    #include <unistd.h>
    #include <errno.h>
    int main(int argc, char *argv[], char *envp[]) {
      execve("${lib.getExe run}", argv, envp);
      return errno;
    }
  '';

  ldso32 = pkgs.pkgsi686LinuxStatic.runCommandCC "ldso32" {
    source = ldso-source;
    passAsFile = [ "source" ];
  } "$CC -Os $source -o $out";

  ldso64 = pkgs.pkgsStatic.runCommandCC "ldso64" {
    source = ldso-source;
    passAsFile = [ "source" ];
  } "$CC -Os $source -o $out";
in

run
// {
  inherit
    rootfs
    basedebs
    apt-cache
    ldso32
    ldso64
    ;
}
