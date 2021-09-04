# Cardano Node Dockerfile

This repository maintains an unofficial Dockerfile for the [cardano-node](https://github.com/input-output-hk/cardano-node)
software based on Ubuntu 20.04. It follows the [guide](https://github.com/input-output-hk/cardano-tutorials/blob/master/node-setup/000_install.md)
by IOHK outlining how to compile the cardano node software on Linux distributions. The Dockerfile for the Ubuntu base images are located in another 
repository ([outofbits/cardano-base-images](https://github.com/outofbits/cardano-base-images)).

## Building

In order to build the image in this repository, the arguments below have to be specified.

| Argument | Description |
| --- | --- |
| NODE_VERSION | version of the cardano-node for which the image shall be built |
| NODE_REPOSITORY | repository from which the source code shall be fetched |
| NODE_BRANCH | branch of the repository that shall be checked out |

We can build version `1.29.0` of the cardano-node in the original [repository](https://github.com/input-output-hk/cardano-node) with the following command.

```
docker build --build-arg NODE_VERSION=1.29.0 --build-arg NODE_BRANCH=master \
  --build-arg NODE_REPOSITORY="https://github.com/input-output-hk/cardano-node" .
```

This code repository includes also a Makefile to quickly create images from the default IOHK source for `amd64` and `arm64` platform. 

```
NODE_VERSION=1.29.0 make amd64 arm64 manifest
```

## Running

The image contains the cardano-node as well as the cardano-cli executable. The default entrypoint points to the cardano-node executable. 

### Cardano Node

```
docker run adalove/cardano-node:1.29.0 --help
```

#### Healthcheck

The image contains a small Go program for checking the health of a cardano-node. The program gathers information from the Prometheus endpoint of the node and concludes whether it is healthy based on specified
thresholds.

|         Argument           |          Expected Value           |   Description  |
|--------------------------- | --------------------------------- | -------------- |
| -max-time-since-last-block | duration (e.g. 5m for 5 minutes)  | specifies how long a `cardano-node` can be inable to fetch the most recently minted block |


Example:
```
healthcheck -max-time-since-last-block 5m
```

### Cardano CLI

```
docker run --entrypoint "cardano-cli" adalove/cardano-node:u1.29.0 --help
```

## Where to store your data?

There are several ways to store data used by applications that run in Docker containers. We encourage users of the cardano-node images to familiarize themselves with the options available, including:

* Let Docker manage the storage of your blockchain data by writing the database files to disk on the host system using its own internal volume management. This is the default and is easy and fairly transparent to the user. The downside is that the files may be hard to locate for tools and applications that run directly on the host system, i.e. outside containers.
    
* Create a data directory on the host system (outside the container) and mount this to a directory visible from inside the container. This places the database files in a known location on the host system, and makes it easy for tools and applications on the host system to access the files. The downside is that the user needs to make sure that the directory exists and that e.g. directory permissions and other security mechanisms on the host system are set up correctly.

The Docker documentation is a good starting point for understanding the different storage options and variations, and there are multiple blogs and forum postings that discuss and give advice in this area. We will simply show the basic procedure here for the latter option above:

1. Create a data directory on a suitable volume on your host system, e.g. `/my/own/cardano-node/data`.
2. Start your cardano-node container like this, depending on how you have specified the database path: 
    `docker run -v /my/own/cardano-node/data:/data adalove/cardano-node:tag --database-path /data ...`

Note that users on host systems with SELinux enabled may see issues with this. The current workaround is to assign the relevant SELinux policy type to the new data directory so that the container will be allowed to access it:

`chcon -Rt svirt_sandbox_file_t /my/own/cardano-node/data`

## Contribution

Feel free to submit tickets and pull requests.