To build container put Dockerfile into some folder on host OS and run
	
docker build -t android/curl .

android/curl here is just a name i gave to new created image. The process will consume some time. You can see the list of created images using command: docker images

And we have to run container only to copy output files to host:
	
docker run -v ~/Android/output:/output --rm=true android/curl

Key -v is mounting local ~/Android/output folder to container's /output folder.
