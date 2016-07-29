# rancid-zw5ap

Support for Zebra WiNG5 Access Points in RANCID.

## Usage

Install `zw5ap.pm` along the other RANCID .pm files.

Add this to your `/etc/rancid/rancid.types.conf`:

    # Zebra WiNG5 Access Points
    zw5ap;script;rancid -t zw5ap
    zw5ap;login;clogin
    zw5ap;module;zw5ap
    zw5ap;inloop;zw5ap::inloop
    zw5ap;command;zw5ap::RunCommand;enable
    zw5ap;command;zw5ap::ShowVersion;show version
    zw5ap;command;zw5ap::ShowConfig;write term

## Device support

All WiNG5 APs should work, although I only really tested the AP6521 and AP7522.

## Known issues

### Devices which contain crash information

This setup will timeout if the device contains crash information. This will set
the prompt to `device*>`, and RANCID's `clogin` script really doesn't like the
`*`.

Workaround: remove the crash info files, either from CLI or in the web GUI:
"Clear Crash Info" contextual menu.

## Author

Thomas Equeter, 2016.

## License

This software may be distributed under the same terms as
[RANCID](http://www.shrubbery.net/rancid/).

> This product includes software developed by Terrapin Communications,
> Inc. and its contributors for RANCID.
