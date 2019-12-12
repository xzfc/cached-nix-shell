[ "$1" = -p ] && p=$PATH
dontAddDisableDepTrack=1
[ -e $stdenv/setup ] && source $stdenv/setup
set +e
[ "$1" = -p ] && { PATH=$PATH:$p; unset p; }
declare -F runHook > /dev/null && runHook shellHook
unset NIX_ENFORCE_PURITY
shift
exec "$@"
