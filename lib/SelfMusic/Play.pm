package SelfMusic::Play;

use utf8;
use Mojo::JSON;
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
    my (%self_music, %self_path);
    my @play_list = $self->self_kuaipan->get_play_list(\%self_music, \%self_path, $oauth_token, $oauth_token_secret);
    $self->stash(plist => \@play_list);
    $self->stash(lists => \%self_music);
    $self->stash(paths => \%self_path);
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

sub demo {
  my $self = shift;
  my $url = "http://$self_net/play?user=c2VsZi5tdXNpYy5lZ0BnbWFpbC5jb20%3D&id=a322abeff15f3a66dc5a099ae77b4c21";
  return $self->redirect_to($url);
}

1;

__END__
