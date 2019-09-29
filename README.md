# Project
## Build & Test
```
make        --build the project
make test   --make and run tests
make clean  --clean out builds and build files
```

# Docker
## Build 
```
cd path-to-git
docker build -t a-name .
```

## Run Shell
```
docker run --rm -v `pwd`:/home/cd_project a-name /bin/bash
```

## Run tests
```
docker run --rm -v `pwd`:/home/cd_project -it a-name /bin/bash \
    -c "cd hw1; make clean; ls hellocaml.ml providedtests.ml | entr -s 'make test'"
```