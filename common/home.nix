{
  lib,
  vars,
  ...
}:

{
  imports = [
    ./firefox.nix
    ./home-packages.nix
    ./scripts.nix
    # Active only from their install stage on (osConfig.nixbox.stage).
    ./apps.nix
    ./built.nix
  ];

  # Home Manager settings shared by the Mango and Plasma variants.

  home.username = vars.user;
  home.homeDirectory = "/home/${vars.user}";
  home.stateVersion = "26.05";

  fonts.fontconfig.enable = true;

  # The defaults are ~/Desktop, ~/Documents, ..., ~/Projects.
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  # --- shell ---
  home.sessionPath = [ "$HOME/.local/bin" ];
  home.sessionVariables = {
    EDITOR = "micro";
    CLAUDE_CODE_MAX_OUTPUT_TOKENS = "64000";
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      # rebuild: nh finds the flake via programs.nh.flake (~/nixos)
      rebuild = "nh os switch";
      update = "nh os switch --update";
      l = "eza -al --icons";
      ad = "asciidoctor -a source-highlighter=rouge ";
      battery = "acpi --battery --details";
      bigFiles = "du -ahx . | sort -h | nl";
      cmatrix = "cmatrix -bu 6";
      cpufreq = "watch grep \"cpu MHz\" /proc/cpuinfo";
      fingerprint = "sudo fprintd-enroll \"$(whoami)\"";
      gpg-check = "gpg --keyserver-options auto-key-retrieve --verify";
      gpg-retrieve = "gpg --keyserver-options auto-key-retrieve --receive-keys";
      grep = "grep --color=auto";
      gs = "git status";
      journalInfo = "journalctl -p 3 -xb";
      mnt = "udisksctl mount -b ";
      partuuid = "ls -l /dev/disk/by-partuuid";
      polkitStatus = "pgrep -af polkit";
      sf = "sudo systemctl --failed";
      sstart = "sudo systemctl start";
      sstat = "sudo systemctl status";
      userlist = "cut -d: -f1 /etc/passwd";
      wget = "wget -c";

      # Btrfs
      bbalance = "sudo btrfs balance start /";
      bbalanceStatus = "sudo btrfs balance status /";
      bdefrag = "sudo btrfs filesystem defragment -r /";
      bfree = "sudo btrfs filesystem usage /";
      bscrub = "sudo btrfs scrub start /";
      bscrubStatus = "sudo btrfs scrub status /";

      # Helpers
      create-ssh-key = "ssh-keygen -t ed25519";
    };
    initExtra = ''
      # Cursor shape
      printf '\e[34 q'

      # Optional tool directories (only added when they exist)
      for d in "$HOME/.android/bin" "$HOME/.lmstudio/bin"; do
        [ -d "$d" ] && PATH="$PATH:$d"
      done
      # Newest node-* under pi-node (glob order is alphabetical, the last one wins)
      for d in "$HOME"/.local/share/pi-node/node-*/bin; do
        [ -d "$d" ] && node_bin="$d"
      done
      [ -n "''${node_bin:-}" ] && PATH="$node_bin:$PATH"
      unset node_bin

      programPath() {
        readlink -e "$(which "$1")"
      }

      umount-drive() {
        local mnt="''${1:-$HOME/mount}"
        local map="''${2:-micleh}"
        mnt="''${mnt/#\~/$HOME}"
        if mountpoint -q "$mnt"; then
          sudo umount "$mnt"
          echo "Unmounted $mnt"
        else
          echo "Not mounted: $mnt"
        fi
        if [ -e "/dev/mapper/$map" ]; then
          sudo cryptsetup close "$map"
          echo "Closed /dev/mapper/$map"
        else
          echo "Mapper not open: $map"
        fi
      }

      # Archive extractor
      ex() {
        if [ -f "$1" ]; then
          case "$1" in
            *.tar.bz2|*.tbz2) tar xjf "$1" ;;
            *.tar.gz|*.tgz) tar xzf "$1" ;;
            *.tar.xz|*.tar) tar xf "$1" ;;
            *.tar.zst) unzstd "$1" ;;
            *.bz2) bunzip2 "$1" ;;
            *.rar) unrar x "$1" ;;
            *.gz) gunzip "$1" ;;
            *.zip) unzip "$1" ;;
            *.Z) uncompress "$1" ;;
            *.7z) 7z x "$1" ;;
            *.deb) ar x "$1" ;;
            *) echo "'$1' cannot be extracted via ex()" ;;
          esac
        else
          echo "'$1' is not a valid file"
        fi
      }
    '';
  };

  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ../dotfiles/config/.config/starship.toml);
  };
  programs.zoxide.enable = true;
  programs.eza = {
    enable = true;
    icons = "auto";
  };

  programs.git = {
    enable = true;
    ignores = [
      "*.backup*"
      "*.swp"
      "*.swo"
      "*~"
      ".DS_Store"
    ];
    settings = {
      user = {
        name = "MicLeh";
        email = "micleh@proton.me";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
  # GitHub login via `gh auth login`; also installs the git credential helper.
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.foot = {
    enable = true;
    settings = {
      main.font = "JetBrains Mono NL:size=13";
      main.include = "~/.config/foot/themes/noctalia";
      scrollback.lines = 10000;
    };
  };

  # --- files ---
  xdg.configFile = {
    "kitty/kitty.conf".source = ../dotfiles/kitty/.config/kitty/kitty.conf;
    "kitty/dank-tabs.conf".source = ../dotfiles/kitty/.config/kitty/dank-tabs.conf;
    "kitty/dank-theme.conf".source = ../dotfiles/kitty/.config/kitty/dank-theme.conf;
    "doublecmd/doublecmd.xml".source = ../dotfiles/doublecmd/.config/doublecmd/doublecmd.xml;
    "mc/ini".source = ../dotfiles/mc/.config/mc/ini;
    "mc/panels.ini".source = ../dotfiles/mc/.config/mc/panels.ini;
    "user-dirs.locale".source = ../dotfiles/config/.config/user-dirs.locale;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/x-github-client" = [ "github-desktop.desktop" ];
      "x-scheme-handler/x-github-desktop-auth" = [ "github-desktop.desktop" ];
      "x-scheme-handler/x-github-desktop-dev-auth" = [ "github-desktop.desktop" ];

      # LibreOffice Writer documents (desktop file name from nixpkgs is writer.desktop)
      "application/msword" = [ "writer.desktop" ];
      "application/vnd.ms-word.document.macroEnabled.12" = [ "writer.desktop" ];
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [ "writer.desktop" ];
      "application/vnd.openxmlformats-officedocument.wordprocessingml.template" = [ "writer.desktop" ];
      "application/vnd.oasis.opendocument.text" = [ "writer.desktop" ];
      "application/vnd.oasis.opendocument.text-template" = [ "writer.desktop" ];
      "application/rtf" = [ "writer.desktop" ];

      # LibreOffice Impress presentations (desktop file name from nixpkgs is impress.desktop)
      "application/vnd.ms-powerpoint" = [ "impress.desktop" ];
      "application/vnd.ms-powerpoint.presentation.macroEnabled.12" = [ "impress.desktop" ];
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [ "impress.desktop" ];
      "application/vnd.openxmlformats-officedocument.presentationml.slideshow" = [ "impress.desktop" ];
      "application/vnd.openxmlformats-officedocument.presentationml.template" = [ "impress.desktop" ];
      "application/vnd.oasis.opendocument.presentation" = [ "impress.desktop" ];
      "application/vnd.oasis.opendocument.presentation-template" = [ "impress.desktop" ];
    };
  };

  # Overwrite LibreOffice's mutable profile on every activation with the managed baseline.
  home.activation.libreofficeProfile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    profile="$HOME/.config/libreoffice/4/user"
    source=${../dotfiles/libreoffice/.config/libreoffice/4/user}
    run install -D -m 0644 "$source/registrymodifications.xcu" "$profile/registrymodifications.xcu"
    run install -D -m 0644 \
      "$source/config/soffice.cfg/modules/swriter/toolbar/singlemode.xml" \
      "$profile/config/soffice.cfg/modules/swriter/toolbar/singlemode.xml"
    run install -D -m 0644 \
      "$source/config/soffice.cfg/modules/swriter/toolbar/singlemode-text.xml" \
      "$profile/config/soffice.cfg/modules/swriter/toolbar/singlemode-text.xml"
  '';
}
