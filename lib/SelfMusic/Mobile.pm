package SelfMusic::Mobile;
use utf8;
use SelfConf;
use Mojo::Base 'Mojolicious::Controller';

my $self_net = SelfConf::NET_ADDR;

sub index {
  my $self = shift;
  my $user = $self->self_register->decode_user($self->param('user'));
  my $id = $self->param('id');
  my ($num, $id_db, $oauth_token, $oauth_token_secret, $netbox) = $self->self_db->get_user_info($user);
  my ($response, $rspn_type, @play_list);
  if ($num < 1) {
    $response = '未发现你的帐号，请重新注册';
    $rspn_type = 'error';
  } elsif ($id ne $id_db) {
    $response = '登录地址已过期，请使用新地址登录或重新注册获取新地址';
    $rspn_type = 'error';
  } else {
    $response = '登录成功';
    $rspn_type = 'success';

    my $self_plist = $self->self_db->get_user_plist($user);
    @play_list = SelfCommon::sort_by_pinyin(keys %{$self_plist->{"music"}});
  }

  $self->stash(response => $response);
  $self->stash(rspn_type => $rspn_type);
  $self->stash(plist => \@play_list);
  $self->stash(puser => $self->self_register->encode_user($user));
  $self->stash(pid => $id);
  $self->stash(pnet => $self_net);
  $self->render();
}

sub play {
  my $self = shift;
  my $user = $self->self_register->decode_user($self->param('user'));
  my $id = $self->param('id');
  my $item = $self->param('item');
  my $self_plist = $self->self_db->get_user_plist($user);

  $self->stash(pitem => $item);
  $self->stash(list => $self_plist->{"music"}->{$item});
  $self->stash(path => $self_plist->{"path"}->{$item});
  $self->stash(puser => $self->self_register->encode_user($user));
  $self->stash(pid => $id);
  $self->stash(pnet => $self_net);

  $self->render();
}

1;
