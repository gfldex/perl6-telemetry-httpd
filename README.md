# Telemetry::httpd

[![Build Status](https://travis-ci.org/gfldex/perl6-telemetry-httpd.svg?branch=master)](https://travis-ci.org/gfldex/perl6-telemetry-httpd)

Add a Simple httpd to any Perl 6 program that listens on 5565 by default and
reports telemetry gathered by `use Telemetry;`

## SYNOPSIS

```
use Telemetry::httpd;

loop { 
    say ‚heart beat‘;
    sleep 1;
}
```

The httpd server process is started when the module is loaded. Reports can be
fetched with `GET /` as text.

The default interval of 1 second can be changed by `GET /interval=66.6`. The
httpd-server thread can be terminated by `GET /stop-server` and taking
telemetry snapshots can be stopped with `GET /stop-snapper`.

The default port of 5565 can be changed via `%*ENV<RAKUDO_REPORT_PORT>`.

## LICENSE

All files (unless noted otherwise) can be used, modified and redistributed
under the terms of the Artistic License Version 2. Examples (in the
documentation, in tests or distributed as separate files) can be considered
public domain.

ⓒ2017 Wenzel P. P. Peppmeyer
