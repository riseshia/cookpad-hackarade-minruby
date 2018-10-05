#!/bin/bash
echo Ruby
ruby test"$1".rb
echo Miniruby
ruby interp.rb test"$1".rb
