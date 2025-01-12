{
  lib,
  arcanum,
  hostname,
  ...
}:
with lib;
{
  content = {
    services.openssh = {
      enable = true;
      openFirewall = mkForce false; # why is this enabled by default
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        X11Forwarding = false;
        Banner = "/etc/issue";
        PermitRootLogin = "no";
        AllowTcpForwarding = false;
        # ssh-agent is used to authenticate sudo
        # instead of reusing insecure memorable passwords
        AllowAgentForwarding = true;
        PermitTunnel = false;
        AllowStreamLocalForwarding = false;
        AllowUsers = singleton arcanum.username;
        AuthenticationMethods = "publickey";
        HostKeyAlgorithms = "ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,sk-ssh-ed25519-cert-v01@openssh.com,rsa-sha2-256,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com";
        Ciphers = [
          "aes128-ctr"
          "aes128-gcm@openssh.com"
          "aes256-ctr,aes192-ctr"
          "aes256-gcm@openssh.com"
        ];
        KexAlgorithms = [
          "curve25519-sha256"
          "curve25519-sha256@libssh.org"
          "diffie-hellman-group16-sha512"
          "diffie-hellman-group18-sha512"
          "sntrup761x25519-sha512@openssh.com"
        ];
        Macs = [
          "hmac-sha2-256-etm@openssh.com"
          "hmac-sha2-512"
          "hmac-sha2-512-etm@openssh.com"
          "umac-128-etm@openssh.com"
        ];
      };
      listenAddresses = [
        {
          addr = "0.0.0.0";
          port = 22420;
        }
        {
          addr = "[::]";
          port = 22420;
        }
      ];
      hostKeys = singleton {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      };
    };
    users.users."${arcanum.username}".openssh.authorizedKeys.keys = [
      # default
      (mkIf (
        hostname == "lolcathost"
      ) "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPgPZSPprj4B9RrVPh4+GCnrcTaUiXXvqbaoh9lWwaF9")
      (mkIf (
        hostname == "localpost"
      ) "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAtcE6jROh15Whm1yEtjGTum2MUc/iKXt4OdISEV8ewb")
      (mkIf (
        hostname == "localtoast"
      ) "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHpa7Qp3XqLvjgDMst7JKqPXYD6AFR9qGwOpNcFpm9TA")
      (mkIf (
        hostname == "localhoax"
      ) "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAuigCR5jpN9F1GjDygcXSvjwvQ4UREecVrj7BuqQMSx")
      (mkIf (
        hostname == "lokalhost"
      ) "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOM86kWF+pZ3JnXTxktD7L4uym+Dbr4g0vEbdedj+vXz")
      (mkIf (
        hostname == "localghost"
      ) "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBDGm5mHr0P6BNKwDMsEl8wbK7oQ+MBFkWadsY40IVWu")
      (mkIf (
        hostname == "localcoast"
      ) "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAIFrq2/a9ibLGJUctaZajgopO5BlgcU0sOt1tmbK2Yh")
      (mkIf (
        hostname == "localhostage"
      ) "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG8l2eWBqaawMtImuwJDTc0+xXTIPC73CkHwz/ndSINf")
    ];
  };
  persist = {
    directories = singleton "/root/.ssh";
    files = [
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };
  userPersist.directories = singleton {
    directory = ".ssh";
    mode = "700";
  };
}
