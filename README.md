# Buildbox Containers

## Buildbox

The idea behind **Buildbox** is to create an immutable and portable build environment. The **buildbox** container can build, test and deply any software project, using Docker tools or [dobi](https://dnephin.github.io/dobi/) build automation.

You can run **buildbox** on any Docker host, locally or on cloud. To reduce build time, use volumes to mount internal Docker folders (like `var/lib/docker`) and different application folders (like `node_modules`, `.maven`, `.ivy2`, `vendor` and similar). 

**Buildbox** is a single build node equiped with following tools:
- `bash`
- `curl`
- `docker`
- `docker-compose`
- `dobi`
- `git`
- `jq`
- `vim`
- `wget`


### Recommended build flow:

1. Clone `.git` repository.
2. Run `docker build ...` to build any Docker images: builder, app, test containers.
3. Or use `dobi` build automation tool for Docker, read [dobi docs](https://dnephin.github.io/dobi/)

## Challenges

- How to create multiple and independent **buildfox** environments running on same machine? 
- How to provide convinient access to these **buildboxes**?

## Solution

Each **buildbox** is [dind Docker](https://hub.docker.com/_/docker/) container enriched with additional tools.
It is possible to use `docker` client with `--host` flag to connect to docker daemon running inside **buildbox**. 
In addition, it is possible to create *special* `ssh`, that allows to connect with `ssh` to the **buildbox** or to use web terminal to access **buildbox** terminal from browser

![buildbox diagram](./images/builderbox.png)

## Try it on localhost

Run single **buildbox** with following command:
```
$ docker run -d --privileged --name buildbox \
    --hostname=buildbox-host \
    --shm-size=1g -p $12375:2375 \
    alexeiled/buildbox
```

Or run `init.sh` script, to start a new Docker registry mirror and three **buildboxes** and three `ssh` containers connected to these boxes.

```
$ ./init.sh
```
