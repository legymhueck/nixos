{ vars, ... }:

let
  home = "/home/${vars.user}";
  conf = "${home}/.config/restic";
  repoFile = "${conf}/unterricht-repo";
  passwordFile = "${conf}/unterricht-passwort";
  # Current target: a USB disk with the ext4 label "restic-backup", kept
  # outside the house and attached now and then (udisks mounts it here).
  # For a network target (e.g. Storage Box) drop this condition.
  diskRepo = "/run/media/${vars.user}/restic-backup/restic/unterricht";
in
{
  # Encrypted, versioned backup of the teaching repository including its
  # git-ignored archive (_altbestand, fremdmaterial, Abitur archives) to an
  # off-site restic repository. Personal data is not in that folder (it stays
  # on the VeraCrypt SSD) and must not be added here.
  #
  # One-time setup (see docs/tips/commands.md):
  #   ~/.config/restic/unterricht-repo      repository, e.g. sftp:storagebox:/restic/unterricht
  #   ~/.config/restic/unterricht-passwort  repository password (chmod 600, also keep it in KeePassXC)
  #   restic-unterricht init
  # Until both files exist and the disk is attached, the daily timer starts
  # nothing (conditions below); with the disk attached it runs once a day, or
  # at once with: sudo systemctl start restic-backups-unterricht
  services.restic.backups.unterricht = {
    inherit (vars) user;
    repositoryFile = repoFile;
    inherit passwordFile;
    paths = [ "${home}/Documents/GitHub/micleh/unterricht" ];
    exclude = [
      "**/.spiegel-papierkorb"
      "**/.venv"
      "**/__pycache__"
      "**/node_modules"
      "**/out"
      "**/result"
      "*.class"
    ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-monthly 12"
      "--keep-yearly 3"
    ];
    # Command restic-unterricht: restic with repository and password preset.
    createWrapper = true;
  };

  # The restic-unterricht wrapper uses the service's cache directory; create
  # it at boot so the wrapper works before the timer has run once.
  systemd.tmpfiles.rules = [ "d /var/cache/restic-backups-unterricht 0700 ${vars.user} users -" ];

  systemd.services."restic-backups-unterricht".unitConfig = {
    ConditionPathExists = [
      repoFile
      passwordFile
    ];
    ConditionPathIsDirectory = diskRepo;
  };
}
