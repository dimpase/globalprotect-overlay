# Northwestern VPN helpers

These optional Python 3 scripts demonstrate external-browser login as a desktop
user, followed by a VPN connection from a separate root terminal. They are
adapted from the helpers used to test this overlay at Northwestern. The ebuild
does not install them.

Both use `vpn-connect.northwestern.edu`. For another organisation, change
`PORTAL` in `nu-vpn-login` and the portal argument in `nu-vpn-connect` to the
same server. They require the overlay's `gpauth`, `gpclient`, and browser
callback handler, plus a working `/run/user/<UID>` desktop runtime directory.

## Install

From the repository root, as your normal desktop user:

```sh
install -Dm755 examples/nu-vpn-login "$HOME/.local/bin/nu-vpn-login"
```

From the repository root, in a root terminal:

```sh
install -Dm755 examples/nu-vpn-connect /usr/local/sbin/nu-vpn-connect
```

## Use

In your desktop terminal:

```sh
~/.local/bin/nu-vpn-login
```

Complete browser authentication, allowing **GlobalProtect browser login
callback** when prompted. On success the script prints the exact command to
run in your root terminal, for example:

```sh
/usr/local/sbin/nu-vpn-connect alice
```

Replace `alice` with the desktop username that performed the login, or simply
copy the command printed by the login helper. If your `su` setup preserves the
desktop username in `$USER`, `nu-vpn-connect "$USER"` also works. Other root
shells may set it to `root`; the explicit argument avoids that ambiguity.

The login helper obtains the UID from `os.geteuid()` and the username from the
system account database. The connection helper looks up the explicitly supplied
username. Neither relies on a hard-coded username, UID, or home directory.

The authentication result is stored in
`/run/user/<UID>/northwestern-vpn/auth.json` with directory mode `0700` and file
mode `0600`. A new login replaces the previous result. The root helper checks
ownership and permissions, rejects symlinks at the credential-directory and
file level, opens and unlinks the file, and passes it to `gpclient` on standard
input. Credentials are not printed or passed as command-line arguments.

Keep the root terminal open. **Ctrl+C** disconnects; alternatively, run
`gpclient disconnect --wait 5` as root. Disconnect before suspending the laptop;
these examples do not implement automatic suspend/resume handling.

If you log in but decide not to connect, remove the saved result as your desktop
user:

```sh
rm -f -- "/run/user/$(id -u)/northwestern-vpn/auth.json"
```
