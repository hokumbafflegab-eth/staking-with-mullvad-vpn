#!/usr/bin/env bash
# pubip-getter.sh will be executed by the pubip-getter.service

# check if /tmp/public_ip file exists and source it if exists
[[ -f "/tmp/public_ip" ]] && source /tmp/public_ip;

# set NEW_PUBLIC_IP variable from ipinfo.io api
NEW_PUBLIC_IP="$(curl -s https://ipinfo.io/ip)";

# validate NEW_PUBLIC_IP with regex (needs to be valid IPv4 address)
if [[ "$NEW_PUBLIC_IP" =~ ^(([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$ ]]; 
then
	# write or overwrite /tmp/public_ip if IP changed or does not exist
	# trigger restart of pub-ip-changed.target (which restarts EL/CL clients if configured)
	[[ "$PUBLIC_IP" != "$NEW_PUBLIC_IP" ]] && \
		echo "Valid Public IP" && \
		echo "PUBLIC_IP=$NEW_PUBLIC_IP" > /tmp/public_ip && \
	    echo "Successfully updated /tmp/public_ip: $NEW_PUBLIC_IP" && \
		systemctl restart pubip-changed.target || \
		echo "No change -- skipping"
else
	echo "Invalid Public IP -- skipping";
fi
