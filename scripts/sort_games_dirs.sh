#!/bin/bash
# Wariant sort_games.sh dla struktury folder-na-gre (np. ZX81, Atari XE)
set -e
count=0
for d in */; do
    d="${d%/}"
    if [[ "$d" =~ ^[A-Za-z]$ ]] || [ "$d" == "0-9_inne" ]; then
        continue
    fi
    first_char=$(echo "${d:0:1}" | tr '[:lower:]' '[:upper:]')
    if [[ "$first_char" =~ [A-Z] ]]; then
        target_dir="$first_char"
    else
        target_dir="0-9_inne"
    fi
    mkdir -p "$target_dir"
    mv "$d" "$target_dir/"
    count=$((count+1))
done
echo "Przeniesiono $count folderow."
