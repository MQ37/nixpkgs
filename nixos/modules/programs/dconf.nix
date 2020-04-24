{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.dconf;
  cfgDir = pkgs.symlinkJoin {
    name = "dconf-system-config";
    paths = map (x: "${x}/etc/dconf") cfg.packages;
    postBuild = ''
      mkdir -p $out/profile
      mkdir -p $out/db
    '' + (
      concatStringsSep "\n" (
        mapAttrsToList (
          name: path: ''
            ln -s ${path} $out/profile/${name}
          ''
        ) cfg.profiles
      )
    ) + ''
      ${pkgs.dconf}/bin/dconf update $out/db
    '';
  };
in
{
  ###### interface

  options = {
    programs.dconf = {
      enable = mkEnableOption "dconf";

      profiles = mkOption {
        type = types.attrsOf types.path;
        default = {};
        description = "Set of dconf profile files, installed at <filename>/etc/dconf/profiles/<replaceable>name</replaceable></filename>.";
        internal = true;
      };

      packages = mkOption {
        type = types.listOf types.package;
        default = [];
        description = "A list of packages which provide dconf profiles and databases in <filename>/etc/dconf</filename>.";
      };
    };
  };

  ###### implementation

  config = mkIf (cfg.profiles != {} || cfg.enable) {
    environment.etc.dconf.source = mkIf (cfg.profiles != {} || cfg.packages != []) cfgDir;

    services.dbus.packages = [ pkgs.dconf ];

    # For dconf executable
    environment.systemPackages = [ pkgs.dconf ];

    # Needed for unwrapped applications
    environment.variables.GIO_EXTRA_MODULES = mkIf cfg.enable [ "${pkgs.dconf.lib}/lib/gio/modules" ];
  };

}
