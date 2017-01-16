# Buildbox as Codefresh Build Node

It's possible to add a `buildbox` Docker container as a valid [Codefresh](https://www.codefresh.io) build node. 
Currently, used internally by Codefresh R&D team.

## Instructions

There is a helper `bash` script `local_run.sh`, that can create a new `buildbox` container attached to Codefresh environment.

- Have a running Codefresh environment (development, staging, or other)
- Execute `./local_run.sh -h` to show available options or run it with default options
- For example: `./local_run.sh -i 2` will create a `buildbox-2` Docker container
- Get a shell into above Docker container `docker exec -it buildbox-2 bash`
- Once inside `buildbox` container, run the following commands: `cd /cf && ./register_cf_node.sh`. This command should register a `buildbox` Docker daemon as Codefresh `builder` node 
