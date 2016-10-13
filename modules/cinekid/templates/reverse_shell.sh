#!/bin/sh

exec ssh "<%= @reverse_shell_host %>" \
  -p "<%= @reverse_shell_port %>" \
  -l "<%= @reverse_shell_user %>" \
  -R 22222:localhost:22 -N
