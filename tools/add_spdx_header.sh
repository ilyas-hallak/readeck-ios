#!/bin/bash

# spdx header info
# (edit below if you want to change copyright or license)
desired_header="// SPDX-FileCopyrightText: © 2025 Ilyas Hallak <ilhallak@gmail.com>\n//\n// SPDX-License-Identifier: MIT\n"

dry_run=false
if [[ "$1" == "--dry-run" ]]; then
  dry_run=true
  echo "running in dry-run mode. no files will be changed."
fi

# go to project root (where this script lives)
cd "$(dirname "$0")/.."

# look for all .swift files, but skip the tools folder itself
find . -type f -name "*.swift" ! -path "./tools/*" | while read -r file; do
    # check if the header is already there
    if ! grep -q "SPDX-License-Identifier: MIT" "$file"; then
        if $dry_run; then
            echo "[dry run] would add header to: $file"
        else
            # make a tmp file for the new content
            tmpfile=$(mktemp)
            # stick the header and the original content together
            printf "%b\n" "$desired_header" > "$tmpfile"
            cat "$file" >> "$tmpfile"
            # overwrite the original file with the new one
            mv "$tmpfile" "$file"
            echo "header added: $file"
        fi
    fi
done

if $dry_run; then
  echo "dry run complete. no files were changed."
else
  echo "done! all swift files now have the spdx header (if not already present)."
fi 