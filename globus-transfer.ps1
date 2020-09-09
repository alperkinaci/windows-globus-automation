#Set source endpoint (i.e. personal endpoing on the local server)
$source_ep='Full-ID-string-of-personal-endpoint'

#Set destination endpoint (i.e. Quest shared endpoint)
$dest_ep='Full-ID-string-of-shared'

#Start the transfer with Globus and record the task ID for this transfer.
#Both endpoint folders are the exact access paths for the endpoint.
#All the files/folders under the source path are recursively transfered to destination.
$task_id= globus transfer --checksum-algorithm MD5 --verify-checksum ${source_ep}:\ ${dest_ep}:/ --jmespath 'task_id' --format=UNIX --recursive

#If your "outgoing" foder is a subfolder of your personal endpoint path then
#use the following instead:
# $task_id= globus transfer --checksum-algorithm MD5 --verify-checksum ${source_ep}:\outgoing ${dest_ep}:/ --jmespath 'task_id' --format=UNIX --recursive

#Check the status of the transfer after 5 minutes
$transfer_status= globus task wait --timeout 300 --format json "$task_id"

#Continue to check the status until the transfer status reports success
while("$transfer_status" -notmatch "\bSUCCEEDED\b") {
    $transfer_status= globus task wait --timeout 300 --format json "$task_id";
    }

#Deactivate conda environment
conda deactivate
