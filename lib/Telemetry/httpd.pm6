use v6.c;
use Telemetry;

constant $port = %*ENV<RAKUDO_REPORT_PORT> // 5565;

constant HTTP-HEADER = "HTTP/1.1 200 OK", "Content-Type: text/plain; charset=UTF-8", "Content-Encoding: UTF-8", "";
constant term:<HTTP-HEADER-404> = "HTTP/1.1 404 Not Found", "Content-Type: text/plain; charset=UTF-8", "Content-Encoding: UTF-8", "";

my &BOLD = $*OUT.t ?? sub (*@s) { "\e[1m{@s.join('')}\e[0m" } !! sub (|c) { c };

INIT start react {
    snapper(1);
    whenever IO::Socket::Async.listen('0.0.0.0', $port) -> $conn {
        note „{now} incomming connection from {$conn.peer-host}:{$conn.peer-port}“;
        my @msg = HTTP-HEADER;
        whenever $conn.Supply.lines {
            # we only really care about the first line in a http header.
            if /^GET <ws> (<[\w„/.=“]>+) [„HTTP“ \d „/“ \d]? / {
                note „{now} GET $0“;
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
                for @msg {
                    once note .Str;
                    $conn.print(.Str ~ "\n");
                }
                $conn.close;
            }

        }
        CLOSE {
            note „{now} connection closed“;
        }
        CATCH { default { warn BOLD .^name, ': ', .Str; warn BOLD „handled in $?LINE“; } }
    }
}

