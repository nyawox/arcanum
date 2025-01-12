---
tags:
  - Readme
---

# Arcanum

[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)
[![nixos-unstable](https://img.shields.io/badge/unstable-nixos?style=for-the-badge&logo=nixos&logoColor=cdd6f4&label=NixOS&labelColor=11111b&color=b4befe)](https://github.com/NixOS/nixpkgs)
[![GitHub Actions](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2Fnyawox%2Farcanum%2Fbadge%3Fref%3Dmain&style=for-the-badge&labelColor=11111b)](https://actions-badge.atrox.dev/nyawox/arcanum/goto?ref=main)
[![LICENSE](https://img.shields.io/github/license/nyawox/arcanum.svg?style=for-the-badge&labelColor=11111b&color=94e2d5)](https://github.com/nyawox/arcanum)

## Quick Start

**SSH keys in /etc/ssh will be copied over to the new installation.**

### bin/localinstall

```bash
Usage : localinstall -h <hostname> [options]

Options:

* -h, --host <hostname>
Set the config hostname to install from this flake

* --secureboot
Generate secure boot keys.

* --initrdssh
Generate initrd SSH host keys.

* --homesecrets
Install home secrets key

* --username
Set the username to install secrets (optional)
```

### bin/remoteinstall

```bash
Usage : remoteinstall -h <hostname> -p <port> -i <ip> [options]

Options:


* -h, --host <hostname>
Set the config hostname to install from this flake.

* -p, --port <ssh_port>
Set the SSH port to connect with.

* -i, --ip <ssh_ip>
Set the destination IP to install.

* --identity-key <file_path>
Set the private key to use

* --secureboot
Generate secure boot keys.

* --initrdssh
Generate initrd SSH host keys.

* --homesecrets
Install home secrets key

* --username
Set the username to install secrets (optional)
```

`--initrdssh` requires sudo.

## Deploy

`nix run` or `nix run -- -t host1,host2`

## TODOs

- [ ] At least in private git instance try to use proper commit prefix. [see here][https://github.com/angular/angular.js/blob/master/DEVELOPERS.md#type]
- [ ] Deploy hashicorp vault or something capable of rotating credentials
- [ ] Figure out how to achieve fully automated remote luks unlock
- [ ] Organize secrets structure, with per-machine credentials and preferably credentials rotation
- [ ] After implementing all library features eventually stabilize the structure to a point where i feel comfortable mirroring all commits from private git instance to GitHub without rebasing
- [x] Handle acme.sh failure and send a fail signal to healthchecks
- [ ] Copying ssh age key at installation is tedious. find a way to manage this remotely, kms solution?
