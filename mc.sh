#! /bin/bash

: '
/**
 *
 * Minecraft control script.
 * Suggested name: /usr/bin/mc
 * This script MUST be in your path!
 * All paths should be absolute.
 *
 * @author Dan Hlavenka
 * @version 2012-09-06 20:02 CST
 *
 */

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! Requires `detachtty` or `screen` to work at all. !!
!!     Requires `s3cmd` to back up to Amazon S3     !!
!!   Requires `gsutil` to back up to Google Cloud   !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
'

base_dir="/home/dan/mc"
java_path="/java/bin/java"
minecraft_path="/home/dan/mc/bukkit.jar"
bg_app="screen" # Either "screen" or "detachtty"
memory="1G"
update_url="http://cbukk.it/craftbukkit.jar"
beta_update_url="http://cbukk.it/craftbukkit-beta.jar"
dev_update_url="http://cbukk.it/craftbukkit-dev.jar"
s3_bucket="" # Set to "" to bypass S3 backups
gs_bucket="" # Set to "" to bypass GS backups
opts="" # Extra options to pass to Java

cd $base_dir

case "$1" in
    start)
		if [ "`mc status`" = "Running" ]; then
			echo "ERROR: Already running"
		else
			echo "Starting server..."
			if [ $bg_app = "screen" ]; then
				screen -dmS mc mc run
			else
				detachtty $base_dir/mc mc run
			fi
			while [ "`mc status`" != "Running" ]; do
				[ ] # Wait for Java to start
			done
			echo "Server started."
		fi
		;;
	run)
		$java_path -Xmx$memory -Xms$memory $opts -jar $minecraft_path
		;;
	join)
		if [ "`mc status`" = "Running" ]; then
			if [ $bg_app = "screen" ]; then
				screen -r mc
			else
				attachtty $base_dir/mc
			fi
		else
			echo "ERROR: Not running"
		fi
		;;
	watch)
		tail -f $base_dir/server.log
		;;
	stop)
		if [ "`mc status`" = "Running" ]; then
			echo "Stopping server..."
			kill `pidof java` # Not as graceful as it should be
			while [ "`mc status`" = "Running" ]; do
				[ ] # Wait for Java to terminate
			done
			echo "Server stopped"
		else
			echo "ERROR: Not running"
		fi
		;;
	kill)
		if [ "`mc status`" = "Running" ]; then
			echo "Killing server..."
			kill -9 `pidof java`
			while [ "`mc status`" = "Running" ]; do
				[ ] # Wait for Java to terminate
			done
			echo "Server stopped"
		else
			echo "ERROR: Not running"
		fi
		;;
	restart)
		if [ "`mc status`" = "Running" ]; then
			mc stop
		fi
		mc start
		;;
	backup)
		archive=$base_dir/backups/`date "+%Y-%m-%d-%H-%M"`.zip
		zip -q $archive -r world
		if [ $s3_bucket ]; then
			s3cmd put --add-header=x-amz-storage-class:REDUCED_REDUNDANCY $archive s3://$s3_bucket/backups/
		fi
		if [ $gs_bucket ]; then
			gsutil cp -a public-read $archive gs://$gs_bucket/backups/
		fi
		echo "Backup complete"
		;;
	update)
		rm $minecraft_path
		case "$2" in
			beta)
				wget -O $minecraft_path $beta_update_url
				;;
			dev)
				wget -O $minecraft_path $dev_update_url
				;;
			*)
				wget -O $minecraft_path $update_url
				;;
		esac
		chmod +x $minecraft_path
		if [ "`mc status`" = "Running" ]; then
			mc restart
		fi
		echo "Update complete"
		;;
	status)
		if [ "`pidof -s java`" ]; then
			echo "Running"
		else
			echo "Not running"
		fi
		;;
	*)
		echo "Status:" `mc status`
		echo "Options:"
		echo "       mc start : Starts the server"
		echo "        mc join : Brings the server console to your active window"
		echo "       mc watch : Monitors the console output without attaching"
		echo "        mc stop : Stops the server (un!)gracefully"
		echo "        mc kill : Kills the server immediately"
		echo "     mc restart : Stops the server gracefully, then restarts"
		echo "      mc update : Updates to the latest Recommended build"
		echo " mc update beta : Updates to the latest Beta build"
		echo "  mc update dev : Updates to the latest Development build"
		echo "      mc backup : Saves a copy of the world to ~/backups"
		echo "      mc status : Returns the server status ('running' / 'not running')"
		;;
esac