# borrowed straight from https://github.com/cynicsketch/nix-mineral, with some modifications made to address issues
# none of the kernelParams override option work as intended in original module, and the filesystem hardening assumes standard partition structure
# which breaks my impermanence setup
# and make my devices unbootable
{
  cfg,
  config,
  lib,
  pkgs,
  platform,
  ...
}:
with lib;
{
  options = {
    compatibility = {
      disable-wifi-mac-rando = mkOption {
        type = types.bool;
        default = false;
      };

      allow-unsigned-modules = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Allow loading unsigned kernel modules.
        '';
      };
      allow-binfmt-misc = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Reenable binfmt_misc.
        '';
      };
      allow-busmaster-bit = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Reenable the busmaster bit at boot.
        '';
      };
      allow-io-uring = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Reenable io_uring.
        '';
      };
      allow-ip-forward = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Reenable ip forwarding.
        '';
      };
      no-lockdown = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Disable Linux Kernel Lockdown.
        '';
      };
    };
    desktop = {
      allow-multilib = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Reenable support for 32 bit applications.
        '';
      };
      allow-unprivileged-userns = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Allow unprivileged userns.
        '';
      };
      allow-unprivileged-bpf = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Allow unprivileged bpf.
        '';
      };
      relax-bpf = mkOption {
        type = types.bool;
        default = false;
      };
      nix-allow-all = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Allow all users to use nix.
        '';
      };
      yama-relaxed = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Instead of disabling ptrace, restrict only so that parent processes can
          ptrace descendants.
        '';
      };
    };
    performance = {
      allow-smt = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Reenable symmetric multithreading.
        '';
      };
      iommu-passthrough = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable bypassing the IOMMU for direct memory access.
        '';
      };
      no-mitigations = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Disable all CPU vulnerability mitigations.
        '';
      };
      no-pti = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Disable page table isolation.
        '';
      };
    };
    security = {
      disable-bluetooth-kmodules = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Disable bluetooth related kernel modules.
        '';
      };
      disable-intelme-kmodules = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Disable Intel ME related kernel modules and partially disable ME interface.
        '';
      };
      disable-tcp-window-scaling = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Disable TCP window scaling.
        '';
      };
      hardened-malloc-systemwide = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Use hardened-malloc as the default memory allocator for all running
          processes.
        '';
      };
      lock-root = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Lock the root user.
        '';
      };
      minimize-swapping = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Reduce frequency of swapping to bare minimum.
        '';
      };
      sysrq-sak = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable Secure Attention Key with the sysrq key.
        '';
      };
      disable-tcp-timestamp = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Disable TCP timestamps to avoid leaking system time, as opposed to enabling
          it by default to protect against wrapped sequence numbers/improve
          performance
        '';
      };
    };
  };
  content = mkMerge [
    (mkIf cfg.compatibility.disable-wifi-mac-rando {
      networking.networkmanager.wifi.macAddress = mkForce "preserve";
    })
    # Compatibility

    (mkIf cfg.compatibility.allow-binfmt-misc {
      boot.kernel.sysctl."fs.binfmt_misc.status" = mkForce "1";
    })

    (mkIf cfg.compatibility.allow-io-uring {
      boot.kernel.sysctl."kernel.io_uring_disabled" = mkForce "0";
    })

    (mkIf cfg.compatibility.allow-ip-forward {
      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = mkForce "1";
        "net.ipv4.conf.all.forwarding" = mkForce "1";
        "net.ipv4.conf.default.forwarding" = mkForce "1";
        "net.ipv6.conf.all.forwarding" = mkForce "1";
        "net.ipv6.conf.default.forwarding" = mkForce "1";
      };
    })

    # Desktop

    (mkIf cfg.desktop.allow-unprivileged-userns {
      boot.kernel.sysctl."kernel.unprivileged_userns_clone" = mkForce "1";
    })

    (mkIf cfg.desktop.allow-unprivileged-bpf {
      boot.kernel.sysctl."kernel.unprivileged_bpf_disabled" = mkForce "0";
    })

    (mkIf cfg.desktop.relax-bpf {
      boot.kernel.sysctl."net.core.bpf_jit_harden" = mkForce "0";
    })

    (mkIf cfg.desktop.nix-allow-all { nix.settings.allowed-users = mkForce [ "*" ]; })

    (mkIf cfg.desktop.yama-relaxed {
      boot.kernel.sysctl."kernel.yama.ptrace_scope" = mkForce "1";
    })

    # Security

    (mkIf cfg.security.disable-bluetooth-kmodules {
      environment.etc."modprobe.d/nm-disable-bluetooth.conf" = {
        text = ''
          install bluetooth /usr/bin/disabled-bluetooth-by-security-misc
          install bluetooth_6lowpan  /usr/bin/disabled-bluetooth-by-security-misc
          install bt3c_cs /usr/bin/disabled-bluetooth-by-security-misc
          install btbcm /usr/bin/disabled-bluetooth-by-security-misc
          install btintel /usr/bin/disabled-bluetooth-by-security-misc
          install btmrvl /usr/bin/disabled-bluetooth-by-security-misc
          install btmrvl_sdio /usr/bin/disabled-bluetooth-by-security-misc
          install btmtk /usr/bin/disabled-bluetooth-by-security-misc
          install btmtksdio /usr/bin/disabled-bluetooth-by-security-misc
          install btmtkuart /usr/bin/disabled-bluetooth-by-security-misc
          install btnxpuart /usr/bin/disabled-bluetooth-by-security-misc
          install btqca /usr/bin/disabled-bluetooth-by-security-misc
          install btrsi /usr/bin/disabled-bluetooth-by-security-misc
          install btrtl /usr/bin/disabled-bluetooth-by-security-misc
          install btsdio /usr/bin/disabled-bluetooth-by-security-misc
          install btusb /usr/bin/disabled-bluetooth-by-security-misc
          install virtio_bt /usr/bin/disabled-bluetooth-by-security-misc
        '';
      };
    })

    (mkIf cfg.security.disable-intelme-kmodules {
      environment.etc."modprobe.d/nm-disable-intelme-kmodules.conf" = {
        text = ''
          install mei /usr/bin/disabled-intelme-by-security-misc
          install mei-gsc /usr/bin/disabled-intelme-by-security-misc
          install mei_gsc_proxy /usr/bin/disabled-intelme-by-security-misc
          install mei_hdcp /usr/bin/disabled-intelme-by-security-misc
          install mei-me /usr/bin/disabled-intelme-by-security-misc
          install mei_phy /usr/bin/disabled-intelme-by-security-misc
          install mei_pxp /usr/bin/disabled-intelme-by-security-misc
          install mei-txe /usr/bin/disabled-intelme-by-security-misc
          install mei-vsc /usr/bin/disabled-intelme-by-security-misc
          install mei-vsc-hw /usr/bin/disabled-intelme-by-security-misc
          install mei_wdt /usr/bin/disabled-intelme-by-security-misc
          install microread_mei /usr/bin/disabled-intelme-by-security-misc
        '';
      };
    })

    (mkIf cfg.security.disable-tcp-window-scaling {
      boot.kernel.sysctl."net.ipv4.tcp_window_scaling" = mkForce "0";
    })

    (mkIf cfg.security.hardened-malloc-systemwide {
      environment.memoryAllocator = {
        provider = "graphene-hardened";
      };
    })

    (mkIf cfg.security.lock-root {
      users = {
        users = {
          root = {
            hashedPassword = "!";
          };
        };
      };
    })

    (mkIf cfg.security.minimize-swapping {
      boot.kernel.sysctl."vm.swappiness" = mkForce "1";
    })

    (mkIf cfg.security.sysrq-sak { boot.kernel.sysctl."kernel.sysrq" = mkForce "4"; })

    (mkIf cfg.security.disable-tcp-timestamp {
      boot.kernel.sysctl."net.ipv4.tcp_timestamps" = mkForce "0";
    })

    # Software Choice

    {
      boot = {
        kernel = {
          sysctl = {
            # Unprivileged userns has a large attack surface and has been the cause
            # of many privilege escalation vulnerabilities, but can cause breakage.
            "kernel.unprivileged_userns_clone" = "0";

            # Yama restricts ptrace, which allows processes to read and modify the
            # memory of other processes. This has obvious security implications.
            "kernel.yama.ptrace_scope" = "3";

            # Disables magic sysrq key. See file regarding SAK (Secure
            # attention key).
            "kernel.sysrq" = "0";

            # Disable binfmt. Breaks Roseta, see file.
            "fs.binfmt_misc.status" = "0";

            # Disable io_uring. May be desired for Proxmox, but is responsible
            # for many vulnerabilities and is disabled on Android + ChromeOS.
            "kernel.io_uring_disabled" = "2";

            # Disable ip forwarding to reduce attack surface. May be needed for
            # VM networking. See file.
            "net.ipv4.ip_forward" = "0";
            "net.ipv4.conf.all.forwarding" = "0";
            "net.ipv4.conf.default.forwarding" = "0";
            "net.ipv6.conf.all.forwarding" = "0";
            "net.ipv6.conf.default.forwarding" = "0";

            # Privacy/security split.
            "net.ipv4.tcp_timestamps" = "1";

            "dev.tty.ldisc_autoload" = "0";
            "fs.protected_fifos" = "2";
            "fs.protected_hardlinks" = "1";
            "fs.protected_regular" = "2";
            "fs.protected_symlinks" = "1";
            "fs.suid_dumpable" = "0";
            "kernel.dmesg_restrict" = "1";
            "kernel.kexec_load_disabled" = "1";
            "kernel.kptr_restrict" = "2";
            "kernel.perf_event_paranoid" = "3";
            "kernel.printk" = "3 3 3 3";
            "kernel.unprivileged_bpf_disabled" = "1";
            "net.core.bpf_jit_harden" = "2";
            "net.ipv4.conf.all.accept_redirects" = "0";
            "net.ipv4.conf.all.accept_source_route" = "0";
            "net.ipv4.conf.all.rp_filter" = "1";
            "net.ipv4.conf.all.secure_redirects" = "0";
            "net.ipv4.conf.all.send_redirects" = "0";
            "net.ipv4.conf.default.accept_redirects" = "0";
            "net.ipv4.conf.default.accept_source_route" = "0";
            "net.ipv4.conf.default.rp_filter" = "1";
            "net.ipv4.conf.default.secure_redirects" = "0";
            "net.ipv4.conf.default.send_redirects" = "0";
            # we can handle this at firewall level
            # "net.ipv4.icmp_echo_ignore_all" = "1";
            "net.ipv6.icmp_echo_ignore_all" = "1"; # won't be using this to debug
            "net.ipv4.tcp_dsack" = "0";
            "net.ipv4.tcp_fack" = "0";
            "net.ipv4.tcp_rfc1337" = "1";
            "net.ipv4.tcp_sack" = "0";
            "net.ipv4.tcp_syncookies" = "1";
            "net.ipv6.conf.all.accept_ra" = "0";
            "net.ipv6.conf.all.accept_redirects" = "0";
            "net.ipv6.conf.all.accept_source_route" = "0";
            "net.ipv6.conf.default.accept_redirects" = "0";
            "net.ipv6.conf.default.accept_source_route" = "0";
            "net.ipv6.default.accept_ra" = "0";
            "kernel.core_pattern" = "|/bin/false";
            "vm.mmap_rnd_bits" = mkIf (platform == "x86_64-linux") "32"; # linux kernel >= 6.12, in aarch64 hosts don't accept values higher than the default 18
            "vm.mmap_rnd_compat_bits" = "16";
            "vm.unprivileged_userfaultfd" = "0";
            "net.ipv4.icmp_ignore_bogus_error_responses" = "1";

            # enable ASLR
            # turn on protection and randomize stack, vdso page and mmap + randomize brk base address
            "kernel.randomize_va_space" = "2";

            # restrict perf subsystem usage (activity) further
            "kernel.perf_cpu_time_max_percent" = "1";
            "kernel.perf_event_max_sample_rate" = "1";

            # do not allow mmap in lower addresses
            "vm.mmap_min_addr" = "65536";

            # log packets with impossible addresses to kernel log
            # No active security benefit, just makes it easier to spot a DDOS/DOS by giving
            # extra logs
            "net.ipv4.conf.default.log_martians" = "1";
            "net.ipv4.conf.all.log_martians" = "1";

            # disable sending and receiving of shared media redirects
            # this setting overwrites net.ipv4.conf.all.secure_redirects
            # refer to RFC1620
            "net.ipv4.conf.default.shared_media" = "0";
            "net.ipv4.conf.all.shared_media" = "0";

            # always use the best local address for announcing local IP via ARP
            # Seems to be most restrictive option
            "net.ipv4.conf.default.arp_announce" = "2";
            "net.ipv4.conf.all.arp_announce" = "2";

            # reply only if the target IP address is local address configured on the incoming interface
            "net.ipv4.conf.default.arp_ignore" = "1";
            "net.ipv4.conf.all.arp_ignore" = "1";

            # drop Gratuitous ARP frames to prevent ARP poisoning
            # this can cause issues when ARP proxies are used in the network
            "net.ipv4.conf.default.drop_gratuitous_arp" = "1";
            "net.ipv4.conf.all.drop_gratuitous_arp" = "1";

            # ignore all ICMP echo and timestamp requests sent to broadcast/multicast
            "net.ipv4.icmp_echo_ignore_broadcasts" = "1";

            # number of Router Solicitations to send until assuming no routers are present
            "net.ipv6.conf.default.router_solicitations" = "0";
            "net.ipv6.conf.all.router_solicitations" = "0";

            # do not accept Router Preference from RA
            "net.ipv6.conf.default.accept_ra_rtr_pref" = "0";
            "net.ipv6.conf.all.accept_ra_rtr_pref" = "0";

            # learn prefix information in router advertisement
            "net.ipv6.conf.default.accept_ra_pinfo" = "0";
            "net.ipv6.conf.all.accept_ra_pinfo" = "0";

            # setting controls whether the system will accept Hop Limit settings from a router advertisement
            "net.ipv6.conf.default.accept_ra_defrtr" = "0";
            "net.ipv6.conf.all.accept_ra_defrtr" = "0";

            # router advertisements can cause the system to assign a global unicast address to an interface
            "net.ipv6.conf.default.autoconf" = "0";
            "net.ipv6.conf.all.autoconf" = "0";

            # number of neighbor solicitations to send out per address
            "net.ipv6.conf.default.dad_transmits" = "0";
            "net.ipv6.conf.all.dad_transmits" = "0";

            # number of global unicast IPv6 addresses can be assigned to each interface
            "net.ipv6.conf.default.max_addresses" = "1";
            "net.ipv6.conf.all.max_addresses" = "1";

            # enable IPv6 Privacy Extensions (RFC3041) and prefer the temporary address
            # https://grapheneos.org/features#wifi-privacy
            # GrapheneOS devs seem to believe it is relevant to use IPV6 privacy
            # extensions alongside MAC randomization, so that's why we do both
            # Commented, as this is already explicitly defined by default in NixOS
            # "net.ipv6.conf.default.use_tempaddr" = mkForce "2";
            # "net.ipv6.conf.all.use_tempaddr" = mkForce "2";

            # ignore all ICMPv6 echo requests
            "net.ipv6.icmp.echo_ignore_all" = "1";
            "net.ipv6.icmp.echo_ignore_anycast" = "1";
            "net.ipv6.icmp.echo_ignore_multicast" = "1";
          };
        };

        kernelParams = [
          # Requires all kernel modules to be signed. This prevents out-of-tree
          # kernel modules from working unless signed.
          (mkIf (!cfg.compatibility.allow-unsigned-modules) "module.sig_enforce=1")
          # the original mkOverride solution used to disable in original module does nothing.

          # May break some drivers, same reason as the above. Also breaks
          # hibernation.
          (mkIf (!cfg.compatibility.no-lockdown) "lockdown=confidentiality")

          # May prevent some systems from booting.
          (mkIf (!cfg.compatibility.allow-busmaster-bit) "efi=disable_early_pci_dma")

          # Forces DMA to go through IOMMU to mitigate some DMA attacks.
          (mkIf (!cfg.performance.iommu-passthrough) "iommu.passthrough=0")

          # Apply relevant CPU exploit mitigations, and disable symmetric
          # multithreading. May harm performance.
          (mkIf (!cfg.performance.allow-smt) "mitigations=auto,nosmt")
          # optionally disable mitigations
          (mkIf cfg.performance.no-mitigations "mitigations=off")

          # Mitigates Meltdown, some KASLR bypasses. Hurts performance. (isn't this actually enabled by default??)
          (mkIf (!cfg.performance.no-pti) "pti=on")
          (mkIf cfg.performance.no-pti "pti=off")

          # Gather more entropy on boot. Only works with the linux_hardened
          # patchset, but does nothing if using another kernel. Slows down boot
          # time by a bit.
          "extra_latent_entropy"

          # Disables multilib/32 bit applications to reduce attack surface.
          (mkIf (!cfg.desktop.allow-multilib) "ia32_emulation=0")

          "slab_nomerge"
          "init_on_alloc=1"
          "init_on_free=1"
          "page_alloc.shuffle=1"
          "randomize_kstack_offset=on"
          "vsyscall=none"
          "debugfs=off"
          "oops=panic"
          "quiet"
          "loglevel=0"
          "random.trust_cpu=off"
          "random.trust_bootloader=off"
          "intel_iommu=on"
          "amd_iommu=force_isolation"
          "iommu=force"
          "iommu.strict=1"
        ];

        # Disable the editor in systemd-boot, the default bootloader for NixOS.
        # This prevents access to the root shell or otherwise weakening
        # security by tampering with boot parameters. If you use a different
        # boatloader, this does not provide anything. You may also want to
        # consider disabling similar functions in your choice of bootloader.
        loader.systemd-boot.editor = false;
      };
      environment.etc = {
        # Empty /etc/securetty to prevent root login on tty.
        securetty.text = ''
          # /etc/securetty: list of terminals on which root is allowed to login.
          # See securetty(5) and login(1).
        '';

        # Set machine-id to the Kicksecure machine-id, for privacy reasons.
        # /var/lib/dbus/machine-id doesn't exist on dbus enabled NixOS systems,
        # so we don't have to worry about that.
        machine-id.text = ''
          b08dfa6083e7567a1921a715000001fb
        '';

        # Borrow Kicksecure banner/issue.
        # only work for posix compilant shells
        issue.source = builtins.fetchurl {
          url = "https://raw.githubusercontent.com/Kicksecure/security-misc/de6f3ea74a5a1408e4351c955ecb7010825364c5/usr/lib/issue.d/20_security-misc.issue";
          sha256 = "00ilswn1661h8rwfrq4w3j945nr7dqd1g519d3ckfkm0dr49f26b";
        };

        # Borrow Kicksecure and secureblue module blacklist.
        # "install "foobar" /bin/not-existent" prevents the module from being
        # loaded at all. "blacklist "foobar"" prevents the module from being
        # loaded automatically at boot, but it can still be loaded afterwards.
        "modprobe.d/nm-module-blacklist.conf".source =
          pkgs.runCommand "filtered-blacklist"
            {
              src = builtins.fetchurl {
                url = "https://raw.githubusercontent.com/Kicksecure/security-misc/de6f3ea74a5a1408e4351c955ecb7010825364c5/etc/modprobe.d/30_security-misc_disable.conf";
                sha256 = "1mab9cnnwpc4a0x1f5n45yn4yhhdy1affdmmimmslg8rcw65ajh2";
              };
            }
            ''
              sed -e '/^## Network File Systems:/,/^install nfsv4/d' $src > $out
            ''; # disabling network storage break many usecases
      };

      # Add "proc" group to whitelist /proc access and allow systemd-logind to view
      # /proc in order to unbreak it, as well as to user@ for similar reasons.
      # See https://github.com/systemd/systemd/issues/12955, and https://github.com/Kicksecure/security-misc/issues/208
      users.groups.proc = { };
      systemd.services = {
        systemd-logind.serviceConfig.SupplementaryGroups = [ "proc" ];
        "user@".serviceConfig.SupplementaryGroups = [ "proc" ];
      };

      networking = {
        networkmanager = {
          wifi = {
            macAddress = "random";
            scanRandMacAddress = true;
          };
          # Enable IPv6 privacy extensions in NetworkManager.
          connectionConfig."ipv6.ip6-privacy" = mkDefault 2;
        };
      };

      # Enabling MAC doesn't magically make your system secure. You need to set up
      # policies yourself for it to be effective.
      security = {
        apparmor = {
          enable = true;
          killUnconfinedConfinables = true;
        };

        pam = {
          loginLimits = [
            {
              domain = "*";
              item = "core";
              type = "hard";
              value = "0";
            }
          ];
          services = {
            # Increase hashing rounds for /etc/shadow; this doesn't automatically
            # rehash your passwords, you'll need to set passwords for your accounts
            # again for this to work.
            passwd.rules.password."unix".settings.rounds = mkDefault 65536;
            # Enable PAM support for securetty, to prevent root login.
            # https://unix.stackexchange.com/questions/670116/debian-bullseye-disable-console-tty-login-for-root
            login.rules.auth = {
              "nologin" = {
                enable = mkDefault true;
                order = mkDefault 0;
                control = mkDefault "requisite";
                modulePath = mkDefault "${config.security.pam.package}/lib/security/pam_nologin.so";
              };
              "securetty" = {
                enable = mkDefault true;
                order = mkDefault 1;
                control = mkDefault "requisite";
                modulePath = mkDefault "${config.security.pam.package}/lib/security/pam_securetty.so";
              };
            };

            su.requireWheel = true;
            su-l.requireWheel = true;
            system-login.failDelay.delay = "4000000";
          };
        };
      };
      # DNS connections will fail if not using a DNS server supporting DNSSEC.
      services.resolved.dnssec = "true";

      # Get extra entropy since we disabled hardware entropy sources
      # Read more about why at the following URLs:
      # https://github.com/smuellerDD/jitterentropy-rngd/issues/27
      # https://blogs.oracle.com/linux/post/rngd1
      services.jitterentropy-rngd.enable = true;
      boot.kernelModules = [ "jitterentropy_rng" ];

      # Don't store coredumps from systemd-coredump.
      systemd = {
        coredump.extraConfig = mkDefault ''
          Storage=none
        '';

        # Enable IPv6 privacy extensions for systemd-networkd.
        network.config.networkConfig.IPv6PrivacyExtensions = mkDefault "kernel";

        tmpfiles.settings = {
          # Restrict permissions of /home/$USER so that only the owner of the
          # directory can access it (the user). systemd-tmpfiles also has the benefit
          # of recursively setting permissions too, with the "Z" option as seen below.
          "restricthome"."/home/*".Z.mode = "~0700";
        };
      };
      # Limit access to nix to users with the "wheel" group. ("sudoers")
      # nix.settings.allowed-users = mkForce ["@wheel"];
    }
  ];
}
