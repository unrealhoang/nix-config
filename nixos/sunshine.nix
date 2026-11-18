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
# Steam is launched *inside* the headless Sway so it streams to Moonlight on its
# own display. Steam is single-instance, so the launcher shuts down any running
# Steam first to migrate the one instance into this session (see startSteam).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe;

  swaybgBin = getExe pkgs.swaybg;
  footBin = getExe pkgs.foot;
  fuzzelBin = getExe pkgs.fuzzel;
  steamBin = getExe config.programs.steam.package;
  sunshineBin = getExe config.services.sunshine.package;
  audioSink = "sink-sunshine-stereo";

  # swaybar status generator (i3bar/swaybar JSON protocol): renders a clickable
  # "Apps" button (a named block) plus a clock. With click_events, swaybar makes
  # each block a hotspot and writes a click-event JSON object to our stdin on
  # click; a background reader launches fuzzel when the "launcher" block is hit.
  # Clicks only fire over the block itself (label-only), and — per sway PR #6482
  # — hotspots take priority over any bar bindsym. The matcher greps the bare
  # value "launcher" rather than a quoted "name":"launcher" pair, because
  # swaybar serialises the event with a space ("name": "launcher") and may split
  # it across lines; matching the value is robust to both. Only the launcher
  # block carries that string, so the clock block's clicks are ignored.
  barStatus = pkgs.writeShellApplication {
    name = "sway-sunshine-bar";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.fuzzel
      pkgs.procps
    ];
    text = ''
      # swaybar delivers one click-event JSON object per click on our stdin and
      # reads status blocks from our stdout. Read CLICKS in the foreground and
      # run the status/clock WRITER in the background — NOT the other way around.
      # A backgrounded command (`&`) in a shell without job control (which is
      # how systemd runs this) has its stdin silently redirected from /dev/null,
      # so a backgrounded reader hits EOF immediately, exits, and never sees a
      # single click — the exact bug that made the launcher button dead. The
      # writer only needs stdout (which background jobs keep), so it's the safe
      # one to background. The leading "[" and the clock block's events never
      # match *launcher*, so only the "Apps" block launches fuzzel.
      (
        # Header (click_events on), then the infinite array: empty first
        # element, comma-led updates.
        printf '{"version":1,"click_events":true}\n[\n[]\n'
        while :; do
          clock=$(date +'%a %d %b   %H:%M')
          printf ',[{"name":"launcher","full_text":"  Apps  ","background":"#89b4fa","color":"#1a1a2e"},{"full_text":"  %s  ","color":"#cdd6f4"}]\n' "$clock"
          sleep 30
        done
      ) &

      while IFS= read -r line; do
        case "$line" in
          # Detach fuzzel's stdin/stdout from this script's: our stdout IS the
          # pipe swaybar parses as i3bar JSON, so anything fuzzel (or an app it
          # launches, which inherits these fds) prints there corrupts the
          # stream ("invalid i3bar json"). stderr is left on the journal for
          # debugging. fuzzel still finds the display via the inherited env.
          *launcher*) pgrep -x fuzzel >/dev/null || fuzzel </dev/null >/dev/null & ;;
        esac
      done
    '';
  };

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
    # App launcher. fuzzel is spawned by sway, so it (and the apps it launches)
    # inherit sway's WAYLAND_DISPLAY and open on the streamed output.
    bindsym $mod+d exec ${fuzzelBin}
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

    # Status bar (swaybar, bundled with sway). Its status_command renders an
    # "Apps" button label + clock (see barStatus); left-clicking anywhere on the
    # bar opens the launcher, so no window/game click is intercepted the way
    # --whole-window would.
    bar {
        position top
        # sway spawns the bar by bare name "swaybar" via the session PATH, which
        # this headless-only sway isn't on (no system-wide install), so the bar
        # silently never appears. Pin the absolute swaybar from the sway package.
        swaybar_command ${pkgs.sway}/bin/swaybar
        status_command ${getExe barStatus}
        # No bar-wide bindsym: the launcher is scoped to the "Apps" block via
        # the status click-event protocol (see barStatus), so clicks elsewhere
        # on the bar do nothing.
        # Disable the tray: swaybar otherwise adopts the shared user session's
        # StatusNotifier items (Sunshine, blueman) and renders their SVGs — which
        # it cannot parse — as broken/coloured fallback icons (the stray "red"
        # icon on the right). This headless bar has no use for a tray.
        tray_output none
        colors {
            background #1a1a2e
            statusline #cdd6f4
            focused_workspace  #89b4fa #89b4fa #1a1a2e
            inactive_workspace #1a1a2e #1a1a2e #cdd6f4
        }
    }
  '';

  # Launch the headless compositor with a deterministic IPC socket. Uses
  # writeShellScript (NOT writeShellApplication) so the inherited session PATH
  # survives, and prepends bash/coreutils/steam: Sway runs every `exec` via
  # `execlp("sh", "-c", …)`, which searches only $PATH (never /bin/sh), so its
  # spawned apps — swaybg, the display-file writer, and steam — need `sh`
  # plus a usable PATH present here.
  swayLauncher = pkgs.writeShellScript "sway-sunshine" ''
    export SWAYSOCK="${sockShell}"
    # The bare systemd-user-service PATH only has a minimal toolset, so apps
    # launched by name (fuzzel uses each .desktop's `Exec=`, e.g. "alacritty")
    # aren't found and silently fail to spawn. Add the bin dirs where apps live:
    # system, NixOS-integrated home-manager, and the STANDALONE home-manager
    # profile ($HOME/.nix-profile + .local/state/nix/profile) this host actually
    # installs user apps into. Plus sh/coreutils/steam for Sway's own `exec`.
    export PATH="${
      lib.makeBinPath [
        pkgs.bash
        pkgs.coreutils
        config.programs.steam.package
      ]
    }:/run/current-system/sw/bin:/etc/profiles/per-user/unreal/bin:$HOME/.nix-profile/bin:$HOME/.local/state/nix/profile/bin:$PATH"
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

  # Launch Steam in Big Picture inside the headless Sway. Steam is
  # single-instance, so first shut down any running Steam (e.g. on the niri
  # desktop): that migrates the one instance into this session instead of
  # forwarding the launch to the desktop's instance. (No-op if Steam isn't
  # running.) swaymsg exec runs it in this session, so it renders to HEADLESS-1.
  startSteam = pkgs.writeShellApplication {
    name = "sunshine-start-steam";
    runtimeInputs = [
      pkgs.sway
      pkgs.procps
      pkgs.coreutils
    ];
    text = ''
      export SWAYSOCK="${sockShell}"
      if pgrep -x steam >/dev/null 2>&1; then
        ${steamBin} -shutdown || true
        for _ in $(seq 1 15); do
          pgrep -x steam >/dev/null 2>&1 || break
          sleep 1
        done
      fi
      swaymsg exec "${steamBin} steam://open/bigpicture"
    '';
  };

  # Teardown on disconnect: shut the streamed Steam down cleanly, then reset the
  # headless output to 1080p.
  stopSteam = pkgs.writeShellApplication {
    name = "sunshine-stop-steam";
    runtimeInputs = [ pkgs.sway ];
    text = ''
      ${steamBin} -shutdown || true
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

  # --- Input isolation via VT switch (run as root via the sudo rule below) ---
  # niri and the headless sway both use libinput on seat0, so a udev tag can't
  # reveal a device to one and hide it from the other (and seatd can't provide a
  # second seat — it hardcodes "seat0"). Instead, on stream start we switch the
  # active VT off niri's: logind then marks niri's session inactive and PAUSES
  # its input devices, so streamed input no longer leaks into the desktop. The
  # headless sway is unaffected — it opens devices directly (input group), not
  # via logind — so it keeps receiving input. On stream end we switch back.
  vtFile = "/run/sunshine-prestream-vt";
  # >NAutoVTs (default 6) so no getty spawns there; the console is blank and any
  # leaked keystrokes land in a buffer no process reads.
  awayVt = "12";
  vtAway = pkgs.writeShellApplication {
    name = "sunshine-vt-away";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.kbd
    ];
    text = ''
      cur="$(cat /sys/class/tty/tty0/active 2>/dev/null | tr -dc '0-9' || true)"
      if [ -n "$cur" ]; then printf '%s' "$cur" > ${vtFile}; fi
      exec chvt ${awayVt}
    '';
  };
  vtBack = pkgs.writeShellApplication {
    name = "sunshine-vt-back";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.kbd
    ];
    text = ''
      vt="$(cat ${vtFile} 2>/dev/null || true)"
      [ -n "$vt" ] || vt=1
      exec chvt "$vt"
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
      # Runs for every app (unless excluded): switch the VT off niri on connect
      # (isolating its input), switch back on disconnect. Absolute sudo path
      # since Sunshine runs prep-cmds with PATH unset; NOPASSWD rule below.
      global_prep_cmd = builtins.toJSON [
        {
          do = "${config.security.wrapperDir}/sudo ${getExe vtAway}";
          undo = "${config.security.wrapperDir}/sudo ${getExe vtBack}";
        }
      ];
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
        name = "Steam";
        image-path = "steam.png";
        detached = [ (getExe startSteam) ];
        prep-cmd = [
          {
            do = getExe restoreDefaultSink;
            undo = "";
          }
          {
            do = getExe setResolution;
            undo = getExe stopSteam;
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

  # Let the Sunshine user service run only the two VT-switch helpers as root,
  # without a password, so the global prep-cmd can isolate niri's input during a
  # stream (see the VT-switch helpers above).
  security.sudo.extraRules = [
    {
      users = [ "unreal" ];
      commands = [
        {
          command = getExe vtAway;
          options = [ "NOPASSWD" ];
        }
        {
          command = getExe vtBack;
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Sunshine's PS5/DualSense (ds5) gamepad emulation creates its virtual pad
  # through /dev/uhid, which ships as root:root 0600 (no group, no ACL) — so the
  # unprivileged Sunshine user can't open it and ds5 is "disabled due to
  # Permission denied", falling back to (and also failing on) the Xbox pad. The
  # hardware.uinput module only grants /dev/uinput; uhid has no equivalent, so
  # grant it here. GROUP=uinput is session-independent (unlike a logind uaccess
  # ACL), so it survives the stream's VT-switch isolation. static_node retags
  # the node the uhid module creates at load even without a fresh uevent.
  services.udev.extraRules = ''
    KERNEL=="uhid", SUBSYSTEM=="misc", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uhid"
  '';

  # Input isolation note: we do NOT use the upstream udev approach (stripping
  # ID_INPUT from the 0xBEEF/0xDEAD devices). On this setup that hides them from
  # the headless Sway too — both Sway and niri run libinput on seat0, which
  # filters on ID_INPUT (confirmed via swaymsg get_inputs) — and seatd can't give
  # Sway a separate seat (it hardcodes "seat0"). Instead, the global_prep_cmd VT
  # switch (above) makes niri's session inactive for the duration of a stream so
  # logind pauses ITS input; Sway keeps direct (input-group) access. niri's own
  # device-ignore isn't merged upstream yet — revisit when it lands.
}
