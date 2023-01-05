## Setup Mullvad VPN (+port forwarding) for existing ethereum validator nodes

### Links

Mullvad VPN: **[ [Setup](#Mullvad-VPN----Setup) - [Uninstall](#Mullvad-VPN----Uninstall)]**

Public IP address monitoring: **[ [Setup](#Public-IP-address-monitoring----Setup) - [Uninstall](#Public-IP-address-monitoring----Uninstall) ]**

Changes to Execution Client Flags: **[ [geth](#Geth-client-flags-to-modify) ]**

Changes to Conseunsus Client Flags: **[ [lighthouse](#Lighthouse-Beacon-client-flags-to-modify) ]**

Verify you have inbound peer connections **[ [geth](#Verify-you-have-inbound-peer-connections) ]**

---

## Mullvad VPN -- Setup

### Note: you can also follow the [official install docs for linux here](https://mullvad.net/en/download/linux/)

1. Download and trust the [signing key](https://mullvad.net/en/help/verifying-signatures/)

```zsh
wget https://mullvad.net/media/mullvad-code-signing.asc
gpg --import mullvad-code-signing.asc
gpg --edit-key A1198702FC3E0A09A9AE5B75D5A1D4F266DE8DDF

# gpg> trust
# Your decision? 5
# Do you really want to set this key to ultimate trust? (y/N) y
# gpg> q
```

2. Download the cli and signature

```zsh
wget --trust-server-names https://mullvad.net/download/app/deb/latest
wget --trust-server-names https://mullvad.net/download/app/deb/latest/signature
# verify the key
gpg --verify MullvadVPN-*.deb.asc
# if it's all good then install the deb package
sudo apt install MullvadVPN-*.deb
```

3. Go to mullvad and sign up + fund your account (https://mullvad.net/en/account) and make note of your account number
4. login to your mullvad account on the cli ([official docs](https://mullvad.net/en/help/how-use-mullvad-cli/))

```zsh
mullvad account login <your mullvad account number>
```

5. (!) enable LAN access

```zsh
mullvad lan set allow
```

6. Set protocol to wireguard (recommended)

```zsh
mullvad relay set tunnel-protocol wireguard
```

7. Set your target vpn country (USA=us, UK=gb, etc)

```zsh
# list server locations
mullvad relay list

# important to set a country and city for the vpn server
# gb = UK, hel=Helsingborg (city)
mullvad relay set location gb hel
```

8. check your wireguard key

```zsh
mullvad tunnel wireguard key check
```

9. go to your [mullvad account dashboard](<(https://mullvad.net/en/account)>) and set up your device with two forwarded ports (make note of the port numbers). These port numbers need to be manually added to your ethereum EL/CL client flags (see below).

10. If you have a ufw firewall on your server, allow these port numbers through it

```zsh
sudo ufw allow <your-port-1> comment "mullvad geth port"
sudo ufw allow <your-port-2> comment "mullvad lighthouse bn port"

# verify they are active
sudo ufw status
```

11. **STOP** -- Before connecting make sure the ports you configured in your mullvad account dashboard are set properly in your client configs (see below) and you either used the pubip-getter setup or hard coded your mullvad public IP

12. Set mullvad to auto-connect

```zsh
# turn auto-connect on
mullvad auto-connect set on

# turn auto-connect off
mullvad auto-connect set off
```

13. Connect to mullvad

```zsh
mullvad connect

# check status
mullvad status -v
```

14. Check your public IP manually

```zsh
curl -s https://ipinfo.io/ip
```

#### [Back to top](#top)
---

## Mullvad VPN -- Uninstall

1. Make sure your ethereum client configs are set back to how they were before doing this
2. remove mullvad-vpn

```zsh
sudo apt remove mullvad-vpn -y
```

#### [Back to top](#top)
---

## Public IP address monitoring -- Setup

### Note:

- tested only on Ubuntu 22.04.1 LTS

Note: The pubip-getter.sh script is run by the pubip-getter.service every minute. It checks the ipinfo.io/ip API for the host's current public IP. The free tier of that API is limited to [50k requests per month](https://ipinfo.io/developers#rate-limits), so running once per minute results in ~43,830 req/month.

1. take a look at pubip-getter.sh and understand what it's doing
2. copy pubip-getter.sh into /usr/local/bin (may need sudo to write the files to that dir)

```zsh
cd /usr/local/bin && \
sudo curl -fSslO https://raw.githubusercontent.com/hokumbafflegab-eth/staking-with-mullvad-vpn/main/pubip-getter.sh && \
cd -
```

3. make the script executable with

```zsh
sudo chmod +x /usr/local/bin/pubip-getter.sh
```

4. copy pubip-getter.timer and pubip-getter.service into /etc/systemd/system (may need sudo to write the files to that dir)

```zsh
cd /etc/systemd/system && \
sudo curl -fSslO https://raw.githubusercontent.com/hokumbafflegab-eth/staking-with-mullvad-vpn/main/pubip-getter.timer && \
sudo curl -fSslO https://raw.githubusercontent.com/hokumbafflegab-eth/staking-with-mullvad-vpn/main/pubip-getter.service && \
sudo curl -fSslO https://raw.githubusercontent.com/hokumbafflegab-eth/staking-with-mullvad-vpn/main/pubip-changed.target && \
cd -
```

5. enable pubip-getter.timer

```zsh
sudo systemctl enable pubip-getter.timer
```

6. check your logs (it should update every 60 seconds after enabling the timer)

```zsh
journalctl -fu pubip-getter.service
```

```zsh
# expected output
# ...
<timestamp> <hostname> systemd[1]: Starting Public IP Address Monitor...
<timestamp> <hostname> pubip-getter.sh[...]: Valid Public IP
<timestamp> <hostname> pubip-getter.sh[...]: Successfully updated /tmp/public_ip: <your public ip!>
<timestamp> <hostname> systemd[1]: pubip-getter.service: Deactivated successfully.
<timestamp> <hostname> systemd[1]: Finished Public IP Address Monitor.
<timestamp> <hostname> systemd[1]: Starting Public IP Address Monitor...
<timestamp> <hostname> pubip-getter.sh[...]: No change -- skipping
<timestamp> <hostname> systemd[1]: pubip-getter.service: Deactivated successfully.
<timestamp> <hostname> systemd[1]: Finished Public IP Address Monitor.
```

```zsh
journalctl -fu pubip-getter.timer
```

```zsh
# expected output
# ...
<timestamp> <hostname> systemd[1]: Started Timer for pubip-getter.service.
```

#### [Back to top](#top)

---

## Public IP address monitoring -- Uninstall

1. disable pubip-getter.timer

```zsh
sudo systemctl disable pubip-getter.timer
```

2. remove pubip-getter.timer, pubip-getter.service, pubip-changed.target, pubip-getter.sh, and /tmp/public_ip

```zsh
sudo rm /etc/systemctl/system/pubip-getter.timer
sudo rm /etc/systemctl/system/pubip-getter.service
sudo rm /etc/systemctl/system/pubip-changed.target
sudo rm /usr/local/bin/pubip-getter.sh
sudo rm /tmp/public_ip
```

#### [Back to top](#top)

---

## Geth client flags to modify

Notes:

- assuming you are using a systemd unit to run your geth client
- always a good idea to make a backup copy of your service units when you change them
- IMPORTANT: if your client is restarted automatically it is likely you will an attestation or so while it starts up the service. If your client is not automatically restarted, you will also miss attestations due to having a hardcoded enode address (that no longer matches your public ip!)

```zsh
sudo cp ./geth.service ./geth.service.bak
# to restore
sudo mv ./geth.service.bak ./geth.service
```

```zsh
# changes to /etc/systemd/system/geth.service (or whatever your geth service name is)

[Unit]
# ... leave existing
# NEW - this causes the unit to be restarted whenever the target is restarted
PartOf=pubip-changed.target

[Service]
# ...
# NEW - this loads the PUBLIC_IP environment variable
EnvironmentFile=/tmp/public_ip
ExecStart=/usr/bin/geth --mainnet \
            		# ... leave existing flags (or modify as needed)
            		# NEW - this sets your enode/ENR port
			--port <your chosen port forwarded from mullvad dashboard> \
            		# NEW - this sets your enode/ENR IP
			--nat extip:${PUBLIC_IP} \

# ...
```

#### [Back to top](#top)

---

## Lighthouse Beacon client flags to modify

Note:

- assuming you are using a systemd unit to run your lighthouse beacon client
- always a good idea to make a backup copy of your service units when you change them
- IMPORTANT: if your client is restarted automatically it is likely you will an attestation or so while it starts up the service. If your client is not automatically restarted, you will also miss attestations due to having a hardcoded enode address (that no longer matches your public ip!)

```zsh
sudo cp ./lighthousebeacon.service ./lighthousebeacon.service.bak
# to restore
sudo mv ./lighthousebeacon.service.bak ./lighthousebeacon.service
```

```zsh
# changes to /etc/systemd/system/lighthousebeacon.service (or whatever your lighthouse bn service name is)

[Unit]
# ... leave existing
# NEW - this causes the unit to be restarted whenever the target is restarted
PartOf=pubip-changed.target

[Service]
# ...
# NEW - this loads the PUBLIC_IP environment variable
EnvironmentFile=/tmp/public_ip
ExecStart=/usr/local/bin/lighthouse bn \
            		# ... leave existing flags (or modify as needed)
            		# NEW - this sets your enode/ENR port
            		--port <your chosen port forwarded from mullvad dashboard> \
            		# NEW - this sets your enode/ENR IP
			--enr-address ${PUBLIC_IP} \
            		# NEW - this sets your enode/ENR udp port
		    	--enr-udp-port <your chosen port forwarded from mullvad dashboard> \
# ...
```

#### [Back to top](#top)

---

## Verify you have inbound peer connections

1. Attach to the geth console
```zsh
# use whatever your path is to the localhost geth.ipc file
sudo geth attach /var/lib/geth/geth.ipc
```
2. Check total peer count
```
> net.peerCount
40
```
3. Check enode address
```
> admin.nodeInfo.enode
"enode://<some-long-string>@<your-public-ip>:<your-geth-port>"
```
4. Verify inbound peer connections
```
# this command counts the number of peers where network.inbound = true
> admin.peers.filter(peer=>peer.network.inbound).length
27
```
#### [Back to top](#top)

---
