#!/bin/bash
#
# docker_image_diff -- Compares the list of installed RPM packages between
#                      two Docker images from the local Docker registry.
# Copyright (C) 2016, Red Hat, Inc., Matus Marhefka <mmarhefk@redhat.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#===============================================================================

if [ -z "$1" ] || [ -z "$2" ]; then
	echo "Compares the list of installed RPM packages between two Docker"
	echo "images from the local Docker registry. Usage:"
	echo "$0 <DOCKER_OLD_IMG> <DOCKER_NEW_IMG>"
	echo "Prints UPDATED, ADDED and REMOVED packages in <DOCKER_NEW_IMG>"
	echo "compared to <DOCKER_OLD_IMG>."
	exit 0
fi

#===============================================================================
OLD=$1
NEW=$2
DIFF_OLD=$(mktemp)
DIFF_NEW=$(mktemp)
OLD_PKGS=$(mktemp)
NEW_PKGS=$(mktemp)


docker run --rm -t $OLD \
	rpm -qa --qf '%{NAME} %{VERSION}-%{RELEASE} %{SOURCERPM}\n' \
	| sort >$OLD_PKGS
OLD_VER=$(docker inspect --format '{{ index .Config.Labels "Version" }}' $OLD)
OLD_RLS=$(docker inspect --format '{{ index .Config.Labels "Release" }}' $OLD)
OLD_COMP=$(docker inspect --format \
	'{{ index .Config.Labels "com.redhat.component" }}' $OLD)
if [ -z "$OLD_COMP" ]; then
	OLD_COMP=$(docker inspect --format \
	'{{ index .Config.Labels "BZComponent" }}' $OLD)
fi
OLD_TARGET="$OLD_COMP-$OLD_VER-$OLD_RLS"
if [ -z "$OLD_COMP" ]; then
	OLD_TARGET=$1
fi

docker run --rm -t $NEW \
	rpm -qa --qf '%{NAME} %{VERSION}-%{RELEASE} %{SOURCERPM}\n' \
	| sort >$NEW_PKGS
NEW_VER=$(docker inspect --format '{{ index .Config.Labels "Version" }}' $NEW)
NEW_RLS=$(docker inspect --format '{{ index .Config.Labels "Release" }}' $NEW)
NEW_COMP=$(docker inspect --format \
	'{{ index .Config.Labels "com.redhat.component" }}' $NEW)
if [ -z "$NEW_COMP" ]; then
	NEW_COMP=$(docker inspect --format \
	'{{ index .Config.Labels "BZComponent" }}' $NEW)
fi
NEW_TARGET="$NEW_COMP-$NEW_VER-$NEW_RLS"
if [ -z "$NEW_COMP" ]; then
	NEW_TARGET=$2
fi

if [ "$OLD_COMP" != "$NEW_COMP" ]; then
	echo "Warning: comparing different components"
fi

#===============================================================================
UPDATED=""
ADDED=""
REMOVED=""

# $DIFF_NEW will contain a list of new and added packages in $NEW_TARGET
# compared to $OLD_TARGET.
diff -u $OLD_PKGS $NEW_PKGS | grep -E "^\+[^+]" | sed 's/^+//g' >$DIFF_NEW
# $DIFF_OLD will contain a list of old and removed packages in $NEW_TARGET
# compared to $OLD_TARGET.
diff -u $OLD_PKGS $NEW_PKGS | grep -E "^-[^-]" | sed 's/^-//g' >$DIFF_OLD

while read -r line; do
	# Gets name of the new package.
	npkg=$(echo $line | awk '{print $1}')
	# Finds the name of the new package in old packages list.
	opkg=$(grep "^$npkg" $DIFF_OLD)
	# If the new package name is not listed in old packages list, then
	# it was added in $NEW_TARGET.
	if [ -z "$opkg" ]; then
		#ADDED="$ADDED\n$(echo $line | awk '{printf("%s-%s",$1,$2)}')"
		ADDED="$ADDED\n$line"
	else
	# Otherwise it was just updated (packages differ only in version
	# and release numbers).
		UPDATED="$UPDATED\n$line"
	fi
done <$DIFF_NEW

while read -r line; do
	# Gets name of the old package.
	opkg=$(echo $line | awk '{print $1}')
	# Finds the name of the old package in new packages list.
	npkg=$(grep "^$opkg" $DIFF_NEW)
	# If the old package name is not listed in new packages list, then
	# it was removed in $NEW_TARGET.
	if [ -z "$npkg" ]; then
		REMOVED="$REMOVED\n$(echo $line | awk '{printf("%s-%s",$1,$2)}')"
	fi
done <$DIFF_OLD

# Builds a list of updated source RPMs from $UPDATED list.
UPDATED_SRPM=""
while read -r line; do
	UPDATED_SRPM="$UPDATED_SRPM\n$(echo $line | awk '{print $3}')"
done <<<"$(echo -e $UPDATED | tail -n +2)"
UPDATED_SRPM=$(echo -e $UPDATED_SRPM | tail -n +2 | sed 's/.src.rpm//g' | sort -u)

# Builds a list of updated source RPMs from $ADDED list.
ADDED_SRPM=""
while read -r line; do
	ADDED_SRPM="$ADDED_SRPM\n$(echo $line | awk '{print $3}')"
done <<<"$(echo -e $ADDED | tail -n +2)"
ADDED_SRPM=$(echo -e $ADDED_SRPM | tail -n +2 | sed 's/.src.rpm//g' | sort -u)

#===============================================================================
echo -e "Diff between $OLD_TARGET and $NEW_TARGET\n\n"


echo "UPDATED packages in $NEW_TARGET:"
echo "============================================================"
# Lists updated packages in format:
# SRPM package: [list of packages belonging to the SRPM package]
while read -r isrpm; do
	srpm_plain=$(echo $isrpm | tr -d '\n|\r')
	if [ -z "$srpm_plain" ]; then
		continue
	fi
	printf "SRPM %s: " "$srpm_plain"
	while read -r updated; do
		srpm=$(echo $updated | awk '{print $3}' | sed 's/.src.rpm//')
		if [ "$srpm" == "$isrpm" ]; then
			pkg=$(echo $updated | awk '{printf("%s-%s",$1,$2)}')
			printf "%s " "$pkg"
		fi
	done <<<"$(echo -e $UPDATED | tail -n +2)"
	printf "\n"
done <<<"$UPDATED_SRPM"


echo -e "\nADDED packages in $NEW_TARGET:"
echo "============================================================"
# Lists added packages in format:
# SRPM package: [list of packages belonging to the SRPM package]
while read -r isrpm; do
	srpm_plain=$(echo $isrpm | tr -d '\n|\r')
	if [ -z "$srpm_plain" ]; then
		continue
	fi
	printf "SRPM %s: " "$srpm_plain"
	while read -r added; do
		srpm=$(echo $added | awk '{print $3}' | sed 's/.src.rpm//')
		if [ "$srpm" == "$isrpm" ]; then
			pkg=$(echo $added | awk '{printf("%s-%s",$1,$2)}')
			printf "%s " "$pkg"
		fi
	done <<<"$(echo -e $ADDED | tail -n +2)"
	printf "\n"
done <<<"$ADDED_SRPM"


echo -e "\nREMOVED packages in $NEW_TARGET:"
echo "============================================================"
echo -e "$REMOVED" | tail -n +2


rm -f $DIFF_OLD $DIFF_NEW $OLD_PKGS $NEW_PKGS
