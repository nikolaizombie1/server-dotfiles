{ config, ... }:
let
  username = import ./name.nix;
  personalRepo = "https://aramis-matos.github.io/dotfiles";
  secretsLoc = "./secrets";
  caDirectory = "./home-ca";
in
{
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      "--debug"
      "--disable=traefik"
    ];
    gracefulNodeShutdown = {
      enable = false;
      shutdownGracePeriod = "10s";
    };
    autoDeployCharts = {
      nginx = {
        repo = "oci://ghcr.io/nginx/charts/nginx-ingress";
        version = "2.5.0";
        hash = "sha256-uLNv9t8mOqniY/3UT4SeQYwu1EGrl++rES8hIBZEJ1A=";
        values = {
          controller = {
            enableSnippets = true;
            service = {
              httpsPort = {
                port = 443;
              };
              httpPort = {
                port = 80;
              };
            };
          };
        };
      };
      cert-manager = {
        repo = "oci://quay.io/jetstack/charts/cert-manager";
        version = "v1.19.2";
        hash = "sha256-h+La+pRr0FxWvol7L+LhcfK7+tlsnUhAnUsRiNJAr28";
        targetNamespace = "cert-manager";
        createNamespace = true;
        values = {
          crds = {
            enabled = true;
          };
        };
      };
      longhorn = {
        repo = "https://charts.longhorn.io";
        name = "longhorn";
        version = "1.11.1";
        hash = "sha256-qT9gBS5ebjCNB+k/s+zA5NM2u9MjtyXwaJ3y5NaVJFs=";
        targetNamespace = "longhorn-system";
        createNamespace = true;
        values = {
          defaultSettings = {
            defaultDataPath = "/home/${username}/Mass_Storage/longhorn";
            defaultReplicaCount = 1;
            storageMinimalAvailablePercentage = 2;
            storageReservedPercentageForDefaultDisk = 2;
          };
          persistence = {
            defaultClassReplicaCount = 1;
          };
        };
      };
      reflector = {
        repo = "oci://ghcr.io/emberstack/helm-charts/reflector";
        version = "10.0.24";
        hash = "sha256-Aq2/DLyHzEy3Sqp9bYhOgAqYXehRzKSHxQf9mkZaJDw=";
      };
      jellyfin = {
        repo = personalRepo;
        name = "jellyfin";
        version = "0.1.0";
        hash = "sha256-oYL3eJ4meJiGD52MYXtxJJB+1EE51M1DiYdQMrxvg8E=";
        targetNamespace = "jellyfin";
        createNamespace = true;
      };
      ttyd = {
        repo = personalRepo;
        name = "ttyd";
        version = "0.1.0";
        hash = "sha256-JJicpWoQnDGfP1h/YZTvFT0SXdICA6J40Lwqn5TxzUw=";
        targetNamespace = "ttyd";
        createNamespace = true;
        values = {
          startup = {
            config = (builtins.readFile ./${secretsLoc}/startup-config.conf);
          };
        };
      };
      ddclient = {
        repo = personalRepo;
        name = "ddclient";
        version = "0.1.0";
        hash = "sha256-I5z6PNw2fJsa6/5nyD7tsgt7jNa+fTuS4q4EPrLDsxc=";
        targetNamespace = "ddclient";
        createNamespace = true;
        values = {
          secrets = {
            secret = (builtins.readFile ./${secretsLoc}/ddclient.conf);
          };
        };
      };
      dns = {
        repo = personalRepo;
        name = "dns";
        version = "2.0.0";
        hash = "sha256-ti8LctLGF5YKQiZtsiSwn1P6ODERSL3UCgxUrDc7BSU=";
        targetNamespace = "dns";
        createNamespace = true;
        values = {
          bind9 = {
            secrets = {
              zoneValue = (builtins.readFile ./${secretsLoc}/home.lab.zone);
              namedConfValue = (builtins.readFile ./${secretsLoc}/named.conf);
            };
          };
          pihole = {
            secrets = {
              value = (import ./${secretsLoc}/pihole-password.nix);
            };
          };
        };
      };
      certs = {
        repo = personalRepo;
        name = "certs";
        version = "0.1.0";
        hash = "sha256-LoDN07+lmkR92ZUDgUwnD1d22qB9cJDa+SS4xJ1hIdU=";
        targetNamespace = "cert-manager";
        createNamespace = true;
        values = {
          stage = "production";
          cf = {
            secrets = {
              apiToken = (builtins.readFile ./${secretsLoc}/cf-password);
              email = (builtins.readFile ./${secretsLoc}/cf-email);
            };
          };
          lab = {
            secrets = {
              ca = {
                cert = (builtins.readFile ./${caDirectory}/home-ca.crt);
                key = (builtins.readFile ./${caDirectory}/home-ca.key);
              };
            };
          };
        };
      };
      vpn = {
        repo = personalRepo;
        name = "vpn";
        version = "0.6.0";
        hash = "sha256-ba3khTRs37IOnTajWGj+F76uHK9pxUP/78qprYFzG0w=";
        targetNamespace = "vpn";
        createNamespace = true;
        values = {
          gluetun = {
            secrets = {
              addresses = {
                value = (builtins.readFile ./${secretsLoc}/gluetun-addresses);
              };
              privateKey = {
                value = (builtins.readFile ./${secretsLoc}/gluetun-private-key);
              };
            };
          };
          slskd = {
            config = {
              value =  (builtins.readFile ./${secretsLoc}/slskd.yml);
            };
          };
        };
      };
      longhorn-ingress = {
        repo = personalRepo;
        name = "longhorn-ingress";
        version = "0.1.0";
        hash = "sha256-odLHcMvVQMe0qtLcx5N0bJVUVZ1FOUiYzqzjMQc8yiM=";
        targetNamespace = "longhorn-system";
        createNamespace = true;
      };
    };
  };
  services.openiscsi = {
    enable = true;
    name = "${config.networking.hostName}-initiatorhost";
  };
  systemd.services.iscsid.serviceConfig = {
    PrivateMounts = "yes";
    BindPaths = "/run/current-system/sw/bin:/bin";
  };
}
