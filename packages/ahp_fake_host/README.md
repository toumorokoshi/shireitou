# ahp_fake_host

A scripted Agent Host Protocol 1.0.0 host for tests and manual checks. It
asks for tool approvals, input (elicitations), MCP sign-in, and runs
background work when a message names the flow. See
[docs/fake-host.md](../../docs/fake-host.md).

```sh
just fake-host            # prints ws://127.0.0.1:<port>?tkn=<token>
dart test                 # AhpClient flows against the host
```
