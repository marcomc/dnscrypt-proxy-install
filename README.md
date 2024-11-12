# dnscrypt-proxy-install

Script to install and configure DNSCrypt Proxy on RaspberryPi and GNU/Linux

## Importance of Installing DNSCrypt Proxy on Pi-hole

Pi-hole enhances privacy by blocking ads and trackers, but DNS resolvers can still see your IP address. Encrypted DNS protocols like DoT and DoH encrypt traffic but don't hide your IP from resolvers. Solutions like Oblivious-DNS-Over-HTTPS (ODoH) and DNSCrypt with an anonymous relay can hide your IP by routing queries through another host.

## How to Run the Script

You can fetch and run the script using either `curl` or `wget`.

### Using curl

```sh
curl -o dnscrypt-proxy-install.sh https://raw.githubusercontent.com/marcomc/dnscrypt-proxy-install/refs/heads/main/dnscrypt-proxy-install.sh
chmod +x dnscrypt-proxy-install.sh
sudo ./dnscrypt-proxy-install.sh
```

### Using wget

```sh
wget https://raw.githubusercontent.com/marcomc/dnscrypt-proxy-install/refs/heads/main/dnscrypt-proxy-install.sh
chmod +x dnscrypt-proxy-install.sh
sudo ./dnscrypt-proxy-install.sh
```

## Configuring Pi-hole

After installing cloudflared, you need to configure Pi-hole to use it as a DNS-over-HTTPS (DoH) provider.

1. Open the Pi-hole admin interface.
2. Go to **Settings** > **DNS**.
3. Under **Upstream DNS Servers**, select **Custom 1 (IPv4)** and enter `127.0.0.1#5055`.
4. Scroll down and click **Save**.

## Testing DNSCrypt Proxy

```sh
sudo systemctl status dnscrypt-proxy
dig @localhost -p 5055 txt debug.opendns.com
```

## Uninstalling cloudflared

If you need to uninstall cloudflared, you can use the `--uninstall` option with the script:

1. Run the uninstall command:

    ```sh
    sudo ./dnscrypt-proxy-install.sh --uninstall
    ```

This will stop the cloudflared service, disable it, and remove the cloudflared binary and configuration directory.