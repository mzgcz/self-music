#!/usr/bin/env perl

use utf8;
use Mojolicious::Lite;

app->config(hypnotoad => {listen => ['http://*:80'], workers => 3});

# Documentation browser under "/perldoc"
plugin 'PODRenderer';

get '/' => sub {
  my $self = shift;
  $self->render('index');
};

get '/*' => sub {
  my $self = shift;
  $self->render('index');
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Self Music - 自己的音乐';
<div class="row-fluid">
  <div class="span12">
    <div class="alert alert-info" style="text-align:center">
      网站升级中，请稍候再来。
    </div>
  </div>
</div>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <title><%= title %></title>
    <link href="/bootstrap/css/bootstrap.min.css" rel="stylesheet"/>
  </head>
  <body><div class="container"><%= content %></div></body>
</html>
