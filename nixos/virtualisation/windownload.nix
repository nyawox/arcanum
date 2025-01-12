{
  config,
  lib,
  pkgs,
  arcanum,
  ...
}:
with lib;
let
  wincfg = config.modules.virtualisation.windows;
  virtio-drv = pkgs.fetchurl {
    # drivers on stable virtio iso is incompatible with 24h2 installer
    url = "https://github.com/qemus/virtiso-whql/releases/download/v1.9.43-0/virtio-win-1.9.43.tar.xz";
    sha256 = "125aymsjw7la4pgkq8ls33rsvy2dx5jc4kjpbh6zi7522sgriay2";
  };
in
{
  content = {
    # may require >= 15GiB of free space for image manipulation
    # which you probably have if you're going to setup windows
    # udisks2 is required to mount iso
    modules.system.udisks2.enable = mkForce true;
    systemd.user.services.windownload =
      let
        dir = "/home/${arcanum.username}/winstore";
        autounattend = "${arcanum.configPath}/virtualisation/windownload/autounattend.xml";
      in
      {
        enable = true;
        description = "automatically download and patch win11 iso";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        wantedBy = [ "default.target" ];

        serviceConfig.Type = "oneshot";
        path = with pkgs; [
          mido # the script checks if it's in the PATH, if not changes directory to the location of script. we don't want that
          curl # required to download iso
          udisks
          libisoburn
          wimlib
          wget
          gnutar
          xz
        ];
        # TODO: verify checksum manually
        script = ''
          download() {
            cd ${dir}
            Mido win11x64 || true # don't expect to match outdated checksum
            if [[ -f ${dir}/win11x64.iso ]]; then
              mv ${dir}/win11x64.iso ${dir}/win11x64.iso.UNVERIFIED
            fi
          }
          patch() {
            iso="${dir}/win11x64.iso.UNVERIFIED"
            iso_device="$(udisksctl loop-setup --file $iso)"
            iso_device="''${iso_device#Mapped file * as }"
            iso_device="''${iso_device%.}"
            until iso_mntpoint="$(udisksctl mount --block-device "$iso_device")"; do
              sleep 1
            done
            iso_mntpoint="''${iso_mntpoint#Mounted * at }"
            iso_mntpoint="''${iso_mntpoint%.}"
            out="${dir}/out"
            mkdir -p "$out"
            cp -frv $iso_mntpoint/* "$out/"
            chmod -R u+w "$out/"
            # remove keyboard prompt
            rm -f "$out/boot/bootfix.bin"
            cp -frv "$out/efi/microsoft/boot/cdboot_noprompt.efi" "$out/efi/microsoft/boot/cdboot.efi"
            cp -frv "$out/efi/microsoft/boot/efisys_noprompt.bin" "$out/efi/microsoft/boot/efisys.bin"
            # this xml automates the installation
            cp -frv ${autounattend} "$out/autounattend.xml"
            ${optionalString wincfg.iso.shrink
              # bash
              ''
                # patch wim files
                index=4 # Education
                # optimize wim file size
                srcwim="$out/sources/install.wim"
                custwim="${dir}/custom.wim"
                wimexport $srcwim $index $custwim
                wimoptimize $custwim --recompress --solid --solid-compress=lzms
                cp -frv $custwim $srcwim
                rm -f $custwim
              ''
            }


            # Copy VirtIO drivers to the location recognized by autounattend.xml (refer to Microsoft-Windows-PnpCustomizationsWinPE)
            # Adding the drivers to boot.img did not work.
            # When editing the WIM file, running wimupdate consecutively with the --command option is not recommended.
            # Generating a command list to pass to wimupdate also did not work. staging directory is the only way

            targetdrv=("Balloon" "NetKVM" "fwcfg" "pvpanic" "qemufwcfg" "qemupciserial" "sriov" "viofs"  "viogpudo" "vioinput" "viomem" "viorng" "vioscsi" "vioserial" "viostor")
            staging_dir="${dir}/staging"
            subpath="w11/amd64"
            virtio_drv_unpacked=${dir}/virtio-out
            mkdir -p $virtio_drv_unpacked
            tar -xf ${virtio-drv} -C "$virtio_drv_unpacked"
            chmod -R u+w $virtio_drv_unpacked
            for drv in "''${targetdrv[@]}"; do
              drvpath="$virtio_drv_unpacked/$drv/$subpath"
              drvdest="$staging_dir/virtiodrv/$drv"
              mkdir -p "$drvdest"
              cp -frv $drvpath/* "$drvdest/"
            done
            cp -frv $staging_dir/virtiodrv $out/virtiodrv
            rm -rf "$staging_dir" "$virtio_drv_unpacked"

            out_iso="${dir}/win11x64.iso"
            # repack iso with efi supoort
            xorriso -as mkisofs \
            -no-emul-boot \
            -b boot/etfsboot.com \
            -e efi/microsoft/boot/efisys.bin \
            -iso-level 3 \
            -J \
            -D \
            -N \
            -joliet-long \
            -relaxed-filenames \
            -V "WindowsSetup" \
            -o "$out_iso" \
            "$out"
            udisksctl unmount --no-user-interaction --block-device "$iso_device" || true
            udisksctl loop-delete --no-user-interaction --block-device "$iso_device" || true
            rm -rf "$out" "$iso"
          }
          if [[ -f ${dir}/win11x64.iso.UNVERIFIED ]]; then # handle case unpatched iso exists
            patch
          elif [[ ! -f ${dir}/win11x64.iso ]]; then
            download
            patch
          else
            exit 0 # Tell systemd it ran successfully
          fi
        '';
      };
  };
}
