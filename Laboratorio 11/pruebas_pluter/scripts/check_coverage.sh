#!/usr/bin/env bash
# Ejercicio 3 — Control de calidad de cobertura.
# Ejecuta flutter test en silencio, filtra código autogenerado de coverage/lcov.info,
# calcula la cobertura neta y falla (exit 1) si es menor al umbral (85 % por defecto).
set -euo pipefail

MIN_COVERAGE="${MIN_COVERAGE:-85}"
cd "$(dirname "$0")/.."

LOG_FILE="$(mktemp)"
trap 'rm -f "$LOG_FILE"' EXIT

echo ">> Ejecutando pruebas con cobertura..."
if ! flutter test --coverage >"$LOG_FILE" 2>&1; then
  echo "ERROR: fallaron las pruebas. Salida completa:" >&2
  cat "$LOG_FILE" >&2
  exit 1
fi

if [[ ! -f coverage/lcov.info ]]; then
  echo "ERROR: no se generó coverage/lcov.info" >&2
  exit 1
fi

echo ">> Filtrando archivos autogenerados..."
report="$(awk -v clean="coverage/clean_lcov.info" '
  function excluded(f) {
    return (f ~ /\.g\.dart$/ || f ~ /\.freezed\.dart$/ || f ~ /\.gr\.dart$/ ||
            f ~ /\.config\.dart$/ || f ~ /(^|\/)generated\// ||
            f == "lib/main.dart")
  }
  BEGIN { printf "" > clean }
  /^SF:/ { file = $0; sub(/^SF:/, "", file); gsub(/\\/, "/", file);
           skip = excluded(file); buf = ""; lf = 0; lh = 0 }
  { buf = buf $0 "\n" }
  /^LF:/ { lf = substr($0, 4) + 0 }
  /^LH:/ { lh = substr($0, 4) + 0 }
  /^end_of_record/ {
    if (!skip) {
      printf "%s", buf >> clean
      total += lf; hit += lh
      files[++n] = file; flf[n] = lf; flh[n] = lh
    }
  }
  END {
    print "TOTAL", total + 0, hit + 0
    for (i = 1; i <= n; i++) print "FILE", files[i], flh[i], flf[i]
  }
' coverage/lcov.info)"

total="$(echo "$report" | awk '$1=="TOTAL"{print $2}')"
hit="$(echo "$report" | awk '$1=="TOTAL"{print $3}')"

if [[ "${total:-0}" -eq 0 ]]; then
  echo "ERROR: no hay líneas instrumentadas tras el filtrado." >&2
  exit 1
fi

pct="$(awk -v h="$hit" -v t="$total" 'BEGIN { printf "%.2f", h * 100 / t }')"
echo ">> Cobertura neta: ${pct}% (${hit}/${total} líneas) — umbral: ${MIN_COVERAGE}%"

if awk -v p="$pct" -v m="$MIN_COVERAGE" 'BEGIN { exit !(p + 0 >= m + 0) }'; then
  echo "OK: la cobertura cumple el mínimo requerido."
  exit 0
fi

echo "" >&2
echo "ERROR: cobertura ${pct}% inferior al mínimo de ${MIN_COVERAGE}%." >&2
echo "Archivos por debajo del umbral:" >&2
echo "$report" | awk -v m="$MIN_COVERAGE" '
  $1=="FILE" && $4 > 0 && ($3 * 100 < m * $4) {
    printf "  - %s: %.1f%% (%d/%d líneas)\n", $2, $3 * 100 / $4, $3, $4
  }' >&2
exit 1
