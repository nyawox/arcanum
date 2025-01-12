# Make sure to Disable Above 4G Decoding and ReBar on firmware settings. this gpu don't utilize the feature to its full potential anyway.
{
  config,
  lib,
  pkgs,
  arcanum,
  ...
}:
with lib;
let
  maccfg = config.modules.virtualisation.macos;
in
{
  content = {
    boot = {
      # fix reset bug on amd gpu. unlike previous failed attempts this really work
      kernelModules = [ "vendor-reset" ];
      # OpenCore don't load without this option
      extraModprobeConfig = # bash
        ''
          options kvm ignore_msrs=1
        '';
    };
    services.udev.extraRules = # conf
      ''
        ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1002", ATTR{device}=="0x6861", RUN+="${getExe pkgs.bash} -c '${getExe' pkgs.kmod "modprobe"} vendor-reset; echo device_specific > /sys$env{DEVPATH}/reset_method'"
      '';
    virtualisation.libvirtd.hooks.qemu = {
      "amdpassthrough" = getExe (
        pkgs.writeShellApplication {
          name = "qemu-hook";

          runtimeInputs = with pkgs; [
            bash
          ];

          text =
            # bash
            ''
              # fk these strict options nix add to shell scripts automatically
              # i shouldn't really need phd in bash just to setup a simple windows vm
              set +o errexit
              set +o nounset
              set +o pipefail
              GUEST_NAME=$1
              OPERATION=$2

              echo "Initializing the passthrough script..."
              # running tmpfs root, no need to do the mktemp thing
              LOG_DIR="/home/${arcanum.username}/.local/share/libvirtd"
              if [[ ! -d "$LOG_DIR" ]]; then
                echo "The directory to store debugging log '$LOG_DIR' doesn't exist. Creating it now..."
                mkdir -p "$LOG_DIR"
                echo "Created '$LOG_DIR' successfully!"
              fi
              # Debugging
              # remember > overwrites, and >> appends. never make the mistake again
              exec >> $LOG_DIR/amdpassthrough.log 2>&1
              set -vx

              if [[ "$GUEST_NAME" == "${maccfg.guestName}" ]]; then
                case $OPERATION in
                    prepare)

                        # Handle AMD drivers
                        if ${getExe' pkgs.kmod "lsmod"} | ${getExe pkgs.gnugrep} -q amdgpu; then
                          echo "amdgpu found"
                          # Check if graphical session is active
                          if ${getExe' pkgs.systemd "systemctl"} --user -M ${arcanum.username}@ is-active --quiet graphical-session.target; then
                              echo "Stopping graphical session..."
                              ${getExe' pkgs.systemd "systemctl"} stop greetd.service
                              rm /run/greetd.run
                              ${getExe' pkgs.systemd "systemctl"} --user -M ${arcanum.username}@ stop graphical-session.target

                              # Wait for graphical session to stop
                              while ${getExe' pkgs.systemd "systemctl"} --user -M ${arcanum.username}@ is-active --quiet graphical-session.target; do
                                  sleep 1
                              done
                          fi

                          # unbinding vtconsoles isn't even necessary but it makes the proccess smoother when launching another vm with the other gpu
                          vt_unbinded=1
                          if test -e "/tmp/vfio-vtconsoles"; then
                              rm -f /tmp/vfio-vtconsoles
                          fi
                          for (( i = 0; i < 16; i++))
                          do
                            if test -x /sys/class/vtconsole/vtcon"''${i}"; then
                                if [ "$(grep -c "frame buffer" /sys/class/vtconsole/vtcon"''${i}"/name)" = 1 ]; then
                          	       echo 0 > /sys/class/vtconsole/vtcon"''${i}"/bind
                                     echo "$DATE Unbinding Console ''${i}"
                                     echo "$i" >> /tmp/vfio-vtconsoles
                                fi
                            fi
                          done

                          # Unload AMD drivers
                          ${getExe' pkgs.kmod "modprobe"} -r --remove-holders drm_kms_helper
                          ${getExe' pkgs.kmod "modprobe"} -r --remove-holders amdgpu

                        fi

                        # Load VFIO modules
                        echo "Loading VFIO modules..."
                        ${getExe' pkgs.kmod "modprobe"} -a vfio vfio-pci vfio_iommu_type1
                        ;;

                    # after libvirt has finished labeling all resources, but has not yet started the guest
                    start)
                      echo "starting"

                      # rebind vtconsoles
                      if [[ $vt_unbinded == 1 ]]; then
                        input="/tmp/vfio-vtconsoles"
                        while read -r consoleNumber; do
                          if test -x /sys/class/vtconsole/vtcon"''${consoleNumber}"; then
                              if [ "$(grep -c "frame buffer" "/sys/class/vtconsole/vtcon''${consoleNumber}/name")" \
                                   = 1 ]; then
                            echo "$DATE Rebinding console ''${consoleNumber}"
                        	  echo 1 > /sys/class/vtconsole/vtcon"''${consoleNumber}"/bind
                              fi
                          fi
                        done < "$input"
                      fi
                      
                      # since i have dual gpu start greetd again
                      ${getExe' pkgs.systemd "systemctl"} start greetd.service

                      ;;

                    release)
                        SHUTDOWN_REASON=$4
                        if [ "$SHUTDOWN_REASON" == "failed" ]; then
                          exit 1;
                        fi
                        echo "VM shutting down because of: $SHUTDOWN_REASON"
                        # Unload VFIO modules
                        echo "Unloading VFIO modules..."
                        modules=("vfio" "vfio-pci" "vfio_iommu_type1")
                        for module in "''${modules[@]}"; do
                          ${getExe' pkgs.kmod "modprobe"} -r --remove-holders "$module"
                        done

                        # Load AMD drivers
                        echo "Loading AMD drivers..."
                        ${getExe' pkgs.kmod "modprobe"} -a amdgpu

                        ;;
                    started)
                      echo "started"
                      ;;
                    migrate)
                      echo "migrating"
                      ;;
                    restore)
                      echo "restoring"
                      ;;
                    reconnect)
                      echo "reconnecting"
                      ;;
                    attach)
                      echo "attaching"
                      ;;
                    stopped)
                      echo "stopped"
                      ;;
                    *)
                      echo "Unexpected operation: $OPERATION"
                      exit 1
                      ;;

                esac
              else
                exit 0;
              fi
            '';
        }
      );
    };
  };
}
