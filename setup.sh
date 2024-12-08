#!/bin/bash

if [ ! -d linux/.git ]; then
# ln -s $PWD/buildroot/output/build/linux-main_ofl/ $PWD/linux
 ln -s $PWD/buildroot/dl/linux/git $PWD/linux/.git
fi

export USE_CCACHE=false
export USE_FILC=false
