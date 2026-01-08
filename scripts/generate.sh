#!/bin/bash

# 1. Run the Buf generation
echo "Generating code from protos..."
buf generate

# --- GO AUTO-PACKAGING ---
echo "Updating Go dependencies..."
if [ ! -f "go.mod" ]; then
    # Initialize if it doesn't exist
    go mod init github.com/Jehoi-ga-ada/aegis-genome
fi
# Clean up and verify generated Go files
go mod tidy

# --- PYTHON AUTO-PACKAGING ---
echo "Setting up Python packages..."
# Ensure every directory has an __init__.py so Python treats them as packages
find gen/python -type d -exec touch {}/__init__.py \;

# --- TYPESCRIPT AUTO-PACKAGING ---
echo "Setting up TypeScript exports..."
TS_GEN_DIR="gen/ts"

generate_ts_index() {
    local dir=$1
    local index_file="$dir/index.ts"
    > "$index_file" # Clear file
    
    for entry in "$dir"/*; do
        if [ -d "$entry" ]; then
            generate_ts_index "$entry"
            echo "export * from './$(basename "$entry")';" >> "$index_file"
        elif [[ "$entry" == *.ts ]] && [[ "$(basename "$entry")" != "index.ts" ]]; then
            local filename=$(basename "$entry" .ts)
            echo "export * from './$filename';" >> "$index_file"
        fi
    done
}

if [ -d "$TS_GEN_DIR" ]; then
    generate_ts_index "$TS_GEN_DIR"
fi

echo "✅ Generation and packaging complete."