mc-control
==========

Allows you to easily control a Minecraft server entirely from the command line.

At the moment, the script must be named "mc" and be somewhere in your path (like /usr/bin/mc). The script sometimes calls itself recursively, which I plan to remove in the future.


Requirements
------------

- At least one of the following:
    - GNU `Screen`
    - [detachtty]
- Java (minecraft.net recommends Sun's JVM, this script doesn't care)


Optional
--------

- `zip` (to make backups)
- [s3cmd] (to back up to Amazon S3)
- [gsutil] (to back up to Google Cloud Storage)


Configuration
-------------

- `base_dir`
    - The directory you want Minecraft to store all its files in. This is usually your home directory, but can be anywhere you have write access to.
- `java_path`
    - The absolute location of the Java executable you want Minecraft to use.
- `minecraft_path`
    - The absolute location of your Minecraft jarfile.
- `bg_app`
    - The application you would like to run Minecraft through. This can be either "screen" or "detachtty".
- `memory`
    - How much memory the Minecraft server should be allowed. This should be in Java's notation (512M = 512 MB, 2G = 2 GB, etc).
- `update_url`
    - The URL to pull updates from. The default pulls them from CraftBukkit's servers. To run a vanilla Minecraft server, change this to `https://s3.amazonaws.com/MinecraftDownload/launcher/minecraft_server.jar`.
- `beta_update_url`
    - Similar to `update_url`. If you aren't using a version that makes multiple release versions available, ignore this.
- `dev_update_url`
    - Similar to `beta_update_url`
- `s3_bucket`
    - The name of your Amazon S3 bucket to save backups to when running `mc backup`. It's up to you to configure `s3cmd` properly. If you don't want to sane backups to Amazon S3, leave this blank.
- `gs_bucket`
    - Similar to S3 backups, but sends your backups to Google Cloud Storage. Note that this is _different_ from Google Drive.
- `opts`
    - Extra options to pass to Java, as a plain string.


Commands
--------

- `mc start`
    - Starts the server and immediately backgrounds it. The process will hang until Java has started, so you can run `mc join` immediately afterwards.
- `mc join`
    - Attaches the server console to your active window. Use C-a-d to detach when using `screen`, or ^\ to detach when using `detachtty`.
- `mc run`
    - Runs the Minecraft server in the foreground console window. Mostly used internally, but also useful for debugging Java errors.
- `mc watch`
    - Monitors the console output without attaching. Uses `tail --follow`. Plain old ^C will get you out.
- `mc tail`
    - Prints the last 20 lines of `server.log`. Uses `tail`. Similar to `mc watch`, but exits immediately.
- `mc stop`
    - Stops the server (un!)gracefully. This should eventually send a real "stop" command to the server console, but instead just uses `kill`.
- `mc kill`
    - Kills the server immediately, using `kill -9`.
- `mc restart`
    - Stops the server gracefully, then starts it back up.
- `mc update`
    - Updates to the latest Recommended build
- `mc update beta`
    - Updates to the latest Beta build
- `mc update dev`
    - Updates to the latest Development build
- `mc backup`
    - Zips a copy of your world directory, and saves it to $base_dir/backups. Runs an S3 or GS backup if set up.
- `mc status`
    - Returns the server's status (either "running" or "not running")


[detachtty]: ftp://ftp.linux.org.uk/pub/lisp/detachtty/
[s3cmd]: http://s3tools.org/download
[gsutil]: https://developers.google.com/storage/docs/gsutil_install