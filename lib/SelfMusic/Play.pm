package SelfMusic::Play;

use utf8;
use Mojo::Base 'Mojolicious::Controller';

my $self_net = SelfConf::NET_ADDR;

sub play {
  my $self = shift;
  my $user = $self->self_register->decode_user($self->param('user'));
  my $id = $self->param('id');
  my ($num, $id_db, $oauth_token, $oauth_token_secret) = $self->self_db->get_user_info($user);
  if ($num < 1) {
    $self->render('error', reason=>'未发现你的帐号，请重新注册');
  } elsif ($id ne $id_db) {
    $self->render('error', reason=>'你使用的登录地址已过期，请使用新地址登录或重新注册获取新地址');
  } else {
    my @music_list =  $self->self_kuaipan->get_file_list($oauth_token, $oauth_token_secret);
    $self->stash(plist => \@music_list);
    $self->stash(puser => $self->self_register->encode_user($user));
    $self->stash(pid => $id);
    $self->stash(pnet => $self_net);
    $self->stash(email => SelfConf::EMAIL_ADDR);
    $self->render('play');
  }
}

sub music {
  my $self = shift;
  my $user = $self->self_register->decode_user($self->param('user'));
  my $id = $self->param('id');
  my $music = $self->param('song');
  my ($num, $id_db, $oauth_token, $oauth_token_secret) = $self->self_db->get_user_info($user);
  if ($num < 1) {
    $self->render('error', reason=>'未发现你的帐号，请重新注册');
  } elsif ($id ne $id_db) {
    $self->render('error', reason=>'你使用的登录地址已过期，请使用新地址登录或重新注册获取新地址');
  } else {
    my $url = $self->self_kuaipan->get_file_url($music, $oauth_token, $oauth_token_secret);
    return $self->redirect_to($url);
  }
}

1;

__END__
