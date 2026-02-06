#!/bin/bash
# Linux bash script that will help adding or removing Session community moderator/s
# Usage:
# "-a" switch to add moderator permission
# "-d" to delete moderator permission
#
# "-h" for hidden moderator
# "-v" for visible moderator (crowned)
# Example: ./thisscript -a -h (add hidden)
# If no switch is added, script will prompt
#
# This script on each run can also help maintain defined list of session IDs as moderators, reverting removal actions mods/admins done via Session GUI. In order to do this...
# add Session IDs of mods inside a file defined under variable "modsids" below. Single line, space separated (blinded or unblinded IDs)...
# and please verify "sogs --rooms ..." command below that it is adding these mods into a correct community with correct permission (hidden/visible/--admin)
#
# Script is also temporarily renaming profanity blocklist because if the list is long like 1000 lines, SOGS may fail starting
#
#set -exu

profanityfile="/var/lib/session-open-group-server/profanity-block-list.txt"
modsids="/var/lib/session-open-group-server/session-moderators-list-space-separated.txt" # list of mods session ids separated by space, to be added as global mods to all rooms without further asking
defaultcommunity="abcde" # mention the community token (alphanumeric characters only) found in the community URL before ?public_key part

# If script is not run with parameter (full blinded ID), ask user input:
echo "----- ABOUT: Script to add or remove Session ID as a moderator -----"
read -r -p "What kind of Session ID? Blinded full Session ID 15... (bf) or blinded partial ID i.e. 15f4%8f4d (bp) or unblinded full regular ID 05... (uf)? (bf, bp or uf): " idtype

# If unblinded full, discover blinded
if [[ "$idtype" == uf ]]; then
read -r -p "Input full unblinded ID:" ids
# turn it into blinded, since i believe this is what SOGS database is using:
#this produces wrong blinded id ending characters and preventing moderating menu to appear: 
#dir="$(pwd)";cd /var/lib/session-open-group-server && sudo su -s /usr/bin/python3 -c 'import sogs.crypto; print(sogs.crypto.compute_blinded_abs_id("'$ids'"))' > /tmp/blid && ids="$(cat /tmp/blid|grep .)";cd "$dir"
#this is correct:
dir="$(pwd)";cd /var/lib/session-open-group-server && sudo su -s /usr/bin/python3 -c 'import sogs.crypto; abs_id = sogs.crypto.compute_blinded_abs_id("'$ids'"); neg_abs_id = sogs.crypto.blinded_neg(abs_id); print(neg_abs_id)' > /tmp/blid && ids="$(cat /tmp/blid|grep .)";cd "$dir"
fi

# Blinded full
if [[ "$idtype" == bf ]]; then read -r -p "Input full blinded ID:" ids; fi

