#!/bin/bash

if [ ! -e linux/.git ]; then
 ln -s $PWD/buildroot/dl/linux/git $PWD/linux/.git
fi

export USE_CCACHE=false
export USE_FILC=false
