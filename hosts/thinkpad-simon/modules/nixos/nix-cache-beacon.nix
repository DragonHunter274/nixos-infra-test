#{ ... }:
{
  services.nix-cache-beacon = {
    # Discover & use other nix-cache-beacon caches on the local network
    cache.enable = true;
  };
  nix.settings.substituters = [ "http://localhost:5028" ];
}
