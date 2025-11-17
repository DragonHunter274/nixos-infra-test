{ config, pkgs, ... }:

{

  home.packages = with pkgs; [
    rofi
  ];

  xdg.configFile = {
    "rofi/config.rasi".text = ''

      configuration {
          modi: "drun,run,window";
          lines: 5;
          font: "JetBrains Mono Nerd Font Bold 14";
          show-icons: true;
          terminal: "alacritty";
          drun-display-format: "{icon} {name}";
          window-format: "{icon} {t}";
          location: 0;
          disable-history: false;
          hide-scrollbar: true;
          sidebar-mode: true;
          display-drun: " 󰀘  Apps ";
          display-run: "   Command ";
          display-window: "   Window ";
      }

      @theme "theme"

      element-text {
          background-color: #00000000;
          text-color: inherit;
      }

      element-text selected {
          background-color: #00000000;
          text-color: inherit;
      }

      mode-switcher {
          background-color: #00000000;
      }

      window {
          height: 400px;
          width: 600px;
          border: 0px;
          border-radius: 10px;
          border: 0px 0px 8px 0px;
          border-color: @window-underline;
          background-color: @window;
          padding: 4px 8px 4px 8px;
          fullscreen: false;
      }

      mainbox {
          background-color: #00000000;
      }

      inputbar {
          children: [prompt,entry];
          background-color: #00000000;
          border-radius: 5px;
          padding: 2px;
          margin: 0px -5px -4px -5px;
      }

      prompt {
          background-color: @button;
          padding: 12px;
          text-color: @bg-col;
          border-radius: 5px;
          margin: 8px 0px 0px 8px;
          border: 0px 0px 8px 0px;
          border-color: @button-underline;
      }

      textbox-prompt-colon {
          expand: false;
          str: ":";
      }

      entry {
          padding: 12px 13px -4px 11px;
          margin: 8px 8px 0px 8px;
          text-color: @fg-col;
          background-color: @blank;
          border-radius: 5px;
          border: 0px 0px 8px 0px;
          border-color: @blank-underline;
      }

      listview {
          border: 0px 0px 0px;
          margin: 27px 5px -13px 5px;
          background-color: #00000000;
          columns: 1;
      }

      element {
          padding: 12px 12px 12px 12px;
          background-color: @blank;
          text-color: @fg-col;
          margin: 0px 0px 8px 0px;
          border-radius: 5px;
          border: 0px 0px 8px 0px;
          border-color: @blank-underline;
      }

      element-icon {
          size: 25px;
          background-color: #00000000;
      }

      element selected {
          background-color: @button;
          text-color: @fg-col2;
          border-radius: 5px;
          border: 0px 0px 8px 0px;
          border-color: @button-underline;
      }

      mode-switcher {
          spacing: 0;
      }

      button {
          padding: 12px;
          margin: 10px 5px 10px 5px;
          background-color: @blank;
          text-color: @tab;
          vertical-align: 0.5;
          horizontal-align: 0.5;
          border-radius: 5px;
          border: 0px 0px 8px 0px;
          border-color: @blank-underline;
      }

      button selected {
          background-color: @bg-col-light;
          text-color: @tab-selected;
          border-radius: 5px;
          border: 0px 0px 8px 0px;
          border-color: @button-underline;
      }


    '';

  };

  xdg.configFile = {
    "rofi/theme.rasi".text = ''
      * {
          bg-col: #002b36;
          bg-col-transparent: #002b36dd;
          bg-col-element: #002b36df;
          bg-col-light: #2aa198;
          border-col: #2aa198;
          selected-col: #2aa198;
          tab: #2aa198;
          tab-selected: #002b36;
          fg-col: #fdf6e3;
          fg-col2: #002b36;
          blank: #073642;
          blank-underline: #002b36;
          button: #2aa198;
          button-underline: #008279;
          window: #1f4f5d;
          window-underline: #164351;

          width: 600;
      }
    '';
  };

}
