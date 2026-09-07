#!/bin/bash
# Generyczny skrypt do rozpakowania kolekcji TOSEC z zagniezdzonymi ZIP-ami
# Uzycie: dostosuj TARGET_DIR ponizej, uruchom z tego katalogu
TARGET_DIR="$(pwd)"
find "$TARGET_DIR" -iname "*.zip" -print0 | while IFS= read -r -d '' f; do
    unzip -o -d "$TARGET_DIR" "$f" > /dev/null 2>&1
done
find "$TARGET_DIR" -iname "*.zip" -delete
find "$TARGET_DIR" -mindepth 1 -type d -empty -delete
echo "Gotowe."
ls "$TARGET_DIR" | wc -l
