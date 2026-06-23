# Headless game streaming: Sunshine capturing a dedicated headless Sway
# compositor, fully isolated from the niri desktop (separate Wayland display,
# audio sink, and input). Ported from
# https://github.com/daaaaan/sunshine-headless-sway and adapted for NixOS,
# niri, and AMD — the upstream's NVIDIA-only `WLR_RENDERER=gles2` workaround is
# unnecessary on amdgpu, which uses the default renderer + VAAPI.
#
# Two user services:
#   sway-sunshine.service  — headless Sway compositor on its own Wayland display
#   sunshine.service       — Sunshine pointed at that display (capture = wlr)
#
# pkgs.steam-old (the isolated /mnt/data2/SteamOld library) is launched *inside*
# the headless Sway, so it streams to Moonlight while the niri desktop — its
# display, audio and input — is untouched. Because steam-old is a fully separate
# Steam instance, no migration/shutdown of a main Steam is needed.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) getExe;

  swaybgBin = getExe pkgs.swaybg;
  footBin = getExe pkgs.foot;
  # Same noctalia shell the niri session runs (flake input package), referenced
  # by absolute path since the sway service runs with a controlled PATH.
  noctaliaBin = getExe inputs.noctalia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  sunshineBin = getExe config.services.sunshine.package;
  audioSink = "sink-sunshine-stereo";

  # Per-user runtime paths. User services always have $XDG_RUNTIME_DIR
  # (= /run/user/<uid>), so deriving these in shell avoids systemd %-specifier
  # quirks in Environment=.
  sockShell = "$XDG_RUNTIME_DIR/sway-sunshine.sock";
  displayShell = "$XDG_RUNTIME_DIR/sway-sunshine.display";

  # Headless Sway config. wlroots' headless backend exposes output HEADLESS-1
  # (the only real output → wlr capture index 0). On startup Sway writes its
  # actual WAYLAND_DISPLAY to a file: Sway picks wayland-N at runtime and
  # ignores any preset WAYLAND_DISPLAY (confirmed in sway/server.c), so the
  # Sunshine service discovers the name from this file rather than guessing.
  swayConfig = pkgs.writeText "sway-sunshine.config" ''
    # Default headless output — 1080p; set-resolution overrides it per client.
    output HEADLESS-1 resolution 1920x1080@60Hz
    output * allow_tearing yes
    output * max_render_time off

    # Dark background so the stream isn't black before an app launches.
    exec ${swaybgBin} -c '#1a1a2e'

    # Run the noctalia shell (same one the niri session uses).
    exec ${noctaliaBin}

    # Publish the runtime WAYLAND_DISPLAY for the Sunshine service to read.
    exec echo "$WAYLAND_DISPLAY" > "$XDG_RUNTIME_DIR/sway-sunshine.display"

    # Input isolation: disable physical devices, enable only Sunshine's virtual
    # passthrough inputs (vendor 0xBEEF=48879 / product 0xDEAD=57005).
    input * events disabled
    input "48879:57005:Keyboard_passthrough" events enabled
    input "48879:57005:Mouse_passthrough" events enabled
    input "48879:57005:Mouse_passthrough_(absolute)" events enabled
    input "48879:57005:Touch_passthrough" events enabled
    input "48879:57005:Pen_passthrough" events enabled
    input "1356:3302:Sunshine_PS5_(virtual)_pad_Touchpad" events enabled
    input "48879:57005:Mouse_passthrough" accel_profile flat
    input "48879:57005:Mouse_passthrough_(absolute)" accel_profile flat

    # --- Standard sway keybindings (mirrors the upstream default config) ---
    set $mod Mod4
    set $left h
    set $down j
    set $up k
    set $right l
    set $term ${footBin}

    # Apps / window control
    bindsym $mod+Return exec $term
    bindsym $mod+Shift+q kill
    bindsym $mod+Shift+c reload
    floating_modifier $mod normal

    # Move focus (vim keys + arrows)
    bindsym $mod+$left focus left
    bindsym $mod+$down focus down
    bindsym $mod+$up focus up
    bindsym $mod+$right focus right
    bindsym $mod+Left focus left
    bindsym $mod+Down focus down
    bindsym $mod+Up focus up
    bindsym $mod+Right focus right

    # Move the focused window
    bindsym $mod+Shift+$left move left
    bindsym $mod+Shift+$down move down
    bindsym $mod+Shift+$up move up
    bindsym $mod+Shift+$right move right
    bindsym $mod+Shift+Left move left
    bindsym $mod+Shift+Down move down
    bindsym $mod+Shift+Up move up
    bindsym $mod+Shift+Right move right

    # Workspaces (1-9, 0 = 10)
    bindsym $mod+1 workspace number 1
    bindsym $mod+2 workspace number 2
    bindsym $mod+3 workspace number 3
    bindsym $mod+4 workspace number 4
    bindsym $mod+5 workspace number 5
    bindsym $mod+6 workspace number 6
    bindsym $mod+7 workspace number 7
    bindsym $mod+8 workspace number 8
    bindsym $mod+9 workspace number 9
    bindsym $mod+0 workspace number 10
    bindsym $mod+Shift+1 move container to workspace number 1
    bindsym $mod+Shift+2 move container to workspace number 2
    bindsym $mod+Shift+3 move container to workspace number 3
    bindsym $mod+Shift+4 move container to workspace number 4
    bindsym $mod+Shift+5 move container to workspace number 5
    bindsym $mod+Shift+6 move container to workspace number 6
    bindsym $mod+Shift+7 move container to workspace number 7
    bindsym $mod+Shift+8 move container to workspace number 8
    bindsym $mod+Shift+9 move container to workspace number 9
    bindsym $mod+Shift+0 move container to workspace number 10

    # Layout
    bindsym $mod+b splith
    bindsym $mod+v splitv
    bindsym $mod+s layout stacking
    bindsym $mod+w layout tabbed
    bindsym $mod+e layout toggle split
    bindsym $mod+f fullscreen
    bindsym $mod+Shift+space floating toggle
    bindsym $mod+space focus mode_toggle
    bindsym $mod+a focus parent

    # Resize mode
    mode "resize" {
        bindsym $left resize shrink width 10px
        bindsym $down resize grow height 10px
        bindsym $up resize shrink height 10px
        bindsym $right resize grow width 10px
        bindsym Left resize shrink width 10px
        bindsym Down resize grow height 10px
        bindsym Up resize shrink height 10px
        bindsym Right resize grow width 10px
        bindsym Return mode "default"
        bindsym Escape mode "default"
    }
    bindsym $mod+r mode "resize"
  '';

  # Launch the headless compositor with a deterministic IPC socket. Uses
  # writeShellScript (NOT writeShellApplication) so the inherited session PATH
  # survives, and prepends bash/coreutils/steam-old: Sway runs every `exec` via
  # `execlp("sh", "-c", …)`, which searches only $PATH (never /bin/sh), so its
  # spawned apps — swaybg, the display-file writer, and steam-old — need `sh`
  # plus a usable PATH present here.
  swayLauncher = pkgs.writeShellScript "sway-sunshine" ''
    export SWAYSOCK="${sockShell}"
    export PATH="${
      lib.makeBinPath [
        pkgs.bash
        pkgs.coreutils
        pkgs.steam-old
      ]
    }:$PATH"
    ${pkgs.coreutils}/bin/rm -f "$SWAYSOCK" "${displayShell}"
    exec ${getExe pkgs.sway} --config ${swayConfig}
  '';

  # Sunshine launcher: wait for the headless Sway to publish its display + IPC
  # socket, then run Sunshine against that display. (Sunshine's own systemd unit
  # forces PATH unset; writeShellApplication bakes its own PATH, and the config
  # is rendered from services.sunshine.settings — identical to what the module
  # would pass.)
  sunshineConf =
    (pkgs.formats.keyValue { }).generate "sunshine.conf"
      config.services.sunshine.settings;
  sunshineLauncher = pkgs.writeShellApplication {
    name = "sunshine-headless";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      for _ in $(seq 1 100); do
        if [ -S "${sockShell}" ] && [ -s "${displayShell}" ]; then break; fi
        sleep 0.1
      done
      WAYLAND_DISPLAY="$(cat "${displayShell}")"
      export WAYLAND_DISPLAY
      exec ${sunshineBin} ${sunshineConf}
    '';
  };

  # --- Sunshine prep-cmd / app scripts (all referenced by absolute path) ---

  setResolution = pkgs.writeShellApplication {
    name = "sunshine-set-resolution";
    runtimeInputs = [
      pkgs.sway
      pkgs.coreutils
    ];
    text = ''
      swaymsg -s "${sockShell}" \
        "output HEADLESS-1 mode ''${SUNSHINE_CLIENT_WIDTH}x''${SUNSHINE_CLIENT_HEIGHT}@''${SUNSHINE_CLIENT_FPS}Hz"
      sleep 1 # let the mode settle before capture starts
    '';
  };

  resetResolution = pkgs.writeShellApplication {
    name = "sunshine-reset-resolution";
    runtimeInputs = [ pkgs.sway ];
    text = ''
      swaymsg -s "${sockShell}" "output HEADLESS-1 mode 1920x1080@60Hz"
    '';
  };

  # Watcher: Sunshine sets audio_sink as the *system* default on connect; this
  # restores the host's previous default within seconds so desktop audio isn't
  # hijacked into the stream. Spawned detached via systemd-run so it survives
  # prep-cmd teardown.
  sinkRestoreWatcher = pkgs.writeShellApplication {
    name = "sunshine-sink-restore-watch";
    runtimeInputs = [
      pkgs.wireplumber
      pkgs.gnugrep
      pkgs.coreutils
    ];
    text = ''
      target="$1"
      for _ in $(seq 1 30); do
        sleep 1
        cur="$(wpctl status 2>/dev/null | grep -A20 'Sinks:' | grep '\*' | head -1 | grep -oE '[0-9]+' | head -1 || true)"
        if [ -n "$cur" ] && [ "$cur" != "$target" ]; then
          wpctl set-default "$target"
          exit 0
        fi
      done
    '';
  };

  restoreDefaultSink = pkgs.writeShellApplication {
    name = "sunshine-restore-default-sink";
    runtimeInputs = [
      pkgs.wireplumber
      pkgs.gnugrep
      pkgs.coreutils
      pkgs.systemd
    ];
    text = ''
      SINK_ID="$(wpctl status 2>/dev/null | grep -A20 'Sinks:' | grep '\*' | head -1 | grep -oE '[0-9]+' | head -1 || true)"
      if [ -z "$SINK_ID" ]; then exit 0; fi
      systemctl --user stop sunshine-sink-restore.service 2>/dev/null || true
      systemctl --user reset-failed sunshine-sink-restore.service 2>/dev/null || true
      exec systemd-run --user --no-block --unit=sunshine-sink-restore \
        ${getExe sinkRestoreWatcher} "$SINK_ID"
    '';
  };

  # Launch the isolated steam-old library in Big Picture inside the headless
  # Sway (swaymsg exec runs it in that session, so it renders to HEADLESS-1).
  startSteamOld = pkgs.writeShellApplication {
    name = "sunshine-start-steam-old";
    runtimeInputs = [ pkgs.sway ];
    text = ''
      export SWAYSOCK="${sockShell}"
      swaymsg exec "${getExe pkgs.steam-old} steam://open/bigpicture"
    '';
  };

  # Teardown on disconnect: kill *only* steam-old (its bwrap cmdline uniquely
  # contains the SteamOld bind — never matches a main Steam), then reset the
  # headless output to 1080p.
  stopSteamOld = pkgs.writeShellApplication {
    name = "sunshine-stop-steam-old";
    runtimeInputs = [
      pkgs.procps
      pkgs.sway
    ];
    text = ''
      pkill -f 'SteamOld' || true
      swaymsg -s "${sockShell}" "output HEADLESS-1 mode 1920x1080@60Hz" || true
    '';
  };

  # Debug helper run inside a foot terminal on the headless output: prints the
  # device list Sway currently sees, then streams live input events at the
  # libinput (device) level — focus-independent, so keyboard keys show even
  # though the terminal, not a separate window, holds focus. (wev would only
  # report keys to the focused surface, which is why it appeared to miss the
  # keyboard.) Press keys / move the Moonlight mouse to confirm input arrives.
  inputDebugTerm = pkgs.writeShellScript "sunshine-input-debug-term" ''
    export SWAYSOCK="${sockShell}"
    echo "=== sway devices (send_events = enabled/disabled) ==="
    ${pkgs.sway}/bin/swaymsg -t get_inputs \
      | ${pkgs.jq}/bin/jq -r '.[] | "\(.identifier)  [\(.type)]  send_events=\(.libinput.send_events // "n/a")"'
    echo
    echo "=== libinput events — focus-independent; press keys / move mouse (Ctrl+C to quit) ==="
    exec ${pkgs.libinput}/bin/libinput debug-events
  '';

  inputDebug = pkgs.writeShellApplication {
    name = "sunshine-input-debug";
    runtimeInputs = [ pkgs.sway ];
    text = ''
      export SWAYSOCK="${sockShell}"
      swaymsg exec "${footBin} ${inputDebugTerm}"
    '';
  };

  # Teardown on disconnect: close the debug terminal + event reader so windows
  # don't pile up across sessions, then reset the headless output to 1080p.
  stopInputDebug = pkgs.writeShellApplication {
    name = "sunshine-stop-input-debug";
    runtimeInputs = [
      pkgs.procps
      pkgs.sway
    ];
    text = ''
      pkill -f 'sunshine-input-debug-term' || true
      pkill -f 'libinput debug-events' || true
      pkill -x foot || true
      swaymsg -s "${sockShell}" "output HEADLESS-1 mode 1920x1080@60Hz" || true
    '';
  };
