Purpose - Trigger lambda in remote environment and extract logs for perf readings.

- step 1 => cd ~/Desktop/ & download this repo and cd to the directory
- step 2 => edit the HOME_DIR to your pwd where the repo downloaded
- step 3 => create a file and add programettic access to invoke lambda on aws qa where the code is
```sh
girishmahajan@PNQ-GMAHAJAN ~ % ls -l ~/.aws_creds_qauattraces02 
-rwxr-xr-x  1 girishmahajan  staff  1124 Oct  3 10:39 /Users/girishmahajan/.aws_creds_qauattraces02
girishmahajan@PNQ-GMAHAJAN ~ % cat ~/.aws_creds_qauattraces02
#! /bin/bash

# creds that allowed to access s3 / lambda
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_SESSION_TOKEN=

# creds that allowed to verify lambda
export ACCESS_KEY_LAMBDA_PAYLOAD=
export SECRET_KEY_LAMBDA_PAYLOAD=

```
- step 4 => override a file to a specific environment that script uses (skip this for qa)
```sh
$ cat Desktop/DEV-111402/.env.sh 
#! /bin/bash

S3_BUCKET_NAME=""
LAMBDA_FUNCTION_NAME=""
AWS_REGION=""
```
- step 5 => - to run => (it shall invoke 20 lambda that reads 20 s3 files (total volume of data it uses on s3 side is 9272.73 GiB) 

```sh
./invoke.sh debug >> logs/console.log
```
##### step 6 - create a zip of current directory and share it to me. 

