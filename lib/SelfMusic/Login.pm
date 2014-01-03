package SelfMusic::Login;

use utf8;
use SelfConf;
use Mojo::Base 'Mojolicious::Controller';

my $self_net = SelfConf::NET_ADDR;

sub index {
  my $self = shift;
  
  $self->stash(email => SelfConf::EMAIL_ADDR);
  $self->stash(net => $self_net);
  $self->stash(response => '');
  $self->stash(rspn_type => 'none');
  $self->render('index');
}

sub register {
  my $self = shift;
  my $mail = $self->param('email');
  my $netbox = $self->param('netbox');
  my $response;
  if ($mail && $netbox) {
    my ($url, $id) = $self->self_register->get_login_addr("http://$self_net/login", $mail);
    $self->self_db->user_register($mail, $id, $netbox);
    $self->self_register->send_register_mail($mail, $url);
    $response = qq{
<div class="alert alert-success">
  登录地址已发送到你邮箱，请从邮箱登录
</div>
};
  } else {
    $response = qq{
<div class="alert alert-error">
  出错啦：请填入正确的邮箱地址
</div>
};
  }
  $self->render_text($response);
}

sub login {
  my $self = shift;
  my $user = $self->self_register->decode_user($self->param('user'));
  my $id = $self->param('id');
  my ($info_num, $id_db, $token_db, $token_secret_db, $netbox_db) = $self->self_db->get_user_info($user);
  my ($response, $rspn_type);
  if ($info_num < 1) {
    $response = '未发现你的帐号，请重新注册';
    $rspn_type = 'error';
  } elsif ($id ne $id_db) {
    $response = '登录地址已过期，请使用新地址登录或重新注册获取新地址';
    $rspn_type = 'error';
  } elsif ($token_db && $token_secret_db) {
    return $self->redirect_to($self->self_register->get_play_addr($self_net, $user, $id));
  } else {
    my ($url, $oauth_token, $oauth_token_secret);
    if ($netbox_db eq 'jskp') {
      ($url, $oauth_token, $oauth_token_secret) = $self->self_kuaipan->request_token($self->self_register->get_token_addr($self_net, $user, $id));
    } elsif ($netbox_db eq 'bdwp') {
      $url = $self->self_baiduyun->request_token($self->self_register->get_pretoken_addr($self_net, $user, $id));
      return $self->redirect_to($url);
    } elsif ($netbox_db eq 'dropbox') {
        ($url, $oauth_token, $oauth_token_secret) = $self->self_dropbox->request_token($self->self_register->get_token_addr($self_net, $user, $id));
    }
    if ($oauth_token) {
      $self->self_db->record_pretoken($user, $id, $oauth_token, $oauth_token_secret, $netbox_db);
      return $self->redirect_to($url);
    } else {
      $response = '预授权失败，请重新授权';
      $rspn_type = 'error';
    }
  }
  
  $self->stash(email => SelfConf::EMAIL_ADDR);
  $self->stash(net => $self_net);
  $self->stash(response => $response);
  $self->stash(rspn_type => $rspn_type);
  $self->render('index');
}

sub pretoken {
    my $self = shift;
    my $user = $self->self_register->decode_user($self->param('user'));
    my $id = $self->param('id');
    my $code = $self->param('code');
    my ($response, $rspn_type);
    if (defined($code)) {
        my ($refresh_token, $access_token) = $self->self_baiduyun->access_token($code, $self->self_register->get_pretoken_addr($self_net, $user, $id));
        if ($access_token && $refresh_token) {
            $self->self_db->save_user_info($user, $id, $access_token, $refresh_token);
            my $play_url = $self->self_register->get_play_addr($self_net, $user, $id);
            return $self->redirect_to($play_url);
        } else {
            $response = '授权失败，请重新授权';
            $rspn_type = 'error';
        }
    } else {
        $response = '预授权失败，请重新授权';
        $rspn_type = 'error';
    }

    $self->stash(email => SelfConf::EMAIL_ADDR);
    $self->stash(net => $self_net);
    $self->stash(response => $response);
    $self->stash(rspn_type => $rspn_type);
    $self->render('index');
}

sub token {
  my $self = shift;
  my $user = $self->self_register->decode_user($self->param('user'));
  my $id = $self->param('id');
  my $pre_oauth_token = $self->param('oauth_token');
  my $verifier = $self->param('oauth_verifier');
  my ($num, $pre_oauth_token_secret, $netbox_db) = $self->self_db->get_pretoken_secret($user, $id, $pre_oauth_token);
  my ($response, $rspn_type);
  if ($num < 1) {
    $response = '预授权失败，请重新授权';
    $rspn_type = 'error';
  } else {
    $self->self_db->delete_pretoken_secret($user, $id, $pre_oauth_token);
    my ($oauth_token, $oauth_token_secret);
    if ($netbox_db eq 'jskp') {
      ($oauth_token, $oauth_token_secret) = $self->self_kuaipan->access_token($pre_oauth_token, $pre_oauth_token_secret, $verifier);
    } elsif ($netbox_db eq 'dropbox') {
      ($oauth_token, $oauth_token_secret) = $self->self_dropbox->access_token($pre_oauth_token, $pre_oauth_token_secret);
    }
    if ($oauth_token && $oauth_token_secret) {
      $self->self_db->save_user_info($user, $id, $oauth_token, $oauth_token_secret);
      my $play_url = $self->self_register->get_play_addr($self_net, $user, $id);
      return $self->redirect_to($play_url);
    } else {
      $response = '授权失败，请重新授权';
      $rspn_type = 'error';
    }
  }
  
  $self->stash(email => SelfConf::EMAIL_ADDR);
  $self->stash(net => $self_net);
  $self->stash(response => $response);
  $self->stash(rspn_type => $rspn_type);
  $self->render('index');
}

1;

__END__
