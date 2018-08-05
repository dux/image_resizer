#!/usr/bin/env bash

rerun --no-notify --pattern="*.rb" "puma -p 4000 -t 0:32"