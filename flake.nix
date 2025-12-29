{
  description = "Elixir Phoenix development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Erlang/OTP and Elixir versions
        erlang = pkgs.beam.packages.erlang_26.erlang;
        elixir = pkgs.beam.packages.erlang_26.elixir;
        
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Core
            erlang
            elixir
            
            # Phoenix deps
            nodejs_22
            nodePackages.pnpm
            
            # Database
            postgresql_16
            
            # Tools
            git
            gcc
            gnumake
            
          ] ++ lib.optionals stdenv.isDarwin [
            fswatch
          ] ++ lib.optionals stdenv.isLinux [
            inotify-tools
          ];
          
          shellHook = ''
            export MIX_HOME="$PWD/.nix-mix"
            export HEX_HOME="$PWD/.nix-hex"
            export PATH="$MIX_HOME/bin:$HEX_HOME/bin:$PATH"
            
            mix local.hex --force --if-missing >/dev/null 2>&1 || true
            mix local.rebar --force --if-missing >/dev/null 2>&1 || true
            
            echo ""
            echo "🚀 Phoenix & React dev environment ready"
            echo "   Elixir: $(elixir --short-version)"
            echo "   Node: $(node --version)"
            echo "   pnpm: $(pnpm --version)"
            echo ""
            echo "Backend:"
            echo "  cd backend && mix deps.get && mix phx.server"
            echo ""
            echo "Frontend:"
            echo "  cd frontend && pnpm install && pnpm dev"
          '';
        };
      });
}