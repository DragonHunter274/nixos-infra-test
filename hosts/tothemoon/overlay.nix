final: prev: {
  open-bamboo-networking = final.callPackage ./obn.nix { };

  orca-slicer = prev.orca-slicer.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.makeWrapper ];

    # nixpkgs' orca-slicer already wraps the binary (GTK/GDK env, etc.) —
    # this appends another wrapProgram call rather than replacing it.
    postFixup = (old.postFixup or "") + ''
      wrapProgram $out/bin/orca-slicer \
        --run '
          plugdir="$HOME/.config/OrcaSlicer/plugins"
          mkdir -p "$plugdir"
          ln -sf "${final.open-bamboo-networking}/lib/libbambu_networking_02.03.00.99.so" \
            "$plugdir/libbambu_networking_02.03.00.99.so"
          ln -sf "${final.open-bamboo-networking}/lib/libBambuSource.so" \
            "$plugdir/libBambuSource.so"

          conf="$HOME/.config/OrcaSlicer/OrcaSlicer.conf"
          jq="${final.jq}/bin/jq"
          mkdir -p "$(dirname "$conf")"
          # A fresh/deleted config has no file yet — seed one so the
          # patch below still lands before OrcaSlicer own first-run
          # defaults (which leave installed_networking unset) take over.
          [ -s "$conf" ] || printf "{}" > "$conf"
          if [ "$("$jq" -r ".app.network_plugin_version // empty" "$conf" 2>/dev/null)" != "02.03.00.99" ] \
            || [ "$("$jq" -r ".app.installed_networking // empty" "$conf" 2>/dev/null)" != "true" ]; then
            tmp="$(mktemp)"
            if "$jq" ".app.network_plugin_version = \"02.03.00.99\" | .app.installed_networking = \"true\"" "$conf" > "$tmp"; then
              mv "$tmp" "$conf"
            else
              rm -f "$tmp"
            fi
          fi
        '
    '';
  });
}
