#!/bin/bash

env="stg"
test="*"

if [ "$1" = "prod" ]; then
  env="prod" 
else
  env="stg"
fi

if [ "$2" = "redirect" ]; then
  test="redirect" 
elif [ "$2" = "cache" ]; then
  test="cache"
elif [ "$2" = "nocache" ]; then
  test="nocache"
else
  test="*"
fi

echo ruby tc_skins.rb --name /_$env\_$test/
ruby tc_skins.rb --name /_$env\_$test/
