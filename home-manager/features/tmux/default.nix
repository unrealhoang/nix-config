{ pkgs, ... }: {
  programs.tmux = {
    catppuccin.enable = true;
    enable = true;
    plugins = with pkgs; [
      tmuxPlugins.resurrect
      tmuxPlugins.yank
      tmuxPlugins.better-mouse-mode
      # {
      #   plugin = tmuxPlugins.catppuccin.overrideAttrs (prevAttrs: {
      #     src = pkgs.fetchFromGitHub {
      #       owner = "catppuccin";
      #       repo = "tmux";
      #       rev = "6ae90fe3fd7881f87dedd35615d70f9f29a238ae";
      #       hash = "sha256-Mp2MxJ/WpCFPCucQxYxYMe7b/yXfPVhj+MSM2XLJ92o=";
      #     };
      #   });
      #   extraConfig = ''
      #     ###########################
      #     # Theme
      #     ###########################
      #     set -g @catppuccin_window_right_separator "█ "
      #     set -g @catppuccin_window_number_position "right"
      #     set -g @catppuccin_window_middle_separator " | "

      #     set -g @catppuccin_window_default_fill "none"
      #     set -g @catppuccin_window_default_text "#W"
      #     set -g @catppuccin_window_current_fill "all"
      #     set -g @catppuccin_window_current_text "#W"

      #     set -g @catppuccin_status_modules_right "directory session date_time"
      #     set -g @catppuccin_status_left_separator "█"
      #     set -g @catppuccin_status_right_separator "█"

      #     set -g @catppuccin_date_time_text "%Y-%m-%d %H:%M"
      #   '';
      # }
    ];
    extraConfig = ''
      # use 256 term for pretty colors
      set-option -g default-terminal "xterm-256color"
      set-option -sa terminal-overrides ",xterm-256color:Tc"
      set-option -g focus-events on

      # increase scroll-back history
      set -g history-limit 10000

      # use vim key bindings
      setw -g mode-keys vi
      set-option -g mouse on

      # decrease command delay (increases vim responsiveness)
      set -sg escape-time 1

      # increase repeat time for repeatable commands
      set -g repeat-time 1000

      # start window index at 1
      set -g base-index 1

      # start pane index at 1
      setw -g pane-base-index 1

      # highlight window when it has new activity
      setw -g monitor-activity on
      set -g visual-activity on

      ###########################
      #  Key Bindings
      ###########################

      # tmux prefix
      unbind C-b
      set -g prefix C-j
      bind-key j send-prefix

      # copy with 'enter' or 'y' and send to mac os clipboard: http://goo.gl/2Bfn8

      # create 'v' alias for selecting text
      bind-key -Tcopy-mode-vi 'v' send -X begin-selection
      bind-key -Tcopy-mode-vi 'y' send -X copy-selection
      #bind-key -Tcopy-mode-vi 'y' send -X copy-pipe-and-cancel "reattach-to-user-namespace pbcopy"
      bind-key -Tcopy-mode-vi Escape send -X cancel
      bind-key -Tcopy-mode-vi V send -X rectangle-toggle

      # paste
      unbind C-p
      bind C-p paste-buffer

      # windows back
      unbind C-p
      unbind C-b
      bind Tab previous-window

      # window splitting
      unbind %
      bind | split-window -h
      unbind '"'
      bind - split-window -v

      # resize panes
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # create 25% lower split
      unbind t
      bind t split-window -p 25

      # quickly switch panes
      unbind ^J
      bind ^J select-pane -t :.+

      # force a reload of the config file
      unbind r
      bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"

      # clear screen
      bind -n C-k send-keys -R \;
    '';
  };
}
