# TODO: find a way to determine if the vm has started successfully to start wayland compositor safely without relying on sleep command
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
in
{
  content.virtualisation.libvirtd.hooks.qemu."nvidiapassthrough" = getExe (
    pkgs.writeShellApplication {
      name = "qemu-hook";

      runtimeInputs = singleton pkgs.bash;

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
          exec >> $LOG_DIR/nvidiapassthrough.log 2>&1
          set -vx

          if [[ "$GUEST_NAME" == "${wincfg.guestName}" ]]; then
            case $OPERATION in
                prepare)

                    # Handle NVIDIA drivers
                    if ${getExe' pkgs.kmod "lsmod"} | ${getExe pkgs.gnugrep} -q nvidia_drm; then
                      echo "nvidia_drm found"
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
                      # unbind vtconsoles if currently bound
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

                      # Unload NVIDIA drivers
                      echo "Unloading NVIDIA drivers..."
                      modules=("nvidia_drm" "nvidia_modeset" "nvidia_uvm" "nvidia")
                      for module in "''${modules[@]}"; do
                        ${getExe' pkgs.kmod "modprobe"} -r --remove-holders "$module"
                      done

                    fi

                    # Load VFIO modules
                    echo "Loading VFIO modules..."
                    ${getExe' pkgs.kmod "modprobe"} -a vfio vfio-pci vfio_iommu_type1
                    ;;

                # after libvirt has finished labeling all resources, but has not yet started the guest
                start)
                  echo "starting"
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

                  # Load NVIDIA drivers
                  echo "Loading NVIDIA drivers..."
                  ${getExe' pkgs.kmod "modprobe"} -a nvidia_drm nvidia_modeset nvidia_uvm nvidia
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
}
