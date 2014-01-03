package SelfConf;
use parent qw(Exporter);

use strict;
use warnings;

our @EXPORT = qw(JSKP_KEY JSKP_SECRET NET_ADDR EMAIL_ADDR EMAIL_PASS SMTP_ADDR APP_SECRET);
our $VERSION = 1.00;

use constant JSKP_KEY => 'key of jskp';
use constant JSKP_SECRET => 'secret of jskp';
use constant DROPBOX_KEY => 'key of dropbox';
use constant DROPBOX_SECRET => 'secret of dropbox';
use constant BAIDUYUN_KEY => 'key of baiduyun';
use constant BAIDUYUN_SECRET => 'secret of baiduyun';
use constant NET_ADDR => '127.0.0.1:3000';
use constant EMAIL_ADDR => 'address of email';
use constant EMAIL_PASS => 'password of email';
use constant SMTP_ADDR => 'address of smtp';
use constant APP_SECRET => "secret of app";

1;

__END__
