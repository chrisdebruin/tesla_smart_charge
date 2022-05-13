#!/bin/bash

docker save ruby_tesla | bzip2 | ssh ubuntu@pi 'bunzip2 | docker load'
