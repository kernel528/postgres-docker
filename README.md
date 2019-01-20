# Postgres docker image
* base image for non-managed services postgres docker containers
* Intent is to maintain current version -1 versions of the database software.
* Maintenance scripts are still under development, and will be found in /scripts folder

### Build example:
```
docker image build -t kernel528/postgres:10.6 -f 10.6/Dockerfile .

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
  * Either way, you should see a report of the currently installed version of postgres.
# source links
* https://www.postgresql.org/download/
