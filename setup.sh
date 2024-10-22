#!/bin/bash

if [ ! -e linux/.git ]; then
 ln -s $PWD/buildroot/dl/linux/git $PWD/linux/.git
fi
