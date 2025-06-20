{ config, pkgs, ... }:
{
  xdg.configFile."hypr/waybar/scripts/clock_json.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      export LIFETIME=2000 # I just watched 'I Want To Eat Your Pancreas' so... I am a bit emotional right now... (I rate it a 10/10 for sure!)
      json_field () {
          echo -n "\"$1\":\"$2\""
          [[ "$3" == "1" ]] && echo -n ","
      }
      time_24h="$(date '+%H:%M')"
      time_12h="$(date '+%I:%M %p')"
      time_date="$(date '+%A, %B %d, %Y')"
      # Fix the 12 hour time if AM/PM isn't found... (I have a friend from Austria who has issues with this.)
      if echo "$time_12h" | grep -iE 'AM|PM' > /dev/null 2>&1; then
          : # Do nothing.
      else
          trimmed_display="$(echo "$time_12h" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
          minute_segment="$(echo "$time_24h" | cut -f2 -d ':')"
          hour_segment="$(echo "$time_24h" | cut -f1 -d ':')"
          am_pm="AM"
          if [[ "$hour_segment" -gt 12 ]]; then
              am_pm="PM"
              hour_segment=$(( ''${hour_segment} - 12 ))
          fi
          time_12h="''${hour_segment}:''${minute_segment} ''${am_pm}"
      fi
      hit_a_click=1
      if [[ "$1" == "click-middle" ]]; then
          notify-send -e -t "''${LIFETIME}" "Uptime is..." "$(uptime -p | sed 's/up //')"
      elif [[ "$1" == "click-left" ]]; then
          notify-send -e -t "''${LIFETIME}" "The date is..." "$time_date"
      elif [[ "$1" == "click-right" ]]; then
          notify-send -e -t "''${LIFETIME}" "12h -> 24h is..." "$time_12h -> $time_24h"
      else
          hit_a_click=0
      fi
      [[ $hit_a_click == 1 ]] && exit
      json_tooltip="$time_date"
      json_text="$time_12h"
      echo -n "{"
      json_field 'text' "$json_text" 1
      json_field 'tooltip' "$json_tooltip" 0
      echo "}"
    '';
  };

  xdg.configFile."hypr/lib.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash

      cache_theme_path="$HOME/.cache/hyprland_rice/theme"

      symlinks=(
          "alacritty:$HOME/.config/alacritty"
          "kitty:$HOME/.config/kitty"
          "rofi:$HOME/.config/rofi"
          "wezterm:$HOME/.config/wezterm"
      )

      is_tty () {
          [[ "$RICE_TTY_MODE" == 1 ]] && return 0
          [[ "$XDG_SESSION_TYPE" == "tty" ]] && return 0 || return 1
      }

      is_number () {
          cat /dev/null | head --lines "$1" > /dev/null 2>&1 && return 0 || return 1
      }

      tty_choose () {
          piped_in="$(cat)"

          prompt="$1"

          message=""
          stop_loop=0

          while [[ "$stop_loop" == 0 ]]; do
              cursor_move_up=0

              line_number=1
              while IFS= read -r line; do
                  echo -e "\033[0;36m[\033[0;96m''${line_number}\033[0;36m]:\033[0m \033[0;35m''${line}\033[0m" >&2
                  cursor_move_up=$(( $cursor_move_up + 1 ))
                  line_number=$(( $line_number + 1 ))
              done < <(echo "$piped_in")
              line_count=$(( $line_number - 1 ))

              echo " " >&2
              cursor_move_up=$(( $cursor_move_up + 1 ))

              prefix=""
              [[ "$message" == "" ]] || prefix+="[''${message}] "

              echo -en "\033[0;33m''${prefix}(Choose Number)\033[0m \033[0;93m''${prompt}\033[0m" >&2
              read chosen < /dev/tty
              cursor_move_up=$(( $cursor_move_up + 1 ))

              is_valid=0

              if is_number "$chosen"; then
                  if [[ "$chosen" -lt 1 ]]; then
                      message="Number too low!"
                  elif [[ "$chosen" -gt $(( $line_number - 1 )) ]]; then
                      message="Number too high!"
                  else
                      message=""
                      is_valid=1
                      stop_loop=1
                  fi
              else
                  message="Please choose a number!"
              fi

              echo -en "\033[''${cursor_move_up}A" >&2
              tput ed >&2

              if [[ "$is_valid" == 1 ]]; then
                  echo "$piped_in" | head --lines "$chosen" | tail --lines 1
              fi
          done
      }

      menu_choose () {
          piped_in="$(cat)"

          title="$1"

          prompt="$title"
          [[ "$prompt" == *":" ]] || [[ "$prompt" == *": " ]] || prompt="''${prompt}: "
          [[ "$prompt" == *" " ]] || prompt="''${prompt} "

          if is_tty; then
              if command -v fzf > /dev/null 2>&1; then
                  echo "$piped_in" | fzf --height ~50% --prompt "$prompt" --pointer "->"
              else
                  echo "$piped_in" | tty_choose "$prompt"
              fi
          else
              echo "$piped_in" | rofi -dmenu -p "$title"
          fi
      }

      get_current_wallpaper_path () {
          file_extension="png"

          extension_path="$cache_theme_path/wallpaper_extension.txt"

          if [[ -f "$extension_path" ]]; then
              file_extension="$(cat "$extension_path")"
          fi

          echo "''${cache_theme_path}/wallpaper.''${file_extension}"
      }

      set_wallpaper () {
          swww_filter="Lanczos3"
          swww_animation="grow"

          [[ "$2" == "" ]] || swww_filter="$2"
          [[ "$3" == "" ]] || swww_animation="$3"

          echo "Setting wallpaper..."
          echo "Filter: ''${swww_filter}"
          echo "Animation: ''${swww_animation}"
          echo "Wallpaper Path: '$1'"

      	swww img "$1" --filter "$swww_filter" -t "$swww_animation" --transition-pos center || return 1
      }

      set_wallpaper_themed () {
          wallpaper_animation="$1"
          wallpaper_filter="" # Empty means default. :-)

          wallpaper_info_dir_path="''${cache_theme_path}/wallpaper_info"

          if [[ -d "$wallpaper_info_dir_path" ]]; then
              [[ -f "''${wallpaper_info_dir_path}/filter" ]] && wallpaper_filter="$(cat "''${wallpaper_info_dir_path}/filter")"
          else
              echo "Wallpaper info directory does not exist... assuming defaults..."
          fi

          set_wallpaper "$(get_current_wallpaper_path)" "$wallpaper_filter" "$wallpaper_animation"
      }

      run_hook () {
          chmod +x "$HOME/.hyprland_rice/autostart_$1"
          $HOME/.hyprland_rice/autostart_$1
      }

      eww-rice () {
      	eww --config ~/.config/hypr/eww/ $*
      }

      abs_path () {
          new_path="$1"

          home_sed="$(echo "$HOME" | sed 's/\//\\\//g')"

          [[ "$new_path" == "~"* ]] && new_path="$(echo $new_path | sed "s/^~/$home_sed/")"

          echo "$new_path"
      }

    '';
  };

  xdg.configFile."hypr/swaync/scripts/tray_waybar.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      sleep 0.1
      swaync-client -t &
    '';
  };

  xdg.configFile."hypr/waybar/scripts/bar_menu.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      sleep 0.1
      $HOME/.config/hypr/eww/scripts/waybar/bar_menu & disown

    '';
  };

  xdg.configFile."hypr/waybar/scripts/powermenu.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      sleep 0.1
      $HOME/.config/hypr/eww/scripts/waybar/powermenu & disown

    '';
  };
}
