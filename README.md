# 2i2c Access Policies for NASA Openscapes Users
This page is a work in progress. It was last updated November 6, 2023 

## Introduction

A key objective of NASA Openscapes is to minimize “the time to science” for researchers. Cloud infrastructure can facilitate shortening this time. We use a 2i2c-managed JupyterHub, which lets us work in the cloud next to NASA Earthdata in AWS US-West-2. The purpose of the JupyterHub is to provide initial, exploratory experiences accessing NASA Earthdata in the cloud. It is not meant to be a long-term solution to support on-going science work or software development. For those users that decide working in the Cloud is advantageous and want to move there, we support a migration from the Hub to their own environment through Coiled.io. 

**Hub Management:** [2i2c](http://2i2c.org/) is a nonprofit that designs, develops, and operates JupyterHubs in the cloud for research and education, including NASA Openscapes. 2i2c ensures that Hubs are cloud-vendor agnostic and are built using open-source software such as JupyterHub and Kubernetes. 

**User Management and Access:** 2i2c manages users through GitHub Teams within the NASA-Openscapes GitHub organization. This requires new users to accept an invitation from NASA-Openscapes. Following that acceptance, the user can then log on to the 2i2c Hub with their Github credentials. Using the NASA Openscapes Hub, the only software requirement to launch the Hub are access to a computer and the internet.

**Hub Location and Right to Replicate:** Our Openscapes JupyterHub is built on top of AWS and is in-region with NASA Earthdata (AWS US-West-2). 2i2c gives users the[ right to replicate](https://2i2c.org/right-to-replicate/) their infrastructure. This means that our Hub could be replicated on GoogleEarthEngine or Microsoft Azure, or ported to another AWS region.

With this setup, we have flexibility to support a diverse range of user needs. The 2i2c Openscapes Hub has been used by the NASA-Openscapes Mentors and other NASA DAAC staff internally as a testing ground for developing cloud tutorials and workflows, but also externally in the research community for workshops like those for science teams and “Hackathons,” a term used here to describe multi-day events with split time for teaching and helping researchers implement concepts into their research projects. 

*This section drew from the ‘Solution’ section of the White Paper entitled, “[The Value of Hosted JupyterHubs in enabling Open NASA Earth Science in the Cloud](https://zenodo.org/records/7667299#.Y_Zxt3bMJPY)” (Nickles, et.al, 2022).*


## Obtaining Access to the NASA Openscapes Hub

Access is controlled by the NASA Openscapes Team, who oversee the management of the Hub and Cloud costs. The first step to gaining access to the NASA Openscapes 2i2c Hub is to request access via [this form](https://forms.gle/sLM9szAYN2mq6SbL9). 

Our JupyterHub users are managed in three GitHub Teams: 

* [Long-term access](https://github.com/orgs/nasa-openscapes-workshops/teams/longtermaccess-2i2c): This access is for NASA Openscapes mentors and team, DAAC staff and others who request a longer-term engagement  
* [NASA Openscapes Champions](https://github.com/orgs/nasa-openscapes-workshops/teams/championsaccess-2i2c): This access is for teams that participate in the NASA Openscapes Champions Program. These teams have access for up to a year as they migrate their workflows to the Cloud. 
* [Workshops and Hack-a-thons](https://github.com/orgs/nasa-openscapes-workshops/teams/workshopaccess-2i2c): This provides short term access of up to 1-month to participants of NASA Earthdata workshops. Participants will be removed at any time and have no expectation of on-going storage in their home directories. 


## Allowable Uses of 2i2c Hub 

Users who join these GitHub teams agree to use the NASA Openscapes Hub only for work on NASA EarthData related activities. Generally, recommended instance size is the smallest instance (1.9GB RAM and up to 3.75 CPUs). 

Run large or parallel jobs over large geographic bounding boxes or over long temporal extents should be cleared with the NASA Openscapes Team by submitting an issue to this repo.   

## Removal From the NASA Openscapes Hub

The NASA Openscapes Hub is a shared, limited resource that incurs real costs. Users are granted access in the terms above and are removed at the end of those limits. Users that haven’t accessed the Hub in more than six months are also removed for security purposes. 

We will do our best to alert users before they lose access to the NASA Openscapes Hub. However, we reserve the right to remove users at any time for any reason. Users that violate the terms of access or incur large Cloud costs without prior permission from the NASA Openscapes Team will be removed immediately.

## Data Storage in the NASA Openscapes Hub

Storing large amounts of data in the cloud can incur significant ongoing costs if not done optimally. We are charged daily for data stored in our Hub. We are developing technical strategies and policies to reduce storage costs that will keep the Openscapes 2i2c Hub a shared resource for us all to use, while also providing reusable strategies for other admins.

The Hub uses an [EC2](https://aws.amazon.com/ec2/) compute instance, with the
`$HOME` directory (`/users/jovyan/` in python images and `/users/rstudio/` in R
images) mounted to [AWS Elastic File System (EFS)](https://aws.amazon.com/efs/)
storage. This drive is really handy because it is persistent across server
restarts and is a great place to store your code. However the `$HOME` directory
should not be used to store data, as it is very expensive, and can also be quite
slow to read from and write to. 

To that end, the Hub provides every user access to two [AWS
S3](https://aws.amazon.com/s3/) buckets - a "scratch" bucket for short-term
storage, and a "persistent" bucket for longer-term storage. AWS S3 buckets are
like online storage containers, accessible through the internet, where you can
store and retrieve files. S3 buckets have fast read/write, and storage costs are
relatively inexpensive compared to storing in your `$HOME` directory. All major
cloud providers provide a similar storage service - S3 is Amazon's version, while 
Google provides "Google Cloud Storage", and Microsoft provides "Azure Blob Storage".

These buckets are accessible only when you are working inside the Hub; you can
access them using the environment variables:

- `$SCRATCH_BUCKET` pointing to `s3://openscapeshub-scratch/[your-username]`
    - Scratch buckets are designed for storage of temporary files, e.g.
      intermediate results. Objects stored in a scratch bucket are removed after
      7 days from their creation.
- `$PERSISTENT_BUCKET` pointing to `s3://openscapeshub-persistent/[your-username]`
    - Persistent buckets are designed for storing data that is consistently used
      throughout the lifetime of a project. There is no automatic purging of
      objects in persistent buckets, so it is the responsibility of the Hub
      admin and/or Hub users to delete objects when they are no longer needed to
      minimize cloud billing costs.

### Using S3 Bucket Storage 

Please see the short tutorial in the Earthdata Cloud Cookbook on [Using S3
Bucket Storage in NASA-Openscapes
Hub](https://nasa-openscapes.github.io/earthdata-cloud-cookbook/how-tos/using-s3-storage.html).

### Data retention and archiving policy

User `$HOME` directories will be retained for six months after their last use.
After a home directory has been idle for six months, it will be [archived to our
"archive" S3 bucket, and removed](#how-to-archive-old-home-directories). If a
user requests their archive back, an admin can restore it for them.

Once a user's home directory archive has been sitting in the archive for an 
additional six months, it will be permanently removed from the archive. After
this it can no longer be retrieved. <!-- TODO make this automatic policy in S3 console -->

In addition to these policies, admins will keep an eye on the 
[Home Directory Usage Dashboard](https://grafana.openscapes.2i2c.cloud/d/bd232539-52d0-4435-8a62-fe637dc822be/home-directory-usage-dashboard?orgId=1)
in Grafana. When a user's home directory increases in size to over 100GB, we
will contact them and work with them to reduce the size of their home directory
- by removing large unnecessary files, and moving the rest to the appropriate S3
bucket (e.g., `$PERSISTENT_BUCKET`).

## The `_shared` directory

[The `_shared` directory](https://infrastructure.2i2c.org/topic/infrastructure/storage-layer/#shared-directories) 
is a place where instructors can put workshop materials
for participants to access. It is mounted as `/home/jovyan/shared`, and is _read
only_ for all users. For those with admin access to the Hub, it is also mounted
as a writeable directory as `/home/jovyan/shared-readwrite`.

This directory will follow the same policies as users' home directories: after 
six months, contents will be archived to the "archive" S3 bucket (more below). 
After an additional six months, the archive will be deleted.

### How to archive old home directories (admin)

To start, you will need to be an admin of the Openscapes Jupyterhub so that
the `allusers` directory is mounted in your home directory. This will contain
all users' home directories, and you will have full read-write access.

#### Finding large `$HOME` directories

Look at the [Home Directory Usage
Dashboard](https://grafana.openscapes.2i2c.cloud/d/bd232539-52d0-4435-8a62-fe637dc822be/home-directory-usage-dashboard?orgId=1)
in Grafana to see the directories that haven't been used in a long time and/or
are very large.

You can also view and sort users' directories by size in the Hub with the 
following command, though this takes a while because it has to summarize _a lot_ 
of files and directories. This will show the 30 largest home directories:

```
du -h --max-depth=1 /home/jovyan/allusers/ | sort -h -r | head -n 30
```

#### Authenticate with S3 archive bucket

We have created an AWS IAM user called `archive-homedirs` with appropriate 
permissions to write to the `openscapeshub-prod-homedirs-archive` bucket. 
Get access keys for this user from the AWS console, and use these keys to 
authenticate in the Hub:

In the terminal, type: 

```
awsv2 configure
```

Enter the access key and secret key at the prompts, and set default region to 
`us-west-2`.

You will also need to temporarily unset some AWS environment variables that have 
been configured to authenticate with NASA S3 storage. (These will be reset the next 
time you log in):

```
unset AWS_ROLE_ARN
unset AWS_WEB_IDENTITY_TOKEN_FILE
```

Test to make sure you can access the archive bucket:

```
# test s3 access:
awsv2 s3 ls s3://openscapeshub-prod-homedirs-archive/archives/
touch test123.txt
awsv2 s3 mv test123.txt s3://openscapeshub-prod-homedirs-archive/archives/
awsv2 s3 rm s3://openscapeshub-prod-homedirs-archive/archives/test123.txt
```

#### Setting up and running the archive script

We use a [python script](scripts/archive-home-dirs.py), [developed by
@yuvipanda](https://github.com/2i2c-org/features/issues/32), that reproducibly
archives a list of users' directories into a specified S3 bucket.

Copy the script into your home directory in the Hub, or even better, clone this
repo.

In the Hub as of 2024-05-17, a couple of dependencies for the script are
missing; you can install them before running the script:

```
pip install escapism

# I had solver errors with pigz so needed to use the classic solver. 
# Also, the installation of pigz required a machine with >= 3.7GB memory
conda install conda-forge::pigz --solver classic
```

Create a text file, with one username per line, of users' home directories you
would like to archive to s3. It will look like:

```
username1
username2
# etc...
```

Finally, run the script from the terminal, changing the parameter values as required:

```
python3 archive-home-dirs.py \
    --archive-name="archive-$(date +'%Y-%m-%d')" \
    --basedir=/home/jovyan/allusers/ \
    --bucket-name=openscapeshub-prod-homedirs-archive \
    --object-prefix="archives/" \
    --usernames-file=users-to-archive.txt \
    --temp-path=/home/jovyan/archive-staging/
```

Omitted in the above example, but available to use, is the `--delete` flag, 
which will delete the users' home directory once the archive is completed.

If you don't use the `--delete` flag, first verify that the archive was successfully
completed and then remove the user's home directory manually.

By default, archives (`.tar.gz`) are created in your `/tmp` directory before
upload to the S3 bucket. The `/tmp` directory is cleared out when you shut down
the Hub. However, `/tmp` has limited space (80GB shared by up to four users on a
single node), so if you are archiving many large directories, you will likely
need to specify a location in your `$HOME` directory by passing a path to the
`--temp-path` argument. The script will endeavour to clean up after itself and 
remove the `tar.gz` file after uploading, but double check that directory
when you are finished or you may have copies of all of the other user
directories in your own `$HOME`!
