# Prerequisites
- [Docker](https://docs.docker.com/engine/installation/)
- [Docker Compose](https://docs.docker.com/compose/install/)

# How to install
```
$ mvn clean install -f ibm-mq-ssl-example/pom.xml
$ sudo docker-compose -f docker-compose.dev.yml build
```

# How to run
```
$ sudo docker-compose -f docker-compose.dev.yml up -d
$ java -jar ibm-mq-ssl-example/target/ibm-mq-ssl-example-0.0.1-SNAPSHOT.jar
```
