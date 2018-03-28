# ANDROID CROSS LIBRARY
This my my experience to solved the cross compiling issue this docker file will help you to adding library openssl, libzip and curl into your toolchain so you can optimize flags when compiling from source code.

### How to use docker:
To build container put Dockerfile into some folder on host OS and run

```sh
docker build -t android/curl .
```

android/curl here is just a name i gave to new created image. The process will consume some time. You can see the list of created images using command: docker images

And we have to run container only to copy output files to host:
	
```sh
docker run -v ~/Android/output:/output --rm=true android/curl
```

Key -v is mounting local ~/Android/output folder to container's /output folder.
