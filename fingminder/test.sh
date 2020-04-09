#!/bin/bash
if ! [ -L ./test.sh ]; then
    echo "FOI"
else
    echo "NAO FOI"
fi
