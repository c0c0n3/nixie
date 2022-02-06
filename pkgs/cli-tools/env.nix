#
# A collection of useful command line tools.
#
{ pkgs, ... }: rec {

  cliUtils = with pkgs; [
    # Internet:
      aria
    # Hardware:
      pciutils
    # Disk:
      smartmontools du-dust
    # Filesystems:
      ntfs3g
    # Network:
      tcpdump ldns ncat  # NOTE (1)
    # Commands:
      tree bc lsof lesspipe ripgrep ripgrep-all
    # Compression: (they all work with lesspipe)
      unzip zip
    # Version Control
      git
  ];

  linuxCliUtils = with pkgs; [
    # Hardware:
      hwinfo usbutils
    # Disk:
      hdparm sdparm parted
    # Network:
      ethtool
    # Commands:
      mkpasswd
  ];

  xUtils = with pkgs; [ xorg.xdpyinfo xorg.xev xorg.xmodmap ];

  mkEnv = { system ? builtins.currentSystem, withXtools ? false }:
  let
    isLinux = (builtins.match ".*-linux$" system) != null;
    xs = if withXtools then xUtils else [];
    lxs = if isLinux then linuxCliUtils else [];
    utils = cliUtils ++ lxs ++ xs;
  in pkgs.buildEnv {
    name = "cli-utils";
    paths = utils;
  };

}
# NOTE
# ----
# 1. dnsutils. Couldn't find it in the NixOS packages and indeed Arch ditched
# it too:
# - https://www.archlinux.org/todo/dnsutils-to-ldns-migration/
# So I'm installing ldns---so use drill instead of nslookup/dig, etc.
