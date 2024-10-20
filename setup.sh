#!/bin/bash

if [ ! -e linux/.git ]; then
 ln -s ./buildroot/dl/linux/git ./linux/.git
fi
