{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.templates.services.k3s;

  # Create a wrapper script for iptables that CNI plugins can execute
  iptablesWrapper = pkgs.writeScriptBin "iptables" ''
    #!${pkgs.runtimeShell}
    exec ${pkgs.iptables}/bin/iptables "$@"
  '';

  iptablesSaveWrapper = pkgs.writeScriptBin "iptables-save" ''
    #!${pkgs.runtimeShell}
    exec ${pkgs.iptables}/bin/iptables-save "$@"
  '';

  iptablesRestoreWrapper = pkgs.writeScriptBin "iptables-restore" ''
    #!${pkgs.runtimeShell}
    exec ${pkgs.iptables}/bin/iptables-restore "$@"
  '';

  # Build a composite environment with CNI plugins and iptables wrappers
  cniWithIptables = pkgs.buildEnv {
    name = "cni-with-iptables";
    paths = [
      iptablesWrapper
      iptablesSaveWrapper
      iptablesRestoreWrapper
    ];
  };
in
{
  options.templates.services.k3s = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable K3S Cluster Node.";
    };

    serverAddr = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Address of an existing server to join (e.g., https://10.0.0.1:6443).
        When empty, this node initializes a new cluster with --cluster-init.
      '';
    };

    tokenFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to file containing the K3s cluster token.
        Required for nodes joining an existing cluster.
      '';
    };

    delay = lib.mkOption {
      type = lib.types.int;
      default = 60;
      description = "K3S Service Start Delay";
    };

    bootstrap = {
      helm = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Helm bootsrap service for K3S Cluster.";
        };
        completedIf = lib.mkOption {
          type = lib.types.str;
          description = ''
            kubectl command condition meet when bootstrap is completed
          '';
        };
        helmfile = lib.mkOption {
          type = lib.types.str;
          description = ''
            Path to bootstrap helmfile
          '';
        };
      };
    };

    prepare = {
      cilium = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Set required preconditions to install cilium to k3s cluster
        '';
      };
    };

    secretsEncryption = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable secrets encryption for the k3s cluster.
        Disable when joining a cluster that was set up without secrets-encryption.
      '';
    };

    services = {
      coredns = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          If enabled coredns will be installed to k3s cluster
        '';
      };

      kube-proxy = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          If enabled k3s kube-proxy will be enabled on k3s cluster
        '';
      };

      flannel = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          If enabled flannel will be enabled on k3s cluster
        '';
      };

      flux = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable flux service for K3S Cluster.";
        };

        url = lib.mkOption {
          type = lib.types.str;
          description = ''
            Git repository URL for Flux (e.g., https://github.com/user/repo)
          '';
        };

        branch = lib.mkOption {
          type = lib.types.str;
          default = "main";
          description = ''
            Git branch to track (e.g., dev, staging, main)
          '';
        };

        path = lib.mkOption {
          type = lib.types.str;
          description = ''
            Path within the repository to the Flux configuration 
            (e.g., ./environments/dev)
          '';
        };

        sopsAgeKeyFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = ''
            Path to SOPS age key file. If null, will try ~/.config/sops/age/keys.txt
          '';
        };
      };

      servicelb = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          If enabled klipper-lb will be enabled on k3s cluster
        '';
      };

      traefik = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          If enabled traefik will be enabled on k3s cluster
        '';
      };

      local-storage = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          If enabled local-storage will be enabled on k3s cluster
        '';
      };

      metrics-server = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          If enabled metrics-server will be enabled on k3s cluster
        '';
      };

    };

    addons = {
      nfs = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            If enabled a localhost only nfs-server will be enabled on node
          '';
        };
        path = lib.mkOption {
          type = lib.types.str;
          default = "/mnt/nfs";
          description = ''
            Host path for nfs server share
          '';
        };
      };

      minio = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            If enabled minio will be enabled on node
          '';
        };
        credentialsFile = lib.mkOption {
          type = lib.types.path;
          description = ''
            File containing the MINIO_ROOT_USER, default is "minioadmin", and
            MINIO_ROOT_PASSWORD (length >= 8), default is "minioadmin"; in the format of
            an EnvironmentFile=, as described by systemd.exec(5). The acess permission must
            be set to 770 for minio:minio.
          '';
        };
        region = lib.mkOption {
          type = lib.types.str;
          default = "local";
          description = ''
            The physical location of the server.
          '';
        };
        buckets = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "volsync"
            "postgres"
          ];
          description = ''
            Bucket name.
          '';
        };
        dataDir = lib.mkOption {
          default = [ "/var/lib/minio/data" ];
          type = lib.types.listOf (lib.types.either lib.types.path lib.types.str);
          description = "The list of data directories or nodes for storing the objects.";
        };
      };
    };
  };

  config =
    let
      k3sAdmissionPlugins = [
        "DefaultStorageClass"
        "DefaultTolerationSeconds"
        "LimitRanger"
        "MutatingAdmissionWebhook"
        "NamespaceLifecycle"
        "NodeRestriction"
        "PersistentVolumeClaimResize"
        "Priority"
        "ResourceQuota"
        "ServiceAccount"
        "TaintNodesByCondition"
        "ValidatingAdmissionWebhook"
      ];
      k3sDisabledServices =
        [ ]
        ++ lib.optionals (cfg.services.flannel == false) [ "flannel" ]
        ++ lib.optionals (cfg.services.servicelb == false) [ "servicelb" ]
        ++ lib.optionals (cfg.services.coredns == false) [ "coredns" ]
        ++ lib.optionals (cfg.services.local-storage == false) [ "local-storage" ]
        ++ lib.optionals (cfg.services.metrics-server == false) [ "metrics-server" ]
        ++ lib.optionals (cfg.services.traefik == false) [ "traefik" ];
      k3sExtraFlags = [
        "--kubelet-arg=config=/etc/rancher/k3s/kubelet.config"
        "--node-label \"k3s-upgrade=false\""
        "--kube-apiserver-arg anonymous-auth=true"
        "--kube-controller-manager-arg bind-address=0.0.0.0"
        "--kube-scheduler-arg bind-address=0.0.0.0"
        "--etcd-expose-metrics"
        "--write-kubeconfig-mode 0644"
        "--kube-apiserver-arg='enable-admission-plugins=${lib.concatStringsSep "," k3sAdmissionPlugins}'"
      ]
      ++ lib.lists.optionals (cfg.services.flannel == false) [
        "--flannel-backend=none"
        "--disable-network-policy"
      ]
      ++ lib.optionals (cfg.services.kube-proxy == false) [
        "--disable-cloud-controller"
        "--disable-kube-proxy"
      ]
      ++ lib.optionals cfg.prepare.cilium [
        "--kubelet-arg=register-with-taints=node.cilium.io/agent-not-ready:NoExecute"
      ]
      ++ lib.optionals cfg.secretsEncryption [
        "--secrets-encryption"
      ];
      k3sDisableFlags = builtins.map (service: "--disable ${service}") k3sDisabledServices;
      k3sCombinedFlags = lib.concatLists [
        k3sDisableFlags
        k3sExtraFlags
      ];
    in
    lib.mkIf cfg.enable {

      environment = {
        systemPackages = lib.mkMerge [
          [
            pkgs.runc
            pkgs.age
            pkgs.cilium-cli
            pkgs.fluxcd
            pkgs.kubernetes-helm
            pkgs.helmfile
            pkgs.git
            pkgs.go-task
            pkgs.minio-client
            pkgs.jq
            pkgs.k9s
            pkgs.krelay
            pkgs.kubectl
            pkgs.nfs-utils
            pkgs.openiscsi
            pkgs.openssl_3
            pkgs.sops

            (pkgs.writeShellScriptBin "nuke-k3s" ''
              if [ "$EUID" -ne 0 ] ; then
                echo "Please run as root"
                exit 1
              fi
              read -r -p 'Nuke k3s?, confirm with yes (y/N): ' choice
              case "$choice" in
                y|Y|yes|Yes) echo "nuke k3s...";;
                *) exit 0;;
              esac
              systemctl stop k3s-helm-bootstrap.timer || true
              systemctl stop k3s-helm-bootstrap.service || true
              systemctl stop k3s-flux2-bootstrap.timer || true
              systemctl stop k3s-flux2-bootstrap.service || true
              flux uninstall -s || true
              kubectl delete deployments --all=true -A
              kubectl delete statefulsets --all=true -A  
              kubectl delete ns --all=true -A    
              kubectl get ns | tail -n +2 | cut -d ' ' -f 1 | xargs -I{} kubectl delete pods --all=true --force=true -n {}
              cilium uninstall || true
              echo "wait until objects are deleted..."
              sleep 28
              systemctl stop k3s
              sleep 2
              rm -rf /var/lib/rancher/k3s/
              rm -rf /var/lib/cni/networks/cbr0/
              if [ -d /opt/k3s/data/temp ]; then
                rm -rf /opt/k3s/data/temp/*
              fi
              sync
              echo -e "\n => reboot now to complete k3s cleanup!"
              sleep 3
              reboot
            '')
          ]
        ];

        etc = {
          "rancher/k3s/kubelet.config" = {
            mode = "0750";
            text = ''
              apiVersion: kubelet.config.k8s.io/v1beta1
              kind: KubeletConfiguration
              maxPods: 250
            '';
          };
          "rancher/k3s/k3s.service.env" = {
            mode = "0750";
            text = ''
              K3S_KUBECONFIG_MODE="644"
            '';
          };
        };
      };

      systemd.tmpfiles.rules = lib.mkMerge [
        [
          "d /root/.kube 0755 root root -"
          "L /root/.kube/config  - - - - /etc/rancher/k3s/k3s.yaml"
          # Symlink iptables wrappers into K3s CNI bin directory for CNI plugins
          "L+ /var/lib/rancher/k3s/data/current/bin/iptables - - - - ${cniWithIptables}/bin/iptables"
          "L+ /var/lib/rancher/k3s/data/current/bin/iptables-save - - - - ${cniWithIptables}/bin/iptables-save"
          "L+ /var/lib/rancher/k3s/data/current/bin/iptables-restore - - - - ${cniWithIptables}/bin/iptables-restore"
          # Longhorn requires mount and iscsiadm at standard FHS paths when using nsenter into host namespace
          "L /usr/bin/mount - - - - /run/current-system/sw/bin/mount"
          "L /usr/sbin/iscsiadm - - - - /run/current-system/sw/bin/iscsiadm"
        ]
        (lib.mkIf cfg.addons.nfs.enable [
          "d ${cfg.addons.nfs.path} 0775 root root -"
          "d ${cfg.addons.nfs.path}/pv 0775 root root -"
        ])
      ];

      boot.kernel.sysctl = {
        "fs.inotify.max_user_instances" = 524288;
        "fs.inotify.max_user_watches" = 524288;
      };

      networking.firewall = {
        allowedTCPPorts = lib.mkMerge [
          [
            80 # http
            222 # git ssh
            443 # https
            445 # samba
            6443 # kubernetes api
            8080 # reserved http
            10250 # k3s metrics
          ]
          (lib.mkIf cfg.addons.nfs.enable [ 2049 ])
          (lib.mkIf cfg.addons.minio.enable [
            9000
            9001
          ])
          (lib.mkIf cfg.prepare.cilium [
            4240 # health check
            4244 # hubble server
            4245 # hubble relay
            9962 # agent prometheus metrics
            9963 # operator prometheus metrics
            9964 # envoy prometheus metrics
          ])
        ];
        allowedUDPPorts = lib.mkMerge [
          [
            8472 # VXLAN overlay (flannel/cilium inter-node)
          ]
        ];
        allowedTCPPortRanges = [
          {
            from = 2379;
            to = 2380;
          } # etcd
        ];
      };

      services = {
        prometheus.exporters.node = {
          enable = false;
        };
        nfs.server = lib.mkIf cfg.addons.nfs.enable {
          enable = true;
          exports = ''
            ${cfg.addons.nfs.path} ${config.networking.hostName}(rw,fsid=0,async,no_subtree_check,no_auth_nlm,insecure,no_root_squash)
          '';
        };
        minio = lib.mkIf cfg.addons.minio.enable {
          enable = true;
          region = cfg.addons.minio.region;
          dataDir = cfg.addons.minio.dataDir;
          rootCredentialsFile = cfg.addons.minio.credentialsFile;
        };
        k3s = {
          enable = true;
          role = "server";
          clusterInit = (cfg.serverAddr == "");
          serverAddr = cfg.serverAddr;
          tokenFile = lib.mkIf (cfg.tokenFile != null) cfg.tokenFile;
          environmentFile = "/etc/rancher/k3s/k3s.service.env";
          extraFlags = lib.concatStringsSep " " k3sCombinedFlags;
        };
        openiscsi = {
          enable = true;
          name = "${config.networking.hostName}-initiatorhost";
        };
      };

      systemd = {
        services = {
          k3s-delay = {
            description = "Delay start of k3s";
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${pkgs.coreutils}/bin/true";
            };
          };
          k3s = {
            after = lib.mkMerge [
              [ "k3s.delay.service" ]
              (lib.mkIf cfg.addons.minio.enable [ "minio.service" ])
              (lib.mkIf cfg.addons.nfs.enable [ "nfs-server.service" ])
            ];
            path = with pkgs; [
  iptables
  iproute2
  utillinux
  coreutils
];
            serviceConfig = {
              TimeoutStartSec = lib.mkForce (120 + cfg.delay);
            };
          };
          iscsid.serviceConfig = {
            PrivateMounts = "yes";
            BindPaths = "/run/current-system/sw/bin:/bin";
          };
          minio-init = lib.mkIf cfg.addons.minio.enable {
            enable = true;
            path = [
              pkgs.minio
              pkgs.minio-client
            ];
            requiredBy = [ "multi-user.target" ];
            after = [ "minio.service" ];
            serviceConfig = {
              Type = "simple";
              User = "minio";
              Group = "minio";
              RuntimeDirectory = "minio-config";
            };
            script = ''
              set -e
              sleep 5
              source ${cfg.addons.minio.credentialsFile}
              mc --config-dir "$RUNTIME_DIRECTORY" alias set minio http://localhost:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"
              ${toString (
                lib.lists.forEach cfg.addons.minio.buckets (
                  bucket: "mc --config-dir $RUNTIME_DIRECTORY mb --ignore-existing minio/${bucket};"
                )
              )}
            '';
          };
        };
        timers.k3s-delay = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "${toString cfg.delay}s";
            Unit = "k3s-delay.service";
          };
        };
        timers."k3s-helm-bootstrap" = lib.mkIf (cfg.bootstrap.helm.enable && cfg.serverAddr == "") {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "3m";
            OnUnitActiveSec = "3m";
            Unit = "k3s-helm-bootstrap.service";
          };
        };
        timers."k3s-flux2-bootstrap" = lib.mkIf (cfg.services.flux.enable && cfg.serverAddr == "") {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "3m";
            OnUnitActiveSec = "3m";
            Unit = "k3s-flux2-bootstrap.service";
          };
        };
      };

      systemd.services."k3s-helm-bootstrap" = lib.mkIf (cfg.bootstrap.helm.enable && cfg.serverAddr == "") {
        script = ''
          export PATH="$PATH:${pkgs.git}/bin:${pkgs.kubernetes-helm}/bin"
          if ${pkgs.kubectl}/bin/kubectl ${cfg.bootstrap.helm.completedIf} ; then
            exit 0
          fi
          sleep 30
          if ${pkgs.kubectl}/bin/kubectl ${cfg.bootstrap.helm.completedIf} ; then
            exit 0
          fi
          ${pkgs.helmfile}/bin/helmfile --quiet --file ${cfg.bootstrap.helm.helmfile} apply --skip-diff-on-install --suppress-diff
        '';
        after = [ "k3s.service" ];
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          RestartSec = "3m";
        };
      };

      systemd.services."k3s-flux2-bootstrap" = lib.mkIf (cfg.services.flux.enable && cfg.serverAddr == "") {
        script =
          let
            ageKeyPath =
              if cfg.services.flux.sopsAgeKeyFile != null then
                toString cfg.services.flux.sopsAgeKeyFile
              else
                "/root/.config/sops/age/keys.txt";
          in
          ''
            export PATH="$PATH:${pkgs.git}/bin:${pkgs.fluxcd}/bin:${pkgs.kubectl}/bin"

            # Check if bootstrap is complete (GitRepository and Kustomization exist and are ready)
            if ${pkgs.kubectl}/bin/kubectl get gitrepository flux-system -n flux-system &>/dev/null && \
               ${pkgs.kubectl}/bin/kubectl get kustomization flux-system -n flux-system &>/dev/null; then
              echo "Checking if Flux bootstrap is healthy..."
              
              # Check if GitRepository is ready
              GIT_READY=$(${pkgs.kubectl}/bin/kubectl get gitrepository flux-system -n flux-system -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")
              
              # Check if Kustomization is ready
              KUST_READY=$(${pkgs.kubectl}/bin/kubectl get kustomization flux-system -n flux-system -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")
              
              if [ "$GIT_READY" = "True" ] && [ "$KUST_READY" = "True" ]; then
                echo "Flux bootstrap already complete and healthy, skipping"
                exit 0
              else
                echo "Flux resources exist but are not healthy, will attempt to fix..."
              fi
            fi

            echo "Waiting for k3s to be ready..."
            sleep 30

            # Ensure flux-system namespace exists
            echo "Ensuring flux-system namespace exists..."
            ${pkgs.kubectl}/bin/kubectl create namespace flux-system --dry-run=client -o yaml | ${pkgs.kubectl}/bin/kubectl apply -f -

            # Create or update SOPS age secret BEFORE installing Flux
            echo "Creating/updating SOPS age secret..."
            AGE_KEY_FILE="${ageKeyPath}"

            if [ -f "$AGE_KEY_FILE" ]; then
              cat "$AGE_KEY_FILE" | \
              ${pkgs.kubectl}/bin/kubectl create secret generic sops-age \
                --namespace=flux-system \
                --from-file=age.agekey=/dev/stdin \
                --dry-run=client -o yaml | ${pkgs.kubectl}/bin/kubectl apply -f -
              echo "SOPS age secret created/updated"
            else
              echo "Warning: SOPS age key not found at $AGE_KEY_FILE"
              echo "SOPS decryption will not work without this key"
            fi

            # Install Flux if CRDs don't exist
            if ! ${pkgs.kubectl}/bin/kubectl get CustomResourceDefinition -A | grep -q "toolkit.fluxcd.io" ; then
              echo "Installing Flux..."
              ${pkgs.fluxcd}/bin/flux install
              
              echo "Waiting for Flux controllers to be ready..."
              ${pkgs.kubectl}/bin/kubectl wait --for=condition=ready pod \
                -l app=source-controller -n flux-system --timeout=5m || true
              ${pkgs.kubectl}/bin/kubectl wait --for=condition=ready pod \
                -l app=kustomize-controller -n flux-system --timeout=5m || true
              ${pkgs.kubectl}/bin/kubectl wait --for=condition=ready pod \
                -l app=helm-controller -n flux-system --timeout=5m || true
              ${pkgs.kubectl}/bin/kubectl wait --for=condition=ready pod \
                -l app=notification-controller -n flux-system --timeout=5m || true
            else
              echo "Flux CRDs already installed"
            fi

            # Create or update GitRepository
            echo "Creating/updating GitRepository..."
            if ${pkgs.kubectl}/bin/kubectl get gitrepository flux-system -n flux-system &>/dev/null; then
              echo "GitRepository exists, checking if update needed..."
              CURRENT_URL=$(${pkgs.kubectl}/bin/kubectl get gitrepository flux-system -n flux-system -o jsonpath='{.spec.url}')
              CURRENT_BRANCH=$(${pkgs.kubectl}/bin/kubectl get gitrepository flux-system -n flux-system -o jsonpath='{.spec.ref.branch}')
              
              if [ "$CURRENT_URL" != "${cfg.services.flux.url}" ] || [ "$CURRENT_BRANCH" != "${cfg.services.flux.branch}" ]; then
                echo "GitRepository configuration changed, updating..."
                ${pkgs.kubectl}/bin/kubectl delete gitrepository flux-system -n flux-system
                ${pkgs.fluxcd}/bin/flux create source git flux-system \
                  --url="${cfg.services.flux.url}" \
                  --branch="${cfg.services.flux.branch}" \
                  --interval=1m \
                  --namespace=flux-system
              else
                echo "GitRepository is up to date"
              fi
            else
              ${pkgs.fluxcd}/bin/flux create source git flux-system \
                --url="${cfg.services.flux.url}" \
                --branch="${cfg.services.flux.branch}" \
                --interval=1m \
                --namespace=flux-system
            fi

            # Create or update Kustomization
            echo "Creating/updating Kustomization..."
            if ${pkgs.kubectl}/bin/kubectl get kustomization flux-system -n flux-system &>/dev/null; then
              echo "Kustomization exists, checking if update needed..."
              CURRENT_PATH=$(${pkgs.kubectl}/bin/kubectl get kustomization flux-system -n flux-system -o jsonpath='{.spec.path}')
              
              if [ "$CURRENT_PATH" != "${cfg.services.flux.path}" ]; then
                echo "Kustomization path changed, updating..."
                ${pkgs.kubectl}/bin/kubectl delete kustomization flux-system -n flux-system
                ${pkgs.fluxcd}/bin/flux create kustomization flux-system \
                  --source=GitRepository/flux-system \
                  --path="${cfg.services.flux.path}" \
                  --prune=true \
                  --interval=10m \
                  --namespace=flux-system
              else
                echo "Kustomization is up to date"
              fi
            else
              ${pkgs.fluxcd}/bin/flux create kustomization flux-system \
                --source=GitRepository/flux-system \
                --path="${cfg.services.flux.path}" \
                --prune=true \
                --interval=10m \
                --namespace=flux-system
            fi

            echo "Triggering reconciliation..."
            ${pkgs.fluxcd}/bin/flux reconcile source git flux-system --timeout=2m
            ${pkgs.fluxcd}/bin/flux reconcile kustomization flux-system --timeout=5m

            echo "Verifying bootstrap status..."
            sleep 5

            # Final health check
            GIT_READY=$(${pkgs.kubectl}/bin/kubectl get gitrepository flux-system -n flux-system -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")
            KUST_READY=$(${pkgs.kubectl}/bin/kubectl get kustomization flux-system -n flux-system -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")

            if [ "$GIT_READY" = "True" ] && [ "$KUST_READY" = "True" ]; then
              echo "✅ Flux bootstrap complete and healthy!"
              exit 0
            else
              echo "⚠️  Flux bootstrap completed but resources are not ready yet"
              echo "GitRepository ready: $GIT_READY"
              echo "Kustomization ready: $KUST_READY"
              echo "Check status with: flux get all -A"
              exit 1
            fi
          '';
        after = [ "k3s.service" ];
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          RestartSec = "3m";
        };
      };
    };
}
