#!/bin/bash
# /usr/bin/mc
: '
/**
 *
 * Minecraft control script.
 * This script MUST be in your path!
 * All paths should be absolute.
 *
 * @author Dan Hlavenka
 * @version 2012-12-18 01:22 CST
 *
 */

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!    Requires `screen` to work at all.     !!
!! Requires `s3cmd` to back up to Amazon S3 !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
'

base_dir="/home/dan/mc"
java_path="/usr/bin/java"
minecraft_path="/home/dan/mc/bukkit.jar"
memory="8G"
update_url="http://cbukk.it/craftbukkit.jar"
beta_update_url="http://cbukk.it/craftbukkit-beta.jar"
dev_update_url="http://cbukk.it/craftbukkit-dev.jar"
s3_bucket="" # Set to "" to bypass S3 backups
s3_reduced_redundancy=true
opts="-server -Djava.awt.headless=true" # Extra options to pass to Java

cd $base_dir

start(){
	if [ "$(status)" = "Running" ]; then
		echo "ERROR: Already running"
	else
		screen -dmS mc mc run
		while [ "$(status)" != "Running" ]; do
			[ ] # Wait for Java to start
		done
		echo "Server started."
	fi
}

stop(){
	if [ "$(status)" = "Running" ]; then
		screen -S mc -X eval "stuff 'stop'\015"
		while [ "$(status)" = "Running" ]; do
			[ ] # Wait for Java to terminate
		done
		echo "Server stopped"
	else
		echo "ERROR: Not running"
	fi
}

status(){
	if screen -list | grep -q "mc"; then
		echo "Running"
	else
		echo "Not running"
	fi
}

restart(){
	if [ "$(status)" = "Running" ]; then
		echo $(stop)
	fi
	echo $(start)
}

case "$1" in
	start)
		echo $(start)
		;;
	run)
		$java_path -Xmx$memory -Xms512M $opts -jar $minecraft_path
		;;
	join)
		if [ "$(status)" = "Running" ]; then
			screen -dr mc
		else
			echo "ERROR: Not running"
		fi
		;;
	watch)
		tail -f $base_dir/server.log
		;;
	tail)
		lines=20
		if [ "$2" ]; then
			lines="$2"
		fi
		tail -n $lines $base_dir/server.log
		;;
	stop)
		echo $(stop)
		;;
	kill)
		if [ "$(status)" = "Running" ]; then
			echo "Killing server..."
			screen -X -S mc quit
			while [ "$(status)" = "Running" ]; do
				[ ] # Wait for Java to terminate
			done
			echo "Server stopped"
		else
			echo "ERROR: Not running"
		fi
		;;
	restart)
		echo $(restart)
		;;
	backup)
		screen -S mc -X eval "stuff 'broadcast Starting backup...'\015"
		screen -S mc -X eval "stuff 'save-off'\015"
		screen -S mc -X eval "stuff 'save-all'\015"
		archive=$base_dir/backups/`date "+%Y-%m-%d-%H-%M"`.zip
		zip -q $archive -r world
		screen -S mc -X eval "stuff 'save-on'\015"
		if [ $s3_bucket ]; then
			header=""
			if [ $s3_reduced_redundancy == true ]; then
				header="--add-header=x-amz-storage-class:REDUCED_REDUNDANCY"
			fi
			s3cmd put $header $archive s3://$s3_bucket/backups/
		fi
		screen -S mc -X eval "stuff 'broadcast Backup complete!'\015"
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
		if [ "$(status)" = "Running" ]; then
			echo $(restart)
		fi
		echo "Update complete"
		;;
	status)
		echo $(status)
		;;
	*)
		echo "Status:" $(status)
		echo "Options:"
		echo "       mc start : Starts the server"
		echo "        mc join : Brings the server console to your active window"
		echo "       mc watch : Monitors the console output without attaching"
		echo "   mc tail n=20 : Displays the last n lines of the server log"
		echo "        mc stop : Stops the server gracefully"
		echo "        mc kill : Kills the server immediately"
		echo "     mc restart : Stops the server gracefully, then restarts"
		echo "      mc update : Updates to the latest Recommended build"
		echo " mc update beta : Updates to the latest Beta build"
		echo "  mc update dev : Updates to the latest Development build"
		echo "      mc backup : Saves a copy of the world to $base_dir/backups"
		echo "      mc status : Returns the server status (running / not running)"
		;;
esac
