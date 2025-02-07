# MDE Offline Update Docker

The MDE Offline Dockerfile provides a basic docker container that hosts the Microsoft Offline Update repository for MDE on Linux and Mac.

## What this does

* This container _does_ a one time fetch of the Security Intelligence Updates for MDE from Microsoft.
* This container _does_ pull down updates for MDE on Mac & Linux
* This container _does_ provides a web server that exposes the Security Intelligence Updates properly for your environment
* This container _does_ provide a sample JSON file content to configure your Linux Servers to use it for offline updates

## What this doesn't do

* This container _does not_ perform regular pulls of the Security Intelligence Updates.
* This container _does not_ mirror the Windows Updates

## Building & Running the Conatiner

Use the following commands to build and start the container

```bash
docker build -t [YOUR BUILD TAG HERE] .
docker run -p [YOUR DESIRED PORT]:80 -d [YOUR BUILD TAG HERE]
```

After building the container you can access the default web site to check the manifest details and manually download the security intelligence update zip files for both Mac and Linux.
