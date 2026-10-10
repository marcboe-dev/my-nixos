HOST="${1:?Nutzung: install <nixos-laptop|nixos-vm>}"

case "$HOST" in
  nixos-laptop) HOSTDIR=laptop ;;
  nixos-vm)     HOSTDIR=vm ;;
  *) echo "Unbekannter Host: $HOST"; exit 1 ;;
esac

DIR="$HOME/my-nixos"
[ -d "$DIR" ] || git clone https://github.com/marcboe-dev/my-nixos.git "$DIR"
cd "$DIR"

cp /etc/nixos/hardware-configuration.nix "hosts/$HOSTDIR/"
git add "hosts/$HOSTDIR/hardware-configuration.nix"

sudo nixos-rebuild switch --flake ".#$HOST" --option experimental-features "nix-command flakes"
