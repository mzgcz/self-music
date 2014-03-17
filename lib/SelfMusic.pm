package SelfMusic;

use Mojo::Base 'Mojolicious';
use SelfDB;
use KuaiPan;
use DropBox;
use BaiDuYun;
use SelfConf;
use Register;
use SelfCommon;

sub refresh_user_token {
  my $self = shift;
    
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
  if (1==$mday || 15==$mday) {
    my $refresh_info = $self->self_db->get_user_refresh_info();
    foreach my $info (@$refresh_info) {
      my ($user, $id, $refresh_token) = @$info;
      my ($new_refresh_token, $new_access_token) = $self->self_baiduyun->refresh_token($refresh_token);
      if ($new_access_token && $new_refresh_token) {
        $self->self_db->save_user_info($user, $id, $new_access_token, $new_refresh_token);
      }
    }
  }
}

sub startup {
  my $self = shift;
  
  $self->config(hypnotoad => {listen => ['http://*:80'], workers => 3});
  
  # $self->secret(SelfConf::APP_SECRET);
  
  my $self_db = SelfDB->new;
  $self->helper(self_db => sub { return $self_db });
  
  my $self_kuaipan = KuaiPan->new;
  $self->helper(self_kuaipan => sub { return $self_kuaipan });
  
  my $self_dropbox = DropBox->new;
  $self->helper(self_dropbox => sub { return $self_dropbox });
  
  my $self_baiduyun = BaiDuYun->new;
  $self->helper(self_baiduyun => sub { return $self_baiduyun });
  
  my $self_register = Register->new;
  $self->helper(self_register => sub { return $self_register });
  
  my $r = $self->routes;
  
  $self->self_db->create_db();
  refresh_user_token($self);
  
  $r->get('/')->to('login#index')->name('index');
  $r->get('/manual')->to('login#manual')->name('manual');
  $r->get('/register')->to('login#register')->name('register');
  $r->get('/login')->to('login#login')->name('login');
  $r->get('/pretoken')->to('login#pretoken')->name('pretoken');
  $r->get('/token')->to('login#token')->name('token');
  $r->get('/play')->to('play#play')->name('play');
  $r->get('/sync')->to('play#sync')->name('sync');
  $r->get('/music')->to('play#music')->name('music');
  $r->get('/demo')->to('play#demo')->name('demo');

  $r->get('/mobile')->to('mobile#index');
  $r->get('/mobile/play')->to('mobile#play');
}

1;

__END__
