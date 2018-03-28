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
# Author:   Koh Schooley <kschooley@osc.edu>
# Date:     March 2016

# Global Defaults
TIMEOUT_LIMIT="600"
RANGE="-168:00:00"
SYSTEM=$LMOD_SYSTEM_NAME
CMD_REMOVE_EXTRAS="grep -v '^$'"

echo "    -- -- -- -- Usage Summary for $SYSTEM -- -- -- --"
echo

echo "-- Settings"
echo "TIMEOUT_LIMIT = $TIMEOUT_LIMIT"
echo "RELEVANT DATE RANGE = $RANGE"
echo

echo "-- Top Groups by usage ( Sorted by CPU time)"
echo "PHDed = Total proc-hours dedicated to active and completed jobs."
showstats -a -t $RANGE --timeout=$TIMEOUT_LIMIT | head -n 15 | $CMD_REMOVE_EXTRAS
echo

echo "-- Groups sorted by Maximum Expansion Factor (Lower = Better)"
echo "Expansion Factor = (QueuedTime + RunTime) / WallClockLimit"
echo
showstats -a -t $RANGE --timeout=$TIMEOUT_LIMIT | awk 'NR<5{print $0 ;next}{print $0 | "sort -r -k 13n,13 | tac | head"}' | $CMD_REMOVE_EXTRAS
echo

echo "-- Usage Statistics by QoS"
echo
showstats -q -t $RANGE --timeout=$TIMEOUT_LIMIT | $CMD_REMOVE_EXTRAS

echo "-- Least Efficient Users"
echo "Effic = Actual CPU hours / Allocated CPU hours"
echo
showstats -u -t $RANGE --timeout=$TIMEOUT_LIMIT | awk 'NR<5{print $0;next}{print $0 | "sort -r -k 15n,15 | head"}' | $CMD_REMOVE_EXTRAS
echo

echo "-- Longest Average Queue Time by Users"
echo "Queue time includes time spent in various holds"
echo
showstats -u -t $RANGE --timeout=$TIMEOUT_LIMIT | awk 'NR<5{print $0;next}{print $0 | "sort -r -k 14n,14 | tac | head"}' | $CMD_REMOVE_EXTRAS
echo

echo "-- Statistics for Classes of Jobs"
showstats -c -t $RANGE --timeout=$TIMEOUT_LIMIT | $CMD_REMOVE_EXTRAS

echo "-- Non-Job Reservations"
echo
showres | awk '$2 == "User" { print $0 }'
echo

echo "-- Blocked Jobs"
echo "Are any of these forgotten?  Non-runnable?"
showq -b | head -n 20
echo

echo "-- Eligible Jobs, Descending"
showq -i | head -n 20
