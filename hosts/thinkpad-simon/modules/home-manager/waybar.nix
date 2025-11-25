{ config, pkgs, ... }:
let
  ewwPath = builtins.toPath ./eww;
in
{
  home.packages = with pkgs; [
    waybar
    nerd-fonts.jetbrains-mono
    eww
  ];

  # Waybar configuration
  xdg.configFile."waybar/config".text = ''

      {
        "layer": "top", // Waybar at top layer
        // "position": "bottom", // Waybar position (top|bottom|left|right)
        "height": 30, // Waybar height (to be removed for auto height)
        // "width": 1280, // Waybar width
        "spacing": 4, // Gaps between modules (4px)
        // Choose the order of the modules
        "modules-left": ["hyprland/workspaces", "hyprland/window"],
        //"modules-center": ["hyprland/window"],
        "modules-right": ["custom/mvg", "custom/tailscale", "custom/swaync", "custom/menu", "tray", "pulseaudio", "cpu", "memory", "backlight", "battery", "battery#bat2", "custom/scripted_clock", "custom/powermenu"],
        // Modules configuration
        "custom/powermenu": {
    	"format": " ",
    	"on-click": "~/.config/hypr/waybar/scripts/powermenu.sh",
    	"tooltip": false,
        },
        "custom/mvg": {
        "exec": "~/.config/hypr/waybar/scripts/waybar_mvg.sh",
        "return-type": "json",
        "interval": 20,
        "format": "󰔬 {}",
        "tooltip": true
        },

        "custom/tailscale" : {
            "exec": "~/.config/hypr/waybar/scripts/waybar-tailscale/waybar-tailscale.sh --status",
            "on-click": "exec ~/.config/hypr/scripts/waybar-tailscale/waybar-tailscale.sh --toggle",
            "exec-on-event": true,
            "format": "VPN: {icon}",
            "format-icons": {
                "connected": "on",        
                "stopped": "off"
            },
            "tooltip": true,
            "return-type": "json",
            "interval": 3,
        }

        "custom/swaync": {
    	"format": " ",
    	"on-click": "~/.config/hypr/swaync/scripts/tray_waybar.sh",
        "on-click-right": "swaync-client -C",
        "on-click-middle": "~/.config/hypr/swaync/scripts/notify_count.sh",
    	"tooltip": false,
        },
        "custom/menu": {
    	"format": " ",
    	"on-click": "~/.config/hypr/waybar/scripts/bar_menu.sh",
    	"tooltip": false,
        },
        "wlr/workspaces": {
    	"on-click": "activate",
        },
        "keyboard-state": {
            "numlock": true,
            "capslock": true,
            "format": "{name} {icon}",
            "format-icons": {
                "locked": "",
                "unlocked": ""
            }
        },
        "sway/mode": {
            "format": "<span style=\"italic\">{}</span>"
        },
        "sway/scratchpad": {
            "format": "{icon} {count}",
            "show-empty": false,
            "format-icons": ["", ""],
            "tooltip": true,
            "tooltip-format": "{app}: {title}"
        },
        "mpd": {
            "format": "{stateIcon} {consumeIcon}{randomIcon}{repeatIcon}{singleIcon}{artist} - {album} - {title} ({elapsedTime:%M:%S}/{totalTime:%M:%S}) ⸨{songPosition}|{queueLength}⸩ {volume}% ",
            "format-disconnected": "Disconnected ",
            "format-stopped": "{consumeIcon}{randomIcon}{repeatIcon}{singleIcon}Stopped ",
            "unknown-tag": "N/A",
            "interval": 2,
            "consume-icons": {
                "on": " "
            },
            "random-icons": {
                "off": "<span color=\"#f53c3c\"></span> ",
                "on": " "
            },
            "repeat-icons": {
                "on": " "
            },
            "single-icons": {
                "on": "1 "
            },
            "state-icons": {
                "paused": "",
                "playing": ""
            },
            "tooltip-format": "MPD (connected)",
            "tooltip-format-disconnected": "MPD (disconnected)"
        },
        "idle_inhibitor": {
            "format": "{icon}",
            "format-icons": {
                "activated": "",
                "deactivated": ""
            }
        },
        "tray": {
            // "icon-size": 21,
            "spacing": 10
        },
        "clock": {
            "tooltip-format": "{:%H:%M}",
            "tooltip": true,
            "format-alt": "{:%A, %B %d, %Y}",
    	    "format": "{:%I:%M %p}"
        },
        "custom/scripted_clock": {
            "type": "custom",
            "return-type": "json",
            "format": "{}",
            "tooltip": true,
            "interval": 10,
            "on-click": "$HOME/.config/hypr/waybar/scripts/clock_json.sh click-left",
            "on-click-right": "$HOME/.config/hypr/waybar/scripts/clock_json.sh click-right",
            "on-click-middle": "$HOME/.config/hypr/waybar/scripts/clock_json.sh click-middle",
            "exec": "$HOME/.config/hypr/waybar/scripts/clock_json.sh"
        },
        "cpu": {
            "format": "{usage}% ",
            "tooltip": false
        },
        "memory": {
            "format": "{}% "
        },
        "temperature": {
            // "thermal-zone": 2,
            // "hwmon-path": "/sys/class/hwmon/hwmon2/temp1_input",
            "critical-threshold": 80,
            // "format-critical": "{temperatureC}°C {icon}",
            "format": "{temperatureC}°C {icon}",
            "format-icons": ["", "", ""]
        },
        "backlight": {
            // "device": "acpi_video1",
            "format": "{percent}% {icon}",
            "format-icons": ["", "", "", "", "", "", "", "", ""],
            "tooltip-format": "Left click to save brightness.",
    	    "on-click": "~/.config/hypr/waybar/scripts/save_brightness.sh",
    	    "on-click-right": "~/.config/hypr/waybar/scripts/load_brightness.sh",
        },
        "battery": {
            "states": {
                // "good": 95,
                "warning": 30,
                "critical": 15
            },
            "interval": 10,
            "format": "{capacity}% {icon} {power}W",
            "format-charging": "{capacity}%  ",
            "format-plugged": "{capacity}%  ",
            "format-alt": "{time} {icon}",
            // "format-good": "", // An empty format will hide the module
            // "format-full": "",
            "format-icons": [" ", " ", " ", " ", " "]
        },
        "battery#bat2": {
            "bat": "BAT2"
        },
        "network": {
            // "interface": "wlp2*", // (Optional) To force the use of this interface
            "format-wifi": "{essid} ({signalStrength}%) ",
            "format-ethernet": "{ipaddr}/{cidr} ",
            "tooltip-format": "{ifname} via {gwaddr} ",
            "format-linked": "{ifname} (No IP) ",
            "format-disconnected": "Disconnected ⚠",
            "format-alt": "{ifname}: {ipaddr}/{cidr}"
        },
        "pulseaudio": {
            // "scroll-step": 1, // %, can be a float
            "format": "{volume}% {icon} {format_source}",
            "format-bluetooth": "{volume}% {icon} {format_source}",
            "format-bluetooth-muted": " {icon} {format_source}",
            "format-muted": " {format_source}",
            "format-source": "{volume}% ",
            "format-source-muted": "",
            "format-icons": {
                "headphone": "",
                "hands-free": "",
                "headset": "",
                "phone": "",
                "portable": "",
                "car": "",
                "default": ["", "", ""]
            },
            "on-click": "pavucontrol"
        },
        "custom/media": {
            "format": "{icon} {}",
            "return-type": "json",
            "max-length": 40,
            "format-icons": {
                "spotify": "",
                "default": "🎜"
            },
            "escape": true,
            "exec": "$HOME/.config/waybar/mediaplayer.py 2> /dev/null" // Script in resources folder
            // "exec": "$HOME/.config/waybar/mediaplayer.py --player spotify 2> /dev/null" // Filter player based on name
        }
    }




  '';

  # Waybar styling
  xdg.configFile."waybar/style.css".text = ''
    * {
        font-family: JetBrainsMono Nerd Font, FontAwesome, Roboto, Helvetica, Arial, sans-serif;
        font-size: 14px;
        font-weight: bold;
    }

    window#waybar {
        background-color: #073642;
        border-bottom: 8px solid #002b36;
        color: #fdf6e3;
        transition-property: background-color;
        transition-duration: .5s;
    }

    window#waybar.hidden {
        opacity: 0.2;
    }

    /*
    window#waybar.empty {
        background-color: transparent;
    }
    window#waybar.solo {
        background-color: #FFFFFF;
    }
    */

    button {
        all: unset;
        background-color: #2aa198;
        color: #002b36;
        border: none;
        border-bottom: 8px solid #008279;
        border-radius: 5px;
        margin-left: 4px;
        margin-bottom: 2px;
        font-family: JetBrainsMono Nerd Font, sans-sherif;
        font-weight: bold;
        font-size: 14px;
        padding-left: 15px;
        padding-right: 15px;
        transition: transform 0.1s ease-in-out;
    }

    button:hover {
        background: inherit;
        background-color: #1baea4;
        border-bottom: 8px solid #008f84;
    }

    button.active {
        background: inherit;
        background-color: #2fbfb4;
        border-bottom: 8px solid #009f94;
    }

    #mode {
        background-color: #64727D;
        border-bottom: 3px solid #ffffff;
    }

    #custom-scripted_clock,
    #clock,
    #battery,
    #cpu,
    #memory,
    #disk,
    #temperature,
    #backlight,
    #network,
    #pulseaudio,
    #wireplumber,
    #custom-media,
    #tray,
    #mode,
    #idle_inhibitor,
    #scratchpad,
    #custom-swaync,
    #custom-menu,
    #mpd {
        padding: 0 10px;
        color: #ffffff;
    }

    #window,
    #workspaces {
        margin: 0 4px;
    }

    /* If workspaces is the leftmost module, omit left margin */
    .modules-left > widget:first-child > #workspaces {
        margin-left: 0;
    }

    /* If workspaces is the rightmost module, omit right margin */
    .modules-right > widget:last-child > #workspaces {
        margin-right: 0;
    }

    #window {
        background-color: #1f4f5d;
        color: #fdf6e3;
        font-family: JetBrainsMono Nerd Font, monospace;
        font-size: 15px;
        font-weight: bold;
        border: none;
        border-bottom: 8px solid #164351;
        border-radius: 5px;
        margin-bottom: 2px;
        padding-left: 10px;
        padding-right: 10px;
    }

    #custom-swaync {
        background-color: #2aa198;
        color: #002b36;
        font-family: JetBrainsMono Nerd Font, monospace;
        font-size: 18px;
        font-weight: bold;
        border: none;
        border-bottom: 8px solid #008279;
        border-radius: 5px;
        margin-bottom: 2px;
        padding-left: 13px;
        padding-right: 9px;
    }

    #custom-menu {
        background-color: #2aa198;
        color: #002b36;
        font-family: JetBrainsMono Nerd Font, monospace;
        font-size: 18px;
        font-weight: bold;
        border: none;
        border-bottom: 8px solid #008279;
        border-radius: 5px;
        margin-bottom: 2px;
        padding-left: 14px;
        padding-right: 8px;
    }

    #custom-powermenu {
        background-color: #dc322f;
        color: #002b36;
        font-family: JetBrainsMono Nerd Font, monospace;
        font-size: 22px;
        font-weight: bold;
        border: none;
        border-bottom: 8px solid #ba0018;
        border-radius: 5px;
        margin-bottom: 2px;
        margin-right: 4px;
        padding-left: 14px;
        padding-right: 7px;
    }

    #custom-scripted_clock,
    #clock {
        background-color: #859900;
        color: #002b36;
        font-family: JetBrainsMono Nerd Font, monospace;
        font-size: 15px;
        font-weight: bold;
        border: none;
        border-bottom: 8px solid #6b8000;
        border-radius: 5px;
        margin-bottom: 2px;
    }

    #battery {
        background-color: #268bd2;
        color: #002b36;
        font-family: JetBrainsMono Nerd Font, monospace;
        font-size: 15px;
        font-weight: bold;
        border: none;
        border-bottom: 8px solid #0070b4;
        border-radius: 5px;
        margin-bottom: 2px;
    }

    @keyframes blink {
        to {
            background-color: #ffffff;
            color: #000000;
        }
    }

    #battery.critical:not(.charging) {
        background-color: #dc322f;
        color: #002b36;
        font-family: JetBrainsMono Nerd Font, monospace;
        font-size: 15px;
        font-weight: bold;
        border: none;
        border-bottom: 8px solid #ba0018;
        border-radius: 5px;
        margin-bottom: 2px;
    }

    label:focus {
        background-color: #000000;
    }

    #cpu {
        background-color: #2aa198;
        color: #002b36;
        font-family: JetBrainsMono Nerd Font, monospace;
        font-size: 15px;
        font-weight: bold;
        border: none;
        border-bottom: 8px solid #008279;
        border-radius: 5px;
        margin-bottom: 2px;
    }

    #memory {
        background-color: #d33682;
        color: #002b36;
        font-family: JetBrainsMono Nerd Font, monospace;
        font-size: 15px;
        font-weight: bold;
        border: none;
        border-bottom: 8px solid #ac0061;
        border-radius: 5px;
        margin-bottom: 2px;
    }

    #disk {
        background-color: #964B00;
    }

    #backlight {
        background-color: #2aa198;
        color: #002b36;
        font-family: JetBrainsMono Nerd Font, monospace;
        font-size: 15px;
        font-weight: bold;
        border: none;
        border-bottom: 8px solid #008279;
        border-radius: 5px;
        margin-bottom: 2px;
    }

    #network {
        background-color: #2980b9;
    }

    #network.disconnected {
        background-color: #f53c3c;
    }

    #pulseaudio {
        background-color: #dba81c;
        color: #002b36;
        font-family: JetBrainsMono Nerd Font, monospace;
        font-size: 15px;
        font-weight: bold;
        border: none;
        border-bottom: 8px solid #b58900;
        border-radius: 5px;
        margin-bottom: 2px;
    }

    /*
    #pulseaudio.muted {
        background-color: #90b1b1;
        color: #2a5c45;
    }
    */

    #wireplumber {
        background-color: #fff0f5;
        color: #000000;
    }

    #wireplumber.muted {
        background-color: #f53c3c;
    }

    #custom-media {
        background-color: #66cc99;
        color: #2a5c45;
        min-width: 100px;
    }

    #custom-media.custom-spotify {
        background-color: #66cc99;
    }

    #custom-media.custom-vlc {
        background-color: #ffa000;
    }

    #temperature {
        background-color: #f0932b;
    }

    #temperature.critical {
        background-color: #eb4d4b;
    }

    #tray {
        background-color: #d36d23;
        color: #002b36;
        font-family: JetBrainsMono Nerd Font, monospace;
        font-size: 15px;
        font-weight: bold;
        border: none;
        border-bottom: 8px solid #b35302;
        border-radius: 5px;
        margin-bottom: 2px;
    }

    #tray > .passive {
        -gtk-icon-effect: dim;
    }

    #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background-color: #eb4d4b;
    }

    #idle_inhibitor {
        background-color: #2d3436;
    }

    #idle_inhibitor.activated {
        background-color: #ecf0f1;
        color: #2d3436;
    }

    #mpd {
        background-color: #66cc99;
        color: #2a5c45;
    }

    #mpd.disconnected {
        background-color: #f53c3c;
    }

    #mpd.stopped {
        background-color: #90b1b1;
    }

    #mpd.paused {
        background-color: #51a37a;
    }

    #language {
        background: #00b093;
        color: #740864;
        padding: 0 5px;
        margin: 0 5px;
        min-width: 16px;
    }

    #keyboard-state {
        background: #97e1ad;
        color: #000000;
        padding: 0 0px;
        margin: 0 5px;
        min-width: 16px;
    }

    #keyboard-state > label {
        padding: 0 5px;
    }

    #keyboard-state > label.locked {
        background: rgba(0, 0, 0, 0.2);
    }

    #scratchpad {
        background: rgba(0, 0, 0, 0.2);
    }

    #scratchpad.empty {
    	background-color: transparent;
    }

    tooltip {
      background-color: #073642;
      border: none;
      border-bottom: 8px solid #002b36;
      border-radius: 5px;
    }

    tooltip decoration {
      box-shadow: none;
    }

    tooltip decoration:backdrop {
      box-shadow: none;
    }

    tooltip label {
      color: #fdf6e3;
      font-family: JetBrainsMono Nerd Font, monospace;
      font-size: 16px;
      padding-left: 5px;
      padding-right: 5px;
      padding-top: 0px;
      padding-bottom: 5px;
    }


  '';

  xdg.configFile = {
    # This will place the entire folder into ~/.config/hypr/eww
    "hypr/eww".source = ewwPath;
    "hypr/eww".recursive = true;
  };

}
