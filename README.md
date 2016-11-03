# Buildbox Containers

## Buildbox

**Buildbox** is a single build node equiped with following tools:
- `bash`
- `curl`
- `docker`
- `git`
- `jq`
- `vim`
- `wget`

Recommended build flow:

1. Clone `git` repository
2. Run `docker build` to build any Docker images: builder, app, test containers.

## Challenges

How to create multiple and independent **buildfox** environments running on same machine? 
How to provide convinient access to these **buildboxes**

## Solution

Each **buildbox** is [dind Docker](https://hub.docker.com/_/docker/) container enriched with additional tools.
It is possible to use `docker` client with `--host` flag to connect to docker daemon running inside **buildbox**. 
In addition, it is possible to create *special* `ssh`, that allows to connect with `ssh` to the **buildbox** or to use web terminal to access **buildbox** terminal from browser


Run `init.sh` script, to start two **buildboxes** and two `ssh` containers connected to these boxes.

```
$ ./init.sh
```
