#!/bin/bash

# Create a build folder if it doesn't exist
mkdir -p build

# Compile the shell
if gcc shell_main.c shell_core.c -o ./build/shell -Wall `pkg-config --cflags --libs gtk+-3.0`; then
    echo "Build successful. Launching AmitX Shell..."
    ./build/shell
else
    echo "Compilation failed."
    exit 1
fi