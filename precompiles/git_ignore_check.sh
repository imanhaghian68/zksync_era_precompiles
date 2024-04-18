#!/bin/bash
missing_pattern=0
for file in $(ls ./precompiles/*.yul); do
    # Extract the base name of the file
    filename=$(basename "$file")
    filename="${filename%.yul}"
    # Generate the pattern for .gitignore
    gitignore_pattern="src/deps/contracts/${filename}.yul.zbin"
    # Check if the pattern exists in .gitignore
    if ! grep -qF "$gitignore_pattern" .gitignore; then
        echo "File: $filename.yul.zbin should be on the gitignore file"
        missing_pattern=1
    fi
done
if [ $missing_pattern -eq 1 ]; then
    exit 1
fi
