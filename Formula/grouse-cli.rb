class GrouseCli < Formula
  desc "Interact with grouse.site from your command-line"
  homepage "https://github.com/dNitza/grouse-cli"
  url "https://github.com/dnitza/grouse-cli/archive/refs/tags/v0.0.2.tar.gz"
  sha256 "25a0eee1e07f7110cf76842fab093069ae1f4a898fef292bd57b19551ea4db39"
  license "MIT"
  head "https://github.com/dnitza/grouse-cli.git", branch: "main"

  depends_on "ruby@3"

  def install
    # Ensure Bundler uses brewed Ruby during build
    ENV.prepend_path "PATH", Formula["ruby@3"].opt_bin

    # Keep project tree intact so require_relative works
    libexec.install Dir["*"]

    # Ensure the repo-provided executable exists and is executable
    app_exec = libexec/"bin/grouse-cli"
    app_exec.chmod 0755 if app_exec.exist?

    ENV["BUNDLE_PATH"] = (libexec/"vendor/bundle").to_s
    ENV["BUNDLE_WITHOUT"] = "development:test"
    ENV["BUNDLE_BIN"] = (libexec/"bin").to_s

    cd libexec do
      system "bundle", "config", "set", "path", ENV["BUNDLE_PATH"]
      system "bundle", "config", "set", "without", ENV["BUNDLE_WITHOUT"]
      system "bundle", "config", "set", "bin", ENV["BUNDLE_BIN"]
      system "bundle", "install"

      # Remove build-time artifacts that may embed Homebrew shims paths (audit-clean)
      rm Dir[libexec/"vendor/bundle/**/ext/**/{mkmf.log,config.log}"]
      rm_r Dir[libexec/"vendor/bundle/**/ext/**/tmp"]
      rm_r Dir[libexec/"vendor/bundle/**/cache"]
    end

    # Create a wrapper that uses `bundle exec` so bundler sets up the load path correctly
    (bin/"grouse-cli").write <<~EOS
      #!/bin/bash
      export BUNDLE_GEMFILE="#{libexec}/Gemfile"
      export BUNDLE_PATH="#{libexec}/vendor/bundle"
      export PATH="#{Formula["ruby@3"].opt_bin}:$PATH"
      exec "#{Formula["ruby@3"].opt_bin}/bundle" exec "#{libexec}/bin/grouse-cli" "$@"
    EOS
    (bin/"grouse-cli").chmod 0755
  end

  test do
    output = shell_output("#{bin}/#{name} --help")
    assert_match "grouse-cli", output
    assert_match "auth", output
  end
end
