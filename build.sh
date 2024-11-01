#!/usr/bin/env bash
set -e

nasm -f elf64 -o main.o main.asm
ld -o main main.o
