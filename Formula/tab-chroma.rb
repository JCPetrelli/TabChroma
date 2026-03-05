class TabChroma < Formula
  desc "iTerm2 visual feedback plugin for Claude Code"
  homepage "https://github.com/JCPetrelli/tab_chroma"
  url "https://github.com/JCPetrelli/tab_chroma/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "d5558cd419c8d46bdc958064cb97f963d1ea793866414c025906ec15033512ed"
  license "MIT"
  version "1.0.0"

  # No compilation needed — pure bash + Python 3 (macOS stdlib)
  bottle :unneeded

  def install
    # Install script and themes to share dir
    (share/"tab-chroma").install "tab-chroma.sh", "themes", "completions", "VERSION"
    chmod 0755, share/"tab-chroma"/"tab-chroma.sh"

    # Shell completions
    bash_completion.install "completions/tab-chroma.bash" => "tab-chroma"
    fish_completion.install "completions/tab-chroma.fish"

    # Wrapper script in bin/ — sets SHARE_DIR, DATA_DIR, and HOOK_CMD
    (bin/"tab-chroma").write <<~EOS
      #!/bin/bash
      export TAB_CHROMA_SHARE="#{share}/tab-chroma"
      export TAB_CHROMA_DATA="$HOME/.claude/hooks/tab-chroma"
      export TAB_CHROMA_HOOK_CMD="#{bin}/tab-chroma"
      exec "#{share}/tab-chroma/tab-chroma.sh" "$@"
    EOS
  end

  def caveats
    <<~EOS
      To register Claude Code hooks, run:
        tab-chroma install

      This adds tab-chroma to ~/.claude/settings.json so it activates
      automatically during Claude Code sessions.

      To uninstall hooks later:
        tab-chroma uninstall
    EOS
  end

  test do
    assert_match "tab-chroma v", shell_output("#{bin}/tab-chroma version")
  end
end
