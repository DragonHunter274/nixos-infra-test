{ config, pkgs, ... }:

{

  users.users.server = {
    isNormalUser = true;
    description = "server";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      k9s
      neovim
    ];
  };

  users.users.simon = {
    isNormalUser = true;
    description = "simon";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "podman"
    ];
    packages = with pkgs; [
      k9s
      neovim
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICiyUMQ0cq4JoU1aDRq4QwSMxva3+pdayZ2pSi1PG8Gl 38c3-server-simon"
    ];
  };

  users.users.lukas = {
    isNormalUser = true;
    description = "lukas";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      k9s
      neovim
    ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDj92Ck48RvshHAScQ1aPiZh8c304r8jAW97VA2j8HagbpH+i7YGe9iTqMbNLlzlm5AgBKcaQeIOinFXpjn8ZaXndCzSNexE45PGly2GctRGPKtDHsCcjtEqQaUzqpkNkVelfIzxzBYLOGAQbOty7Ca8lmHSUlWlZciv0p5sHWU2OcEYPp4AmABZaEJrUdECEd8T84Qyxpo102zhhi0ZfNkGLXPtf0zbkiGRVgGDJEzBRZytjf73QIN5722q1UwBP8cAYhPJIoXV7mqIl30OEp/YfY41FNRce+H6VnZG0AbpOCmV1FBVtohUxbsWuI78OTKYlAg1jwSBlFZAJzDbni95Qk73XUtjV5LRXRVm30P5NHuvVQyTkb8n4KU5zHHjoaWyBK/pEpkcAoXlD4hsZw5gCRNaWMjtLaxyeXufGWLmKrWOO+mw1FClUqi34pAAuRE/KwpUsaLAm7ZWVjHMYZJ/PSFIwaQuUdYRYTNK5S7HyNu8aGVde5qsbxuuKlU8u0="
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5xNAN8EIB7ZxUbSIWFq+I+5FNroI/fO6uI/jCheFaa2VvzIT7wQk09zFZTHN7cvgIs/hqBJSdvizoMqo6KtlytdnID3CWJznSS+6MbG1q+/uFEUqQlJGM6L+c34Y4X/wf3qXQeiflj9VMk9ZyiMfgcTcNDN9sWhqYg1G2Rq9Wrtd4pbPfmDV9DgW1dI10FHbWaqCd+DPGTlDV4lq9EHZLBocV3pN8eoct0rcTCh1G0ARi3UWya30RBw5kNfyCGc6Xplut4768jHOMqBIzQqvFcDWlzWhBAkXVukTwbZVm+R+1nNexs0K7sd1kWdT+yOooIv93VYTrWKFJK37pbg8OX/wE6QgeubX75Kys0xMi2ivr2GQi0k8vzLEGlYM9ktIGLFF9wsLiyIozq/lpZ+At1BSEPguDD4mylNrJyTSvMNpARWH6HfDjE4fmrtFOQHl5KXbzRQziKj2+BMDkXgI8Q52G5XzBpzZhukpsk5G53wamllhJM9CV5qoMgbkrHE6N+dEAQ2MrhLt2DILwvQsaYONBnZhYK9ZP9pt+9H/SV9766ZRnwQDTc27AN6jz+5auCaEpvmAjxdARugJQWA55+6N1kLf1ATzNQEkT/3iL44yRTiosoYjLpACvUEmyKFEJYLMFkdMMYpSp1uJ6B3RJ4qQv0ZY3RBZCpEpCRW+3qw=="
    ];
  };

  users.users.huber1 = {
    isNormalUser = true;
    description = "Moritz Huber";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "users"
    ];
    packages = with pkgs; [
      k9s
      neovim
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUUz0Z9HISfITuG7cUnN3PMvxUbvRMHfFwvy8HvwDG8"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIER5dTWkG/HH2JuWtyQGl892dLBqIvblDnWUIwI9Os1D"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK4ErQoDPxZNst5f7Qc2jtRPOzprs+WKObjg1jevcjnW"
    ];
  };
  users.users.adrian = {
    isNormalUser = true;
    description = "Adrian";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      k9s
      neovim
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBGJlmdhEw08YDrg8zVzIfXfeuKqB0FCtAfnW0TFT18r"
    ];
  };
  users.users.obedaya = {
    isNormalUser = true;
    description = "Simon Holzner";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      k9s
      neovim
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHk9HLSPaM3IZrJE2OsLLEjjtsd78EAG9aB6i14Ihd1g"
    ];
  };

}
