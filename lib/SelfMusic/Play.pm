package SelfMusic::Play;

use utf8;
use SelfConf;
use Mojo::Base 'Mojolicious::Controller';

my $self_net = SelfConf::NET_ADDR;

sub play {
  my $self = shift;
  my $user = $self->self_register->decode_user($self->param('user'));
  my $id = $self->param('id');
  my ($num, $id_db, $oauth_token, $oauth_token_secret, $netbox) = $self->self_db->get_user_info($user);
  my ($response, $rspn_type);
  if ($num < 1) {
    $response = '未发现你的帐号，请重新注册';
    $rspn_type = 'error';
  } elsif ($id ne $id_db) {
    $response = '登录地址已过期，请使用新地址登录或重新注册获取新地址';
    $rspn_type = 'error';
  } else {
    my $self_plist = $self->self_db->get_user_plist($user);
    my @play_list = SelfCommon::sort_by_pinyin(keys %{$self_plist->{"music"}});
    
    $self->stash(plist => \@play_list);
    $self->stash(netbox => $netbox);
    $self->stash(lists => $self_plist->{"music"});
    $self->stash(paths => $self_plist->{"path"});
    $self->stash(puser => $self->self_register->encode_user($user));
    $self->stash(pid => $id);
    $self->stash(pnet => $self_net);
    $self->stash(email => SelfConf::EMAIL_ADDR);
    return $self->render('play');
  }
  
  $self->stash(email => SelfConf::EMAIL_ADDR);
  $self->stash(net => $self_net);
  $self->stash(response => $response);
  $self->stash(rspn_type => $rspn_type);
  $self->render('index');
}

sub sync {
  my $self = shift;
  my $user = $self->self_register->decode_user($self->param('user'));
  my $id = $self->param('id');
  my ($num, $id_db, $oauth_token, $oauth_token_secret, $netbox) = $self->self_db->get_user_info($user);
  my $response;
  if ($num < 1) {
    $response = qq{
<div class="alert alert-error">
  出错啦：未发现你的帐号，请重新注册
</div>
};
  } elsif ($id ne $id_db) {
    $response = qq{
<div class="alert alert-error">
  出错啦：登录地址已过期，请使用新地址登录或重新注册获取新地址
</div>
};
  } else {
    my $self_plist;
    if ($netbox eq 'jskp') {
      $self_plist = $self->self_kuaipan->get_play_list($oauth_token, $oauth_token_secret);
    } elsif ($netbox eq 'bdwp') {
      $self_plist = $self->self_baiduyun->get_play_list($oauth_token, $oauth_token_secret);
    } elsif ($netbox eq 'dropbox') {
      $self_plist = $self->self_dropbox->get_play_list($oauth_token, $oauth_token_secret);
    }
    $self->self_db->save_user_plist($user, $self_plist);
    $response = 'succeed';
  }
  $self->render_text($response);
}

sub music {
  my $self = shift;
  my $user = $self->self_register->decode_user($self->param('user'));
  my $id = $self->param('id');
  my $music = $self->param('song');
  my ($num, $id_db, $oauth_token, $oauth_token_secret, $netbox) = $self->self_db->get_user_info($user);
  my $response;
  if ($num < 1) {
    $response = '出错啦：未发现你的帐号，请重新注册';
  } elsif ($id ne $id_db) {
    $response = '出错啦：登录地址已过期，请使用新地址登录或重新注册获取新地址';
  } else {
    my $url;
    if ($netbox eq 'jskp') {
      $url = $self->self_kuaipan->get_file_url($music, $oauth_token, $oauth_token_secret);
    } elsif ($netbox eq 'bdwp') {
      $url = $self->self_baiduyun->get_file_url($music, $oauth_token, $oauth_token_secret);
    } elsif ($netbox eq 'dropbox') {
      $url = $self->self_dropbox->get_file_url($music, $oauth_token, $oauth_token_secret);
    }
    return $self->redirect_to($url);
  }
  $self->redirect_to("/error.mp3");
}

sub demo {
  my $self = shift;
  my $url = "http://www.self-app.net/play?user=c2VsZi5tdXNpYy5lZ0BnbWFpbC5jb20%3D&id=a3c8919a5fbc9a68aa2d2d5a29d69c10";
  return $self->redirect_to($url);
}

1;

__END__
