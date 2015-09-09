# This is a script which works for me, based on the previous script submitted here and then further tailored to suit my preferences. Use at your own risk etc.

#!/bin/sh

# Configuration, should be all set up.
remoteuser="minhaz3"
remoteserver="beef.whatbox.ca"
sourcefolder="/home/minhaz3/finished/"
targetfolder="/data/files/finished/TVShows"
templog=`mktemp -t templog.XXXX`
templogfind=`mktemp -t templogfind.XXXX`
syncvar="-avzL --partial --info=progress2 -e ssh --log-file=$templog --bwlimit=4096"

# Except this part.
mailto="seedboxplex@gmail.com"
mailfrom="seedboxplex@gmail.com"

tempmail=".tempmail"

# Mail out an error report when called by a general signal trap
    cleanfail () {
    printf "To: $mailto\nFrom: $mailfrom\nSubject: Whatbox transfers - From `date +%d-%m-%Y-%H:%M:%S`\n\nWhatbox synchronisation has failed due to unspecified signal error.\n\n" > $tempmail
    cat $tempmail | msmtp -a default $mailto
    rm $tempmail
    rm $templog
    rm $templogfind
    exit 1
    }
    
# Mail out an error report when called by an rsync trap.
    cleanfail_rsync () {
    printf "To: $mailto\nFrom: $mailfrom\nSubject: Whatbox transfers - From `date +%d-%m-%Y-%H:%M:%S`\n\nWhatbox rsync has failed. Rsync log attached.\n\n" > $tempmail
    cat $templog >> $tempmail
    cat $tempmail | msmtp -a default $mailto
    rm $tempmail
    rm $templog
    rm $templogfind
    exit 1
    }

# Mail out an error report when called by a find trap.
    cleanfail_find () {
    printf "To: $mailto\nFrom: $mailfrom\nSubject: Whatbox transfers - From `date +%d-%m-%Y-%H:%M:%S`\n\nWhatbox symbolic link cleanup has failed. Find process log attached.\n\n" > $tempmail
    cat $templogfind >> $tempmail
    cat $tempmail | msmtp -a default $mailto
    rm $tempmail
    rm $templog
    rm $templogfind
    exit 1
    }

# Mail out an error report when called by an existing instance of rsync already running trap.
    cleanfail_rsync_active () {
    printf "To: $mailto\nFrom: $mailfrom\nSubject: Whatbox transfers - From `date +%d-%m-%Y-%H:%M:%S`\n\nrsync process is still active. Large download may still be in progress.\n\n" > $tempmail
    #cat $tempmail | msmtp -a default $mailto
    rm $tempmail
    rm $templog
    rm $templogfind
    exit 1
    }

# Check if rsync is already running. If so, exit with an email notification reporting transfers still in progress.
pgrep rsync >/dev/null 2>&1 && cleanfail_rsync_active

# Touch timestamp file to prevent deleting links that are created while rsync is running
ssh $remoteuser@$remoteserver touch $sourcefolder/.rsync-timestamp

# Trap error signals
trap cleanfail 1 2 3 15

# If all is well so far, commence the rsync automated download from the seedbox. Run it twice in case if more files came in during the first rsync process.
stdbuf -i0 -e0 -o0 rsync $syncvar $remoteuser@$remoteserver:$sourcefolder $targetfolder | grep % | awk '{ print $3; }' > /plex/rsyncprog
stdbuf -i0 -e0 -o0 rsync $syncvar $remoteuser@$remoteserver:$sourcefolder $targetfolder | grep % | awk '{ print $3; }' > /plex/rsyncprog
chown -R plex:plex $targetfolder

# Trap any errors, log and email them if rsync does not terminate with a successful exit value (0). Otherwise, continue to delete symlinks now that we're done with them. If the deletion of symlinks fails, this error is also trapped, logged and emailed.
if [ $? != 0 ]; then
    cleanfail_rsync
else
    printf "\n\nTransfer successful. Deleted following symbolic links:\n" > $templogfind
    ssh $remoteuser@$remoteserver find $sourcefolder \! -newer $sourcefolder/.rsync-timestamp -type l -delete -print >> $templogfind
    if [ $? != 0 ]; then
        cleanfail_find
    else
    :
    fi
fi

# Mail out report for a successful transfer. List a trimmed down version of rsync log file, trimming down to parent folders and otherwise single files. If you prefer the full rsync log file, just uncomment the line after the following printf and comment out the cut line after it.
printf "To: $mailto\nFrom: $mailfrom\nSubject: Transfers - From `date +%d-%m-%Y-%H:%M:%S`\n\nDownloaded File List:\n" > $tempmail
# cat $templog >> $tempmail
# I believe this cut line is simpler than using awk with print arguments. This series of commands looks for the "+" in the rsync log file and removes everything up to and including the last "+". Then grep filters out the first supposed file in the list which is just "./". After this, sed takes over and strips all the subdirectories from the first "/" encountered after the parent directory name(s). All that's then left to do is to wipe out all the duplicate lines so that all that remains is each parent directory without any duplication and unique files. It essentially creates the same list as what's in the /finished/ folder but at least it's from a confirmed rsync log file rather than working on assumptions, just to keep the script robust.
cut -s -d + -f 8 $templog | grep -v "\./" | sed 's%/.*%%' | uniq >> $tempmail

# Add the symlink deletion results
cat $templogfind >> $tempmail
#echo "TEMPLOGFIND: `tail -1 $templogfind`"
deleted=`tail -1 $templogfind`
if [ "$deleted" = "Transfer successful. Deleted following symbolic links:" ]; 
then
    exit 0
fi

# Add local disk stats to email report
printf "\n`hostname`/mnt/sdc1 usage:\n" >> $tempmail; df -h | grep Filesystem >> $tempmail && df -h | grep sdc1 >> $tempmail

# Email the compiled report    
cat $tempmail | msmtp -a default $mailto

rm $templog
rm $templogfind
rm $tempmail
exit 0
