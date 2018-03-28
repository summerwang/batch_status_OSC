#!/bin/bash
##############################################################################
# batch_status.sh
#
# The HPC Client Services group has a weekly operational meeting on Mondays.
# During this meeting the status of the batch system is discussed and reviewed.
#
# This script is intended to be run as a cronjob, run weekly on Monday mornings.
# The output is saved, and used for the weekly operational meeting.
#
# The output includes various statistics on system utilization.
#
# Author:       Koh Schooley <kschooley@osc.edu>
# Modified by:  Summer Wang <xwang@osc.edu>
# Date:         June 2016

# Global Defaults
TIMEOUT_LIMIT="600"
RANGE="-192:00:00"
SYSTEM=$LMOD_SYSTEM_NAME
CMD_REMOVE_EXTRAS="grep -v '^$'"

echo "-- Usage Statistics by QoS"
showstats -q -t $RANGE --timeout=$TIMEOUT_LIMIT | $CMD_REMOVE_EXTRAS
echo

echo "-- Blocked Jobs"
echo "Are any of these forgotten?  Non-runnable?"
showq -b | grep -v -E 'blocked|jobs|JOBID|^$' |sort -r -k1,2 |awk '{ c[$2]++; t[$2]=$7" "$8" "$9" "$10} END {  print "Job Count,", "User,", "Oldest Queue Time";for (i in c) print c[i],",", i,",", t[i]}'|column -t -s ','
echo

echo "-- Eligible Jobs, Sort by Queue Time"
showq -i |awk 'NR<5{print $0;next}{print $0 | "sort -r -k 10n,10 | tac |head -20 "}' | grep -v '^$'
echo

