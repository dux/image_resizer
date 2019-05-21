#!/usr/bin/env bash

find ./app | entr -r puma -p 4000 -t 0:16
