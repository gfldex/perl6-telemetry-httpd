use v6.c;

use lib 'lib';
use Test;

quietly { use-ok('Telemetry:httpd', 'can load Telemetry::httpd') };

# use Telemetry::httpd;
# loop { 
#     say ‚heart beat‘;
#     sleep 1;
# }

done-testing;