# Blinded partial to full blinded
if [[ "$idtype" == bp ]]; then
read -r -p "Input first and last 4 characters of an unwanted Session ID. It is displayed next to their nickname in Session. Separate two parts by percent character. (Example input: 15f4%8f4d): " id_incomplete
id=$(sqlite3 /var/lib/session-open-group-server/sogs.db "SELECT DISTINCT session_id FROM message_details WHERE session_id LIKE '$id_incomplete';")
for i in 1 2 3 4 5; do ids=$(sqlite3 'file:/var/lib/session-open-group-server/sogs.db?immutable=1' "SELECT DISTINCT session_id FROM message_details WHERE session_id LIKE '$id_incomplete';"|head -n 1) && [ ${#ids} -eq 66 ] && echo "Success selecting ID \"$ids\"" && break || echo "Failure selecting ID \"$ids\"" && sleep 0.1; done
fi

# Decide about community name (token), listing communities:
for i in 1 2 3 4 5; do /usr/bin/sqlite3 /var/lib/session-open-group-server/sogs.db "select token from rooms;" && break || echo "Failure" 1>/dev/null && sleep 0.1; done
echo -e "\nglobal"
read -r -p "Community name based on above output (empty=$defaultcommunity):" comname;if [[ "$comname" == "" ]]; then comname="$defaultcommunity";fi

# Decide about moderator action (add or delete mod)
if [[ "$*" != *"-a"* ]] && [[ "$*" != *"-d"* ]]; then read -r -p "Type add or delete, to select moderator action (empty=add):" action; elif [[ "$*" == *"-a"* ]]; then action=add; elif [[ "$*" == *"-d"* ]]; then action=delete; fi
if [[ "$action" == "" ]]; then action=add; fi
# Exit if one is trying to add ID which is already listed in mods list file
if [[ "$action" == "add" ]] && [[ "$(cat $modsids)" == *"$ids"* ]]; then echo "I think that the modsids file ($modsids) already contains that blinded Session ID ($ids)." && exit; fi

# Decide about moderator type (hidden or visible)
if [[ "$*" != *"-h"* && "$*" != *"-v"* ]]; then read -r -p "Type hidden or visible, to select moderator type (empty=hidden):" type; elif [[ "$*" == *"-h"* ]]; then type=hidden; elif [[ "$*" == *"-v"* ]]; then type=visible; fi
if [[ "$type" == "" ]]; then type=hidden; fi

# Action (if correct values was input)
if [[ "$comname" == global ]]; then
cp -fp "$profanityfile" "$profanityfile"_"$(date --rfc-3339=date)" # backup blocklist
> "$profanityfile" # empty blocklist (to significantly speedup next sogs command in case of longer blocklist file)
sogs --rooms + --"$action"-moderator "$ids" --"$type";
if [[ "$action" == "delete" ]]; then
sogs --rooms + --delete-moderators "$ids" --admin --hidden
echo "Tried to delete them from admins (all rooms, hidden) in case they was not just a mod."
fi
cp -fp "$profanityfile"_"$(date --rfc-3339=date)" "$profanityfile" # restore blocklist

elif [[ "$action" == add || "$action" == delete ]] && [[ "$type" == hidden || "$type" == visible ]]; then 
cp -fp "$profanityfile" "$profanityfile"_"$(date --rfc-3339=date)" # backup blocklist
> "$profanityfile" # empty blocklist (to significantly speedup next sogs command in case of longer blocklist file)

if [[ "$(grep -c 5 "$modsids")" == "1" ]]; then # file with mod IDs to maintain exist, it contains one line and number 5 exist so hopefully correct format
echo "Unbanning possibly banned moderators..."
for i in 1 2 3 4 5; do
for modlistid in $(cat "$modsids"); do
sqlite3 /var/lib/session-open-group-server/sogs.db "UPDATE users SET banned = FALSE WHERE session_id = '$modlistid';" && break || echo "" && sleep 0.1;
done
done
# Unbanning all mods in a defined room:
for i in 1 2 3 4 5; do
for modlistid in $(cat "$modsids"); do
#sqlite3 /var/lib/session-open-group-server/sogs.db "UPDATE user_permission_overrides (room, \"user\", banned) VALUES ((SELECT id FROM rooms WHERE token = '$comname'), (SELECT id FROM users WHERE session_id = '$modlistid'), FALSE);"
sqlite3 /var/lib/session-open-group-server/sogs.db "UPDATE user_permission_overrides SET banned = FALSE WHERE room = (SELECT id FROM rooms WHERE token = '$comname') AND user = (SELECT id FROM users WHERE session_id = '$modlistid');" && break || echo "" && sleep 0.1;
done
done
echo -e "Unbanning complete. Ocassional locked DB warnings are OK, because the script retry 5 times. \nSetting intended mods as mods:"
# Re-add all mods from file to $defaultcommunity to override possible unwanted removals of them:
# If i will be changing mode on how the modlist works (for example adding modids along with room names instead of using modlist only for $defaultcommunity), then i need to remove below:  && [[ "$comname" != "global" ]]"
sogs --rooms "$defaultcommunity" --add-moderators $(cat "$modsids") --hidden; fi; echo "Setting mods done."
sogs --rooms "$comname" --"$action"-moderator "$ids" --"$type" && 
if [[ "$action" == "add" ]] && [[ "$comname" != "global" ]]; then sed -i "s/$/ $ids/" "$modsids"; elif [[ "$action" == "delete" ]]; then sed -i "s/ $ids//" "$modsids"; fi # append or delete mod ID to/from the line of the mod list file
cp -fp "$profanityfile"_"$(date --rfc-3339=date)" "$profanityfile" # restore blocklist
else
echo "Unrecognized action and/or moderator type."
fi
