#!/bin/bash
# Sortuje pliki gier w bieżącym katalogu do podfolderów A-Z + 0-9_inne
set -e
count=0
for f in *; do
    [ -f "$f" ] || continue
    first_char=$(echo "${f:0:1}" | tr '[:lower:]' '[:upper:]')
    if [[ "$first_char" =~ [A-Z] ]]; then
        target_dir="$first_char"
    else
        target_dir="0-9_inne"
    fi
    mkdir -p "$target_dir"
    mv "$f" "$target_dir/"
    count=$((count+1))
done
echo "Przeniesiono $count plikow."
echo "Podsumowanie folderow:"
for d in */; do
    n=$(find "$d" -maxdepth 1 -type f | wc -l)
    echo "  $d : $n plikow"
done
