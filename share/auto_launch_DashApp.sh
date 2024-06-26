#!/bin/bash
# This script is based on the jupyter notebook script from the NREL HPC team.
# It has been modified to launch a Dash app for the WEIS-Visualization project.

# run by passing the sbatch_DashApp.sh script as an argument on an Eagle login node

# exit when a bash command fails
set -e

unset XDF_RUNTIME_DIR

RES=$(sbatch $1)

jobid=${RES##* }

tries=1
wait=1
echo "Checking job status.."
while :
do
  	status=$(scontrol show job $jobid | grep JobState | awk '{print $1}' | awk -F= '{print $2}')
        if [ $status == "RUNNING" ]
        then
            	echo "job is running!"
                echo "getting dash app information, hang tight.."
                while :
                do
                  	if [ ! -f slurm-$jobid.out ]
                        then
                            	echo "waiting for slurm output to be written"
                                let "wait+=1"
                                sleep 1s
                        elif [ $wait -gt 120 ]
                        then
                            	echo "timed out waiting for output from job."
                                echo "check to make sure job didn't fail"
                                echo "killing the slurm job"
                                scancel $jobid
                                exit 0
                        else
                            	check=$(cat slurm-$jobid.out | grep http://0.0.0.0:8050/ | wc -l)
                                if [ $check -gt 0 ]
                                then
                                    	echo "okay, now run the follwing on your local machine:"
                                        echo $(cat slurm-$jobid.out | grep ssh)
                                        echo "then, navigate to the following on your local browser:"
                                        echo $(cat slurm-$jobid.out | grep http://0.0.0.0:8050/ | head -1 | awk {'print $5'})
                                        exit 0
                                else
                                    	let "wait+=1"
                                        sleep 1s
                                fi
                        fi
                done
                exit 0
        elif [ $tries -gt 120 ]
        then
                echo "timeout.. terminating job."
                scancel $jobid
                exit 0
        else
            	echo "job still pending.."
                sleep 10s
        fi
	((tries++))
done
