package SelfConf;
use parent qw(Exporter);

use strict;

our @EXPORT = qw(JSKP_KEY JSKP_SECRET NET_ADDR EMAIL_ADDR EMAIL_PASS SMTP_ADDR APP_SECRET);
our $VERSION = 0.10;

use constant JSKP_KEY => '金山快盘应用的KEY';
use constant JSKP_SECRET => '金山快盘应用的SECRET';
use constant NET_ADDR => '应用网址';
use constant EMAIL_ADDR => '电子邮箱地址';
use constant EMAIL_PASS => '电子邮箱密码';
use constant SMTP_ADDR => '电子邮箱外发服务器地址';
use constant APP_SECRET => '应用密码';

1;

__END__
