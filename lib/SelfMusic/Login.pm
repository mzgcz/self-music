package SelfMusic::Login;

use utf8;
use Mojo::Base 'Mojolicious::Controller';

my $self_net = SelfConf::NET_ADDR;

sub index {
  my $self = shift;
  
  $self->stash(email => SelfConf::EMAIL_ADDR);
  $self->stash(net => $self_net);
  $self->render('index');
}

sub register {
  my $self = shift;
  my $mail = $self->param('email');
  if ($mail) {
    my ($url, $id) = $self->self_register->get_login_addr("http://$self_net/login", $mail);
    $self->self_db->user_register($mail, $id);
    $self->self_register->send_register_mail($mail, $url);
      
    $self->render('register');
  } else {
    return $self->redirect_to('index');
  }
}

sub login {
  my $self = shift;
  my $user = $self->self_register->decode_user($self->param('user'));
  my $id = $self->param('id');
  my ($info_num, $id_db, $token_db, $token_secret_db) = $self->self_db->get_user_info($user);
  if ($info_num < 1) {
    $self->render('error', reason=>'未发现你的帐号，请重新注册');
  } elsif ($id ne $id_db) {
    $self->render('error', reason=>'你使用的登录地址已过期，请使用新地址登录或重新注册获取新地址');
  } elsif ($token_db && $token_secret_db) {
    return $self->redirect_to($self->self_register->get_play_addr($self_net, $user, $id));
  } else {
    my ($oauth_token, $oauth_token_secret) = $self->self_kuaipan->request_token($self->self_register->get_token_addr($self_net, $user, $id));
    if ($oauth_token) {
      $self->self_db->record_pretoken($user, $id, $oauth_token, $oauth_token_secret);
      return $self->redirect_to($self->self_kuaipan->authorize_token($oauth_token));
    } else {
      $self->render('error', reason=>'预授权失败');
    }
  }
}

sub token {
  my $self = shift;
  my $user = $self->self_register->decode_user($self->param('user'));
  my $id = $self->param('id');
  my $pre_oauth_token = $self->param('oauth_token');
  my ($num, $pre_oauth_token_secret) = $self->self_db->get_pretoken_secret($user, $id, $pre_oauth_token);
  if ($num < 1) {
    $self->render('error', reason=>'预授权出错，请重新进行授权');
  } else {
    $self->self_db->delete_pretoken_secret($user, $id, $pre_oauth_token);
    my ($oauth_token, $oauth_token_secret) = $self->self_kuaipan->access_token($pre_oauth_token, $pre_oauth_token_secret);
    if ($oauth_token && $oauth_token_secret) {
      $self->self_db->save_user_info($user, $id, $oauth_token, $oauth_token_secret);
      my $play_url = $self->self_register->get_play_addr($self_net, $user, $id);
      return $self->redirect_to($play_url);
    } else {
      $self->render('error', reason=>'授权失败');
    }
  }
}

1;

__END__
