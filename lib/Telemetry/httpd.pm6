use v6.c;
use Telemetry;

constant CRLF = "\x0D\x0A";
constant NL = "\n";
constant HTTP-HEADER = "HTTP/1.1 200 OK", "Content-Type: text/plain; charset=utf-8", "Content-Encoding: utf-8", "";
constant term:<HTTP-HEADER-404> = "HTTP/1.1 404 Not Found", "Content-Type: text/plain; charset=UTF-8", "Content-Encoding: UTF-8", "";
constant term:<HTTP-HEADER-408> = "HTTP/1.1 408 Request Timeout", "Content-Type: text/plain; charset=UTF-8", "Content-Encoding: UTF-8", "";
constant term:<HTTP-HEADER-501> = "HTTP/1.1 501 Internal Server Error", "Content-Type: text/plain; charset=utf-8", "Content-Encoding: utf-8", "";

my &BOLD = $*OUT.t ?? sub (*@s) { "\e[1m{@s.join('')}\e[0m" } !! sub (|c) { c };

constant CSS = Q:to /EOH/;
<style>
    table.rakudo-telemetry tr:nth-child(even) { background: #eee; }
    table.rakudo-telemetry tr:nth-child(odd) { background: #fff; }
    table.rakudo-telemetry td { font-family: monospace; }
</style>
<link rel="stylesheet" type="text/css" href="./rakudo-telemetry.css" />
EOH

INIT start {
    react {
        my $port = %*ENV<RAKUDO_TELEMETRY_PORT> // 5000;
        my $local-addr = %*ENV<RAKUDO_TELEMETRY_LISTEN> // ‚localhost‘;

        snapper(1);
        whenever IO::Socket::Async.listen($local-addr, $port) -> $conn {
            my @msg = HTTP-HEADER »~» CRLF;

            whenever $conn.Supply.lines.list {
                # we only really care about the first line in a http header.
                if .head ~~ /^GET <ws> (<[\w„/.=“]>+) [„HTTP“ \d „/“ \d]? / {
                    given $0.Str {
                        when „/“ {
                            # @msg[1] = ‚Content-Type: application/xhtml+xml; charset=UTF-8‘;
                            @msg.push: report(:!header-repeat);
                        }
                        when m{ '/interval' } {
                            my $new-interval = .split(‚=‘)[1].Rat;
                            snapper( $new-interval );
                            @msg.push: „Interval set to $new-interval“;
                        }

                        when ‚/csv‘ {
                            @msg.push: report(:csv, :!legend);
                        }

                        when ‚/html‘ {
                            @msg[1] = ‚Content-Type: application/xhtml+xml; charset=UTF-8‘ ~ CRLF;
                            @msg.push: ‚<?xml version="1.0" encoding="UTF-8"?>‘ ~ NL;
                            @msg.push: „<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">“ ~ NL;
                            @msg.push: „<html xmlns="http://www.w3.org/1999/xhtml"><head><title>PLACEHOLDER</title>{CSS}</head><body><table class="rakudo-telemetry">“;

                            sub tr(Str $s){ ‚<tr>‘ ~ $s ~ ‚</tr>‘ };
                            sub td(Str $s){ [~] ‚<td>‘ «~« $s.split(‚ ‘) »~» ‚</td>‘ };
                            sub th(Str $s){ [~] ‚<th>‘ «~« $s.split(‚ ‘) »~» ‚</th>‘ };

                            my @report = report(:csv, :!legend).split(NL);

                            my $tmp := Nil;
                            note tr($tmp);

                            @msg.push: @report[2]».&th».&tr;
                            @msg.push: @report.tail(*-3)».&td».&tr;

                            @msg.push: ‚</table></body></html>‘;
                        }

                        when „/stop-server“ {
                            done;
                        }

                        when ‚/stop-snapper‘ {
                            snapper(:stop);
                        }

                        default {
                            @msg = HTTP-HEADER-404;
                            @msg.push: „Resource {.Str} not found.“;
                        }
                    }
                }

                # `lines` returns the empty string on a double newline, as we get at the end of a http header.
                if .tail ~~ /^$/ {
                    $conn.print: @msg.join('');
                    $conn.close;
                }
                CATCH {
                    default {
                        $conn.print: join('', HTTP-HEADER-501 »~» CRLF);
                        $conn.print: ‚501 Internal Server Error‘ ~ NL ~ NL;
                        $conn.print: .^name ~ ': ' ~ .Str ~ NL ~ .backtrace;
                        $conn.close;
                    } 
                }
            }
            whenever Promise.in(60) {
                $conn.close;
            }

            CLOSE {
            }
        }
    }
    
    CATCH { default { warn BOLD .^name, ': ', .Str, NL, .backtrace; } }
}
