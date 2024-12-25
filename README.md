[![Build Status](http://drone.kernelsanders.biz:8080/api/badges/kernel528/postgres-docker/status.svg?ref=refs/heads/main)](http://drone.kernelsanders.biz:8080/kernel528/postgres-docker)
[![Latest Version](https://img.shields.io/github/v/tag/kernel528/postgres-docker)](https://github.com/kernel528/postgres-docker/releases/latest)
[![Docker Pulls](https://img.shields.io/docker/pulls/kernel528/postgres)](https://hub.docker.com/r/kernel528/postgres)
[![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/kernel528/postgres)](https://hub.docker.com/r/kernel528/postgres)
[![Docker Image Version (latest by date)](https://img.shields.io/docker/v/kernel528/postgres)](https://hub.docker.com/r/kernel528/postgres)

# Postgres docker image
* Based on:  [Postgres Official Docker - Alpine](https://github.com/docker-library/postgres/tree/master/16/alpine3.20)

### Build example:
```
docker image build -t kernel528/postgres:15 -f 15/Dockerfile .

```

### Runtime example:
```
docker run -it -d -p 5432:5432 --name postgres-local -e POSTGRES_PASSWORD=password --hostname=postgres-local -d kernel528/postgres:10.6
```

# testing example:
* once the container is running, there's two ways to test.

  * within the container
    Connect via
    ```
    docker exec -it <container_name> bash
       su postgres
       psql
       select VERSION();
       \q           
       exit         # su
       exit         # docker container
    ```
  * exterior to the container
    If you have psql installed locally, or in a different container
    ```
    docker container run -it --rm --name psql-client --hostname psql-clien kernel528/postgres:10.6 psql -h 192.168.1.110 -U postgres
    <password>
    select VERSION();
    \q           
    ```
# source links
* https://www.postgresql.org/download/
