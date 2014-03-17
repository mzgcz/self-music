package SelfMusic::Mobile;
use Mojo::Base 'Mojolicious::Controller';

sub index {
  my $self = shift;

  $self->render();
}

sub play {
  my $self = shift;

  $self->render();
}

1;
