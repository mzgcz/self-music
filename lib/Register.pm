package Register;

use strict;
use warnings;
use utf8;
use SelfConf;
use SelfCommon;
use Mojo::Util;
use MIME::Lite;
use MIME::Base64;
use Authen::SASL;

sub new { bless {}, shift }

sub encode_user {
  my ($self, $user) = @_;
  
  return SelfCommon::b64_and_url($user);
}

sub decode_user {
  my ($self, $user) = @_;
  
  return Mojo::Util::b64_decode($user);
}

sub get_login_addr {
  my ($self, $base_url, $mail) = @_;
  
  my $id = Mojo::Util::md5_sum($mail.SelfCommon::rand_str(32).time());
  my $url = $base_url.'?'.'user='.SelfCommon::b64_and_url($mail).'&'.'id='.$id;
  
  return ($url, $id);
}

sub get_pretoken_addr {
    my ($self, $net, $user, $id) = @_;
    
    return "http://$net/pretoken?".'user='.SelfCommon::b64_and_url($user).'&'.'id='.$id;
}

sub get_token_addr {
    my ($self, $net, $user, $id) = @_;
    
    return "http://$net/token?".'user='.SelfCommon::b64_and_url($user).'&'.'id='.$id;
}

sub get_play_addr {
    my ($self, $net, $user, $id) = @_;
    
    return "http://$net/play?".'user='.SelfCommon::b64_and_url($user).'&'.'id='.$id;
}

sub send_register_mail {
  my ($self, $mail, $url) = @_;
  
  my $host = SelfConf::SMTP_ADDR;
  my $user = SelfConf::EMAIL_ADDR;
  my $pass = SelfConf::EMAIL_PASS;
  my $msg = MIME::Lite->new(
                            From => $user,
                            To => $mail,
                            Subject => 'self-music - 自己的音乐',
                            Type => 'text/html',
                            Data => qq{
<body>
  点击<b><a href="$url" style="font-size:30px">这里</a></b>进入你的self-music<br />
或者使用以下网址：<br />
$url
</body>
});
  MIME::Lite->send('smtp', $host, Timeout=>60, AuthUser=>$user, AuthPass=>$pass);
  $msg->send;
}

1;

__END__
