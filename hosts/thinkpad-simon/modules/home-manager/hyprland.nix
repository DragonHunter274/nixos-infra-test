{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

let
  startupScript = pkgs.pkgs.writeShellScriptBin "start" ''
    ${pkgs.waybar}/bin/waybar &
    pypr &
    ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &
    ${pkgs.swww}/bin/swww init &
    goldwarden daemonize &
    ${pkgs.swaynotificationcenter}/bin/swaync &
    ${pkgs.networkmanagerapplet}/bin/nm-applet --indicator & disown
    ${pkgs.signal-desktop}/bin/signal-desktop --start-in-tray & disown
    ${pkgs.pulseaudio}/bin/pactl load-module module-raop-discover
    sleep 1


  '';
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    #    systemd.enable = false;
    settings = {
      debug.disable_logs = false;
      exec-once = ''${startupScript}/bin/start'';
      general = {
        monitor = "eDP-1, 1920x1080, 0x0, 1";
        layout = "master";
        gaps_in = 2;
        gaps_out = 5;
        "col.active_border" = "rgb(2aa198)";
        "col.inactive_border" = "0x00000000";
      };

      input = {
        kb_layout = "de";
        numlock_by_default = true;
        follow_mouse = 1;
        float_switch_override_focus = 1;
        mouse_refocus = 1;
        sensitivity = 0;
        touchpad = {
          natural_scroll = true;
        };
      };

      gestures = {
        workspace_swipe = true;

      };

      "$mod" = "SUPER";
      bind = [
        "$mod_SHIFT, Return, exec, kitty"
        "$mod_SHIFT, Q, killactive"
        "$mod, P, exec, grimblast --notify save screen"
        ", Print, exec, grimblast --freeze copy area"
        "$mod, R, exec, killall rofi || rofi -show"
        "$mod, S, exec, killall rofi || rofi-nixossearch"
        "$mod, L, exec, loginctl lock-session"
        "$mod, bracketright, exec, kitty yazi"
        "$mod_ALT, delete, exit"
        "$mod, V, togglefloating"
        "$mod, X, pin"
        "$mod, F, fullscreen, 1"
        "$mod, Tab, exec, hyprctl dispatch overview:toggle"
        "$mod, S, swapactiveworkspaces, 0 1"
        "$mod_SHIFT, S, movetoworkspace, special"
        "$mod_SHIFT, 2, movetoworkspace, 2"
        "$mod, O, exec, killall .ironbar-wrapper inotifywait pactl || ironbar"
        "$mod, M, focusmonitor, +1"
        "$mod_SHIFT, M, focusmonitor, -1"

        "$mod, Return, layoutmsg, swapwithmaster master"
        "$mod, J, layoutmsg, cyclenext"
        "$mod, K, layoutmsg, cycleprev"
        "$mod_SHIFT, J, layoutmsg, swapnext"
        "$mod_SHIFT, K, layoutmsg, swapprev"
        "$mod, C, splitratio, exact 0.80"
        "$mod, C, layoutmsg, orientationtop"
        "$mod_SHIFT, C, splitratio, exact 0.65"
        "$mod_SHIFT, C, layoutmsg, orientationleft"
        "$mod, H, layoutmsg, addmaster"
        "$mod, L, layoutmsg, removemaster"
        "$mod_SHIFT, H, splitratio, -0.05"
        "$mod_SHIFT, L, splitratio, +0.05"
        "$mod_ALT, L, exec, hyprlock"

        "$mod, 1, exec, hyprnome --previous"
        "$mod, 2, exec, hyprnome"
        "$mod_SHIFT, 1, exec, hyprnome --previous --move"
        "$mod_SHIFT, 2, exec, hyprnome --move"

        ", F12, exec, pypr toggle term"
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bindl = [
        ", XF86AudioPrev, exec, playerctl -p playerctld previous"
        ", XF86AudioNext, exec, playerctl -p playerctld next"
        ", XF86AudioPlay, exec, playerctl -p playerctld play"
        ", XF86AudioPause, exec, playerctl -p playerctld pause"
        ", XF86AudioForward, exec, playerctl -p playerctld position 10+"
        ", XF86AudioRewind, exec, playerctl -p playerctld position 10-"
        ", XF86Messenger, togglespecialworkspace"
      ];
    };
  };

  xdg.configFile."hypr/pyprland.toml".text = ''

    [pyprland]
    plugins = [
      "scratchpads",
    ]

    [scratchpads.term]
    animation = "fromTop"
    command = "kitty --class kitty-dropterm"
    class = "kitty-dropterm"
    size = "75% 60%"

  '';

  programs.hyprlock = {
    enable = true;
    package = inputs.hyprlock.packages.${pkgs.stdenv.hostPlatform.system}.hyprlock;
    settings = {
      general = {
        enable_fingerprint = true;
      };
      background = {
        color = "rgba(255, 255, 255, 1.0)";
        path = "screenshot";
        blur_passes = 4;
        blur_size = 3;
        brightness = 1.0;
      };
      input-field = {
        monitor = "";
        size = "200, 50";
        outline_thickness = 4;
        dots_size = 0.33; # Scale of input-field height, 0.2 - 0.8
        dots_spacing = 0.15; # Scale of dots' absolute size, 0.0 - 1.0
        dots_center = true;
        outer_color = "rgb(2aa198)";
        inner_color = "rgb(002b36)";
        font_color = "rgb(fdf6e3)";
        fade_on_empty = true;
        hide_input = false;

        position = "0, -100";
        halign = "center";
        valign = "center";
      };
      label = [
        {
          monitor = "";
          #   text = ''cmd[update:1000] echo "$(date +'%I:%M %p')"'';
          text = "$TIME";
          color = "rgb(fdf6e3)";
          font_size = 55;
          font_family = "JetBrainsMono Nerd Font";

          position = "0, 0";
          halign = "center";
          valign = "bottom";
        }
      ];
    };
  };
  ###HYPRLOCK END###

  ###HYPRIDLE###

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
        lock_cmd = "pidof hyprlock || hyprlock";
      };

      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 330;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };

  };

  ###HYPRIDLE END###
}
