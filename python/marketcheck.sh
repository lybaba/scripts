targets=( "ENX" "ATSB" "TUN" "BSE" "ASE" "MSM" "SSE" )

containsE() { for e in "${@:2}"; do [[ "$e" = "$1" ]] && echo 1 && return 1; done; echo 0; return 0; }
isValidTargetMarket() { echo "$(containsE "$1" "${targets[@]}")"; }

