# Docker
## Build 
'''
cd path-to-git
docker build -t your-name .
'''

## Run Shell
'''
docker run --rm -v `pwd`:/home/cd_project your-name /bin/bash
'''

## Run tests
'''
docker run --rm -v `pwd`:/home/cd_project -it pascalwacker/ethz-comp-design-docker:latest /bin/bash -c "cd hw1; make clean; ls hellocaml.ml providedtests.ml | entr -s 'make test'"