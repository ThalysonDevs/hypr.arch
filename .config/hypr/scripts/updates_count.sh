#!/bin/bash

# Verifica updates oficiais + AUR
count=$(yay -Qu 2>/dev/null | wc -l)

# Se não houver atualizações
if [ "$count" -eq 0 ]; then
    echo ""
else
    echo "$count"
fi
