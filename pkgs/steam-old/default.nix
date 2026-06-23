# A second, isolated Steam instance ("steam-old") whose entire state — config,
# login and game library — lives under /mnt/data2/SteamOld via a private HOME.
# The stock `steam` is left untouched. A wrapper can only relocate Steam storage
# through HOME (Steam has no library-path env var), so this is a fully separate
# instance rather than just an extra library folder on the existing account.
{
  writeShellScriptBin,
  bubblewrap,
  steam,
}:
writeShellScriptBin "steam-old" ''
  # Fully separate Steam whose storage lives in /mnt/data2/SteamOld.
  #
  # Two things have to be defeated:
  #  1. Steam resolves the home dir from the password database (getpwuid),
  #     NOT $HOME — so exporting HOME doesn't move it; it always picks
  #     /home/unreal. Instead we bind /mnt/data2/SteamOld over the real home
  #     *inside the sandbox*, so Steam's home physically is SteamOld (its
  #     config, login and games live there) while the real ~ and the main
  #     Steam install are shadowed (untouched).
  #  2. Steam's single-instance lock is a per-UID shared-memory object in
  #     /dev/shm (u<uid>-ValveIPCSharedObj-Steam). A private /dev/shm means
  #     this instance can't see the main one's lock, so it won't forward to
  #     it and can run alongside it.
  # Everything else (GPU, Wayland/PipeWire sockets in XDG_RUNTIME_DIR, …) is
  # bind-mounted from the host; the inner Steam FHS sandbox nests fine.
  mkdir -p /mnt/data2/SteamOld
  exec ${bubblewrap}/bin/bwrap \
    --dev-bind / / \
    --tmpfs /dev/shm \
    --bind /mnt/data2/SteamOld "$HOME" \
    ${steam}/bin/steam "$@"
''
