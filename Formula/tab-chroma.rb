class TabChroma < Formula
  desc "iTerm2 visual feedback plugin for Claude Code"
  homepage "https://github.com/JCPetrelli/TabChroma"
  url "https://github.com/JCPetrelli/TabChroma/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "8490b4dcc8122ae7dfde29ca30abb3a93e91445f770d0ad1925cf386ad5f830f"
  license "MIT"
  version "1.0.0"

  def install
    # Install script and themes to share dir
    (share/"tab-chroma").install "tab-chroma.sh", "themes", "completions", "VERSION"
    chmod 0755, share/"tab-chroma"/"tab-chroma.sh"

    # Shell completions (reference from share since completions dir was moved above)
    bash_completion.install share/"tab-chroma"/"completions"/"tab-chroma.bash" => "tab-chroma"
    fish_completion.install share/"tab-chroma"/"completions"/"tab-chroma.fish"

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
