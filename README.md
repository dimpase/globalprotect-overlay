# GlobalProtect CLI overlay for Gentoo

A small, unofficial Gentoo overlay for the command-line components of
[GlobalProtect-openconnect](https://github.com/yuezk/GlobalProtect-openconnect).
It works with organisation-specific GlobalProtect portals; the package contains
no particular server or account settings (but see examples/ for details of using
the package with the Duo 2FA).

## Package

`net-vpn/GlobalProtect-openconnect-3.4.0` installs:

- `gpclient`, the VPN command-line client;
- `gpauth`, for authentication in your normal desktop browser;
- a hidden desktop handler for `globalprotectcallback:` URLs;
- upstream's `vpnc-script`, for route and DNS configuration.

Both executables are built without embedded webview support. There is no GUI,
GTK/WebKit dependency, `gpservice`, or automatically started VPN service.
OpenRC is supported.

The ebuild uses the official offline source release, including pinned Rust
dependencies and upstream's modified OpenConnect library. That library is
bundled because this release needs APIs absent from stock OpenConnect. GnuTLS,
GMP, nettle, libxml2, lz4, p11-kit, and zlib are linked from Gentoo packages.

## Install

Run as root:

```sh
emerge --ask app-eselect/eselect-repository dev-vcs/git
eselect repository add globalprotect-overlay git https://github.com/dimpase/globalprotect-overlay.git
emaint sync -r globalprotect-overlay
```

On amd64, add this line to your `package.accept_keywords` configuration:

```text
=net-vpn/GlobalProtect-openconnect-3.4.0::globalprotect-overlay ~amd64
```

Then run as root:

```sh
emerge --ask =net-vpn/GlobalProtect-openconnect-3.4.0::globalprotect-overlay
```

For OpenRC systems using dhcpcd, install openresolv to coordinate VPN and Wi-Fi
DNS updates. Otherwise the two programs may overwrite each other's DNS settings:

```sh
emerge --ask net-dns/openresolv
dhcpcd --reconfigure
```

If openresolv reports a signature mismatch for `/etc/resolv.conf`, run
`resolvconf -u` as root. Systems using systemd-resolved can use the upstream
script's resolved integration instead.

## Connect with an external browser

For an easier two-terminal workflow, see the optional
[Northwestern helper scripts](examples/README.md). They detect the desktop UID
instead of hard-coding a user; their portal can be edited for other organisations.
The ebuild does not install them. The commands below describe the manual workflow.

Replace `vpn.example.org` with your organisation's portal in both commands below.
Authentication runs as your desktop user; the tunnel runs as root.

As your **desktop user**, in a desktop session with `XDG_RUNTIME_DIR` set:

```sh
umask 077
auth_dir=$(mktemp -d "${XDG_RUNTIME_DIR:?}/gp-auth.XXXXXX")
gpauth vpn.example.org --browser default > "$auth_dir/auth.json"
printf 'Authentication file: %s\n' "$auth_dir/auth.json"
```

Complete SSO/MFA in the browser. If asked, allow **GlobalProtect browser login
callback**. Wait for `gpauth` to finish successfully before proceeding. The
printed path is safe to copy; the file contents are credentials and must remain
private. An authentication failure may also be written as JSON, so a zero exit
status alone does not prove login succeeded.

In a **root** shell, set `auth_file` to the actual path printed above. The
following example opens the file and removes its directory before starting the
tunnel, keeping the credentials available only through the open descriptor:

```sh
auth_file=/run/user/1000/gp-auth.XXXXXX/auth.json
(
    exec 3< "$auth_file" || exit 1
    rm -- "$auth_file" || exit 1
    rmdir -- "$(dirname -- "$auth_file")" || exit 1
    gpclient connect vpn.example.org --cookie-on-stdin <&3 3<&-
)
```

Keep that terminal open. **Ctrl+C** disconnects and runs network cleanup.
Alternatively, in another root terminal:

```sh
gpclient disconnect --wait 5
```

If you abandon authentication before connecting, delete the temporary file and
directory as your desktop user.

## Status and limitations

- Tested on Gentoo amd64 with Rust 1.99.0. Ebuild build, test, and staged-install
  phases passed: 123 tests passed, with one upstream test ignored. Those tests
  ran with Portage sandbox/user switching disabled; socket/process tests also
  required execution outside the development tool sandbox.
- The package was subsequently installed and used successfully with
  Northwestern SSO and VPN, including DNS through openresolv.
- Other organisations have not been tested. Device compliance/HIP policies may
  require additional configuration or prevent access.
- HTTPS fallback worked when ESP could not connect.
- A sleep/wake cycle caused loss of connectivity. The cause is unconfirmed;
  disconnect before suspend and reconnect after waking. This CLI setup installs
  no suspend hook. If necessary, disconnect gracefully, then refresh dhcpcd DNS
  and run `resolvconf -u`. Avoid forcibly killing the client, which skips cleanup.

## Maintenance and licensing

Report packaging problems in this repository's issues, with `emerge --info` and
the relevant build error. For authentication/runtime bugs, include sanitised
logs and the client version. Never publish tokens, cookies, or callback URLs.

Packaging and documentation in this repository are licensed under GPL-2.0
([LICENSE](LICENSE)). The packaged software retains its upstream licences,
listed in the ebuild. This is an independent overlay, not an official Gentoo
or Palo Alto Networks package.
