# potential-winner
Terraform AWS EC2 instance, Jupyter notebook and nginx proxy IPv6 subnet + mariadb installed locally.
Jupyter + nginx config derived from 
https://gist.github.com/paparaka/294450b727c2aa5455e7125f695e54ed
https://nedjalkov-ivan-j.medium.com/jupyter-lab-behind-a-nginx-reverse-proxy-the-docker-way-8f8d825a2336

For Demo and for being the cheapest way of spinning up Jupyter purposes only. Don't use this for production:
* Not highly available
* No backups
* Is in a single AZ
* Doesn't use EFS
* Doesn't use CloudFront. 

Based on a t3.nano which has 500MB of memory, this can lead to OOMs when performing a yum install. Added a temporary swapfile to work around this in the userdata.sh.

## Interview Mode
This has as a training exercise mode to see if an engineer can detect why the workspace is broken and what they do about it in a paired programming exercise.  This is set with the break_workspace value in variables.tf:

break_workspace = true

The candidate should be able to login to Jupyter using the provided URL:

[Login to Jupyter using the provided Token](pictures/jupyter_login.png)

They will be presented with a white screen and asked to fix this.

[Login to Jupyter using the provided Token](pictures/jupyter_blank_page.png)

The terraform output is provided which you can provide to the candidate to login:

```
SSH-string = "ssh -i ideal-octo-parakeet.pem -oPort=2020 ec2-user@44.192.104.111"
Time-Date = "2022-05-15T10:05:31Z"
Web-Server-URL = "http://44.192.104.111"
jupyter-token = "<obfuscated>"
```

The line below is what can be used to temporarily fix the problem in conjuction with the information found in [answers.md]

    volume-id = "aws ec2 modify-volume --size=10 --volume-id vol-0fcc1ab1ccc81e6ae --region us-east-1"

