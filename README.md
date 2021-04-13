# docker/maven


This is a Docker image which handles buildkite builds for Data Engineering


## Hadoop Native

The hadoop native libraries were copied from a running CDP cluster using the
following:

```
tar -C /opt/cloudera/parcels/CDH-7.2.7-1.cdh7.2.7.p0.9408337/lib -cjf CDH-7.2.7-1.cdh7.2.7.p0.9408337-hadoop-native.tar.bz2 hadoop/lib/native
```

The resulting tarball was uploaded to the `misc-static` repository in
Artifactory.  The Dockerfile in this repository pulls the libraries from
Artifactory.
