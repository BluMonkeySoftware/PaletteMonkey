#!/bin/bash
#
# Stamps CFBundleVersion with the repository's commit count, so every build
# carries a number that always moves forward and maps back to a commit.
# Run from the "Set Build Number" phase of each app target — it rewrites the
# built Info.plist (and the dSYM's), never the one in the source tree.

git=$(sh /etc/profile; which git)
number_of_commits=$("$git" rev-list HEAD --count)

target_plist="$TARGET_BUILD_DIR/$INFOPLIST_PATH"
dsym_plist="$DWARF_DSYM_FOLDER_PATH/$DWARF_DSYM_FILE_NAME/Contents/Info.plist"

for plist in "$target_plist" "$dsym_plist"; do
  if [ -f "$plist" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $number_of_commits" "$plist"
  fi
done
