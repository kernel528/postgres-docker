[![Build Status](http://drone.kernelsanders.biz/api/badges/kernel528/postgres-docker/status.svg)](http://drone.kernelsanders.biz/kernel528/postgres-docker)
# Postgres docker image
* Based on:  https://github.com/docker-library/postgres/blob/cc305ee1c59d93ac1808108edda6556b879374a4/10/alpine/Dockerfile

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
