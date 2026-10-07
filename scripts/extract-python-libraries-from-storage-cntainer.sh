#!/bin/bash
# parameter
# $1 - image name

podman run --rm --entrypoint /prod_venv/bin/python $1 -c "      
import importlib.metadata                             
seen = set()
pkgs = []
for d in importlib.metadata.distributions():
  name = d.metadata.get('Name', 'unknown')
  if name not in seen:
    seen.add(name)
    pkgs.append(name + '==' + d.version)
pkgs.sort(key=str.lower)
print('\n'.join(pkgs))"