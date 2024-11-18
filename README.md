# dnscrypt-proxy-install

Script to install and configure DNSCrypt Proxy on RaspberryPi and GNU/Linux

## Run the Script

This is a one-liner script that you can run in your terminal. It will install DNSCrypt Proxy and configure it to use Cloudflare's DNS resolver.

```sh
sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/marcomc/dnscrypt-proxy-install/refs/heads/main/dnscrypt-proxy-install.sh)"
```

## Importance of Installing DNSCrypt Proxy on Pi-hole

Pi-hole enhances privacy by blocking ads and trackers, but DNS resolvers can still see your IP address. Encrypted DNS protocols like DoT and DoH encrypt traffic but don't hide your IP from resolvers. Solutions like Oblivious-DNS-Over-HTTPS (ODoH) and DNSCrypt with an anonymous relay can hide your IP by routing queries through another host.

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