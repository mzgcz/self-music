package SelfMusic;

use Mojo::Base 'Mojolicious';
use SelfDB;
use KuaiPan;
use SelfConf;
use Register;
use SelfCommon;

sub startup {
  my $self = shift;
  
  $self->config(hypnotoad => {listen => ['http://*:3000'], workers => 3});
  
  $self->secret(SelfConf::APP_SECRET);
  
  my $self_db = SelfDB->new;
  $self->helper(self_db => sub { return $self_db });
  
  my $self_kuaipan = KuaiPan->new;
  $self->helper(self_kuaipan => sub { return $self_kuaipan });
  
  my $self_register = Register->new;
  $self->helper(self_register => sub { return $self_register });
  
  my $r = $self->routes;
  
  $self->self_db->create_db();
  
  $r->get('/')->to('login#index')->name('index');
  $r->get('/register')->to('login#register')->name('register');
  $r->get('/login')->to('login#login')->name('login');
  $r->get('/token')->to('login#token')->name('token');
  $r->get('/play')->to('play#play')->name('play');
  $r->get('/music')->to('play#music')->name('music');
}

1;

__END__