in
{
  # Sunshine module: provides the package, uinput (hardware.uinput.enable), its
  # udev rules, firewall ports, avahi discovery, and renders sunshine.conf /
  # apps.json from the options below. We override its systemd unit (further
  # down) to point at the headless Sway instead of the live session.
  services.sunshine = {
    enable = true;
    openFirewall = true;
    capSysAdmin = false; # wlr-screencopy capture needs no elevated capability

    settings = {
      capture = "wlr";
      audio_sink = audioSink;
      min_threads = 6;
    };

    applications.apps = [
      {
        # Stream the headless desktop itself (handy for setup / non-Steam apps).
        name = "Desktop";
        image-path = "desktop.png";
        prep-cmd = [
          {
            do = getExe restoreDefaultSink;
            undo = "";
          }
          {
            do = getExe setResolution;
            undo = getExe resetResolution;
          }
        ];
      }
      {
        name = "Steam (Old Library)";
        image-path = "steam.png";
        detached = [ (getExe startSteamOld) ];
        prep-cmd = [
          {
            do = getExe restoreDefaultSink;
            undo = "";
          }
          {
            do = getExe setResolution;
            undo = getExe stopSteamOld;
          }
        ];
      }
      {
        # Debugging: opens a terminal on the streamed output showing Sway's
        # device list + live mouse/keyboard events. Confirms Moonlight input
        # reaches the headless Sway.
        name = "Input Debug";
        image-path = "desktop.png";
        detached = [ (getExe inputDebug) ];
        prep-cmd = [
          {
            do = getExe setResolution;
            undo = getExe stopInputDebug;
          }
        ];
      }
    ];
  };

  # Headless Sway compositor service.
  systemd.user.services.sway-sunshine = {
    description = "Headless Sway compositor for Sunshine streaming";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];

    environment = {
      WLR_BACKENDS = "headless,libinput";
      LIBSEAT_BACKEND = "noop";
      WLR_LIBINPUT_NO_DEVICES = "1";
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "sway";
      # Apps launched in this session output to the isolated null sink, never
      # the host's speakers.
      PULSE_SINK = audioSink;
    };

    serviceConfig = {
      Type = "simple";
      ExecStart = swayLauncher;
      Restart = "on-failure";
      RestartSec = "5";
    };
  };

  # Point the module's Sunshine unit at the headless Sway: order it after that
  # compositor and replace ExecStart with the discovery wrapper.
  systemd.user.services.sunshine = {
    requires = [ "sway-sunshine.service" ];
    after = [ "sway-sunshine.service" ];
    serviceConfig.ExecStart = lib.mkForce (getExe sunshineLauncher);
  };

  # Persistent PipeWire null sink that always exists (even when Moonlight is
  # disconnected), so game audio has a stable target and never falls back to
  # the host output.
  services.pipewire.extraConfig.pipewire."99-sunshine-null-sink" = {
    "context.objects" = [
      {
        factory = "adapter";
        args = {
          "factory.name" = "support.null-audio-sink";
          "node.name" = audioSink;
          "node.description" = "Sunshine Streaming Sink (Stereo)";
          "media.class" = "Audio/Sink";
          "audio.position" = [
            "FL"
            "FR"
          ];
          "monitor.channel-volumes" = true;
        };
      }
    ];
  };

  # Input isolation is intentionally NOT applied yet. The upstream approach
  # (stripping ID_INPUT from the 0xBEEF/0xDEAD virtual devices) hides them from
  # the host compositor, but on this setup it ALSO hides them from the headless
  # Sway: both run libinput on seat0, which filters on ID_INPUT, so the streamed
  # cursor never moves (confirmed via swaymsg get_inputs). Without the rule Sway
  # sees the devices and input works — the trade-off is Moonlight input also
  # reaches the niri desktop ("leak"). Proper niri-side isolation is a follow-up:
  # niri has no mutter-device-ignore equivalent, so it likely needs a dedicated
  # logind seat for the virtual devices rather than a udev tag.
}
