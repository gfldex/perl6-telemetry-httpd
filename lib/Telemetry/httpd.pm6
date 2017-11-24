use v6.c;
use Telemetry;

constant $port = %*ENV<RAKUDO_TELEMETRY_PORT> // 666;
constant $local-addr = %*ENV<RAKUDO_TELEMETRY_LISTEN> // ‚localhost‘;

constant HTTP-HEADER = "HTTP/1.1 200 OK", "Content-Type: text/plain; charset=UTF-8", "Content-Encoding: UTF-8", "";
constant term:<HTTP-HEADER-404> = "HTTP/1.1 404 Not Found", "Content-Type: text/plain; charset=UTF-8", "Content-Encoding: UTF-8", "";
constant term:<HTTP-HEADER-408> = "HTTP/1.1 408 Request Timeout", "Content-Type: text/plain; charset=UTF-8", "Content-Encoding: UTF-8", "";

my &BOLD = $*OUT.t ?? sub (*@s) { "\e[1m{@s.join('')}\e[0m" } !! sub (|c) { c };

say $local-addr;

INIT start react {
    snapper(1);
    whenever IO::Socket::Async.listen($local-addr, $port) -> $conn {
        my @msg = HTTP-HEADER;
        
        whenever $conn.Supply.lines {
            # we only really care about the first line in a http header.
            if /^GET <ws> (<[\w„/.=“]>+) [„HTTP“ \d „/“ \d]? / {
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
            if /^$/ {
                $conn.print: @msg »~» "\n";
                $conn.close;
            }
        }
        whenever Promise.in(60) {
            $conn.close;
        }

        CLOSE {
        }
        CATCH { default { warn BOLD .^name, ': ', .Str; warn BOLD „handled in $?LINE“; } }
    }
}

