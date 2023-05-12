#!/bin/bash

CPUARCH="amd64"
if [ "$(uname -m)" = "arm64" ]; then
    CPUARCH="arm64"
fi

echo "{\"os\": \"$(uname)\", \"arch\": \"$CPUARCH\"}"
