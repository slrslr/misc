# Session Community Server (SOGS) Linux bash scripts

Requirement for many script is a sqlite3 package: sudo apt install sqlite3

You should open following script files to see what it is doing and to adjust its variables if needed

---

## Profanity automatic removal:

**session-profanity-remover.sh** - automatically removes unwanted posts from a SOGS SQL database (and from Session clients) after it is being posted. It is meant for a long spam phrases for partial matching (phrase "bad" would match and delete messages containing i.e. "Sinbad") and is also meant to deal with a profanity blocklist evaders thanks to a processing of a secondary, regular expressions blocklist.

**profanity-block-list.txt** - list of a words/phrases aimed to be blocked in a civilized discussion. Some listed phrases are questionable for blocking. You should remove some of these in case you allow DMs/PMs, which allows paed.philes and similar to get in contact, to remove pm/dm blocking, search for dm, pm, message, msg, add, group, grp, room.

**profanity-block-list-partial-match.txt** - list of a longer phrases aimed to be blocked in a civilized discussion. List should be more or less safe for partial matching, mostly effective against lazy perverts and ped0s in a discussions.

**profanity-block-list-partial-match-regex.txt** - list of regular expressions that are matching spam phrases like cheeeeeese pizzzzaa and similar where insistent spammers trying to evade/workaround the primary profanity blocklist.

---

## Database triggers:

**session-sogs-prevent-disable-pm-dm-for-regular-users.sh** - add or remove a database trigger that will prevent regular users without admin/mod privileges to send PM/DM to others.

**session-sogs-prevent-disable-pm-dm-for-new-regular-users.sh** - add or remove a database trigger that will prevent new regular users without admin/mod privileges to send PM/DM to others. Older users can send.

**session-sogs-ban-large-long-message-poster.sh** - add or remove a database trigger that will ban user who posts too long text message.

**session-sogs-delete-banned-user-messages-reactions.sh** - add or remove a database trigger that will delete messages and reactions of a user who gets banned.

**session-sogs-allow-users-older-than-defined-date-to-write-post-despite-community-writing-is-disabled.sh** - add or remove a database trigger that will override disabled writing permission in all communities (sogs --rooms + --remove-perms w) for users older than specified date/time. Rest users can not override this so they can not post. Such situation helps treating spam/flood done by new user/s or new spam bots while allowing old users to post.

---

## Other

**session-moderator-add-or-remove.sh** - helps adding or removing Session community moderator/s while maintaining list of selected moderators unbanned

**session-moderator-list-unban-keep-rights.sh** - maintain list of selected Session IDs as a community moderators or admins and keep these IDs not banned. Running this script reverts malevolent community admins removals/bans of other mods/admins.

**session-sogs-delete-messages-containing.sh** - search SOGS database for a messages containing yours defined text (possible to partial match: %ery b%d phras%). After the text is output, you can optionally delete matching messages

**session-sogs-ban-delete-user.sh** - helps to ban user on a whole server and delete all their content

**session-sogs-unban-user.sh** - helps to unban user on a whole server
