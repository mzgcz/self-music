#!/usr/bin/env perl

BEGIN {
    push (@INC,'/opt/self-music');
}

use utf8;
use SelfDB;
use KuaiPan;
use SelfConf;
use Register;
use SelfCommon;
use Mojolicious::Lite;

app->config(hypnotoad => {listen => ['http://*:80'], workers => 3});

# Documentation browser under "/perldoc"
plugin 'PODRenderer';

SelfDB::create_db();

my $self_net = SelfConf::NET_ADDR;

get '/' => sub {
  my $self = shift;
  
  $self->stash(email => SelfConf::EMAIL_ADDR);
  $self->render('index');
};

get '/register' => sub {
  my $self = shift;
  my $mail = $self->param('email');
  if ($mail) {
      my ($url, $id) = Register::get_login_addr("http://$self_net/login", $mail);
      SelfDB::user_register($mail, $id);
      Register::send_register_mail($mail, $url);
      
      $self->render('register');
  } else {
      return $self->redirect_to("http://$self_net");
  }
};

get '/login' => sub {
  my $self = shift;
  my $user = Register::decode_user($self->param('user'));
  my $id = $self->param('id');
  my ($info_num, $id_db, $token_db, $token_secret_db) = SelfDB::get_user_info($user);
  if ($info_num < 1) {
    $self->render('error', reason=>'未发现你的帐号，请重新注册');
  } elsif ($id ne $id_db) {
    $self->render('error', reason=>'你使用的登录地址已过期，请使用新地址登录或重新注册获取新地址');
  } elsif ($token_db && $token_secret_db) {
    return $self->redirect_to(Register::get_play_addr($self_net, $user, $id));
  } else {
    my ($oauth_token, $oauth_token_secret) = KuaiPan::request_token(Register::get_token_addr($self_net, $user, $id));
    if ($oauth_token) {
      SelfDB::record_pretoken($user, $id, $oauth_token, $oauth_token_secret);
      return $self->redirect_to(KuaiPan::authorize_token($oauth_token));
    } else {
      $self->render('error', reason=>'预授权失败');
    }
  }
};

get '/token' => sub {
  my $self = shift;
  my $user = Register::decode_user($self->param('user'));
  my $id = $self->param('id');
  my $pre_oauth_token = $self->param('oauth_token');
  my ($num, $pre_oauth_token_secret) = SelfDB::get_pretoken_secret($user, $id, $pre_oauth_token);
  if ($num < 1) {
    $self->render('error', reason=>'预授权出错，请重新进行授权');
  } else {
    SelfDB::delete_pretoken_secret($user, $id, $pre_oauth_token);
    my ($oauth_token, $oauth_token_secret) = KuaiPan::access_token($pre_oauth_token, $pre_oauth_token_secret);
    if ($oauth_token && $oauth_token_secret) {
      SelfDB::save_user_info($user, $id, $oauth_token, $oauth_token_secret);
      my $play_url = Register::get_play_addr($self_net, $user, $id);
      return $self->redirect_to($play_url);
    } else {
      $self->render('error', reason=>'授权失败');
    }
  }
};

get '/play' => sub {
  my $self = shift;
  my $user = Register::decode_user($self->param('user'));
  my $id = $self->param('id');
  my ($num, $id_db, $oauth_token, $oauth_token_secret) = SelfDB::get_user_info($user);
  if ($num < 1) {
    $self->render('error', reason=>'未发现你的帐号，请重新注册');
  } elsif ($id ne $id_db) {
    $self->render('error', reason=>'你使用的登录地址已过期，请使用新地址登录或重新注册获取新地址');
  } else {
    my @music_list =  get_file_list($oauth_token, $oauth_token_secret);
    $self->stash(plist => \@music_list);
    $self->stash(puser => Register::encode_user($user));
    $self->stash(pid => $id);
    $self->stash(pnet => $self_net);
    $self->stash(email => SelfConf::EMAIL_ADDR);
    $self->render('play');
  }
};

get '/music' => sub {
  my $self = shift;
  my $user = Register::decode_user($self->param('user'));
  my $id = $self->param('id');
  my $music = $self->param('song');
  my ($num, $id_db, $oauth_token, $oauth_token_secret) = SelfDB::get_user_info($user);
  if ($num < 1) {
    $self->render('error', reason=>'未发现你的帐号，请重新注册');
  } elsif ($id ne $id_db) {
    $self->render('error', reason=>'你使用的登录地址已过期，请使用新地址登录或重新注册获取新地址');
  } else {
    my $url = get_file_url($music, $oauth_token, $oauth_token_secret);
    return $self->redirect_to($url);
  }
};

app->secret(SelfConf::APP_SECRET);

app->start;
__DATA__

@@ index.html.ep
% layout 'index';
% title 'Self Music - 自己的音乐';
<div class="row-fluid">
  <div class="span12">
    <div class="hero-unit">
      <h1>Self Music - 自己的音乐</h1>
    </div>
  </div>
</div>
<div class="row-fluid">
  <div class="span8">
    <div>
      <table class="table table-striped">
        <tbody>
          <tr>
            <td><span class="label label-info">简介</span></td>
            <td>self-music 是由 self-app 提供的在线音乐播放服务，用于播放用户网盘中的音乐</td>
          </tr>
          <tr>
            <td><span class="label label-info">音乐</span></td>
            <td>支持 HTML5 指定的 mp3、ogg 和 m4a 等格式，具体依赖各浏览器的支持情况</td>
          </tr>
          <tr>
            <td><span class="label label-info">浏览器</span></td>
            <td>支持谷歌浏览器、搜狗高速浏览器、360安全浏览器超速版，猎豹浏览器，……</td>
          </tr>
          <tr>
            <td><span class="label label-success">建议和支持</span></td>
            <td>把您的建议和支持发送至邮箱 <%= $email %></td>
          </tr>
          <tr>
            <td><span class="label label-warning">牢骚和抱怨</span></td>
            <td>把你的牢骚和抱怨发送至邮箱 <%= $email %></td>
          </tr>
          <tr>
            <td><span class="label label-important">重要的提示</span></td>
            <td>本网页专注于用户注册，注册后登录地址自动发送到注册邮箱，请从邮箱进行登录</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
  <div class="span4">
    <form class="well" action="/register" method="get">
      <fieldset>
        <legend>注册 或 忘记密码</legend>
        <div class="control-group">
          <div class="controls">
            <input type="email" class="input-big" placeholder="电子邮件" name="email" />
            <button type="submit" class="btn btn-primary btn-large">确定</button>
          </div>
        </div>
      </fieldset>
    </form>
  </div>
</div>

@@ register.html.ep
% layout 'default';
% title 'Self Music - 自己的音乐';
<div class="alert alert-success" style="text-align:center">
  登录地址已发送到你邮箱，请从邮箱登录。
</div>

@@ error.html.ep
% layout 'default';
% title 'Error';
<div class="alert alert-error"  style="text-align:center">
  出错啦！<%= $reason %>
</div>

@@ play.html.ep
% layout 'player';
% title 'slef-music';
<script type="text/javascript">
    //<![CDATA[
    $(document).ready(function(){
        
	new jPlayerPlaylist({
	    jPlayer: "#jquery_jplayer_1",
	    cssSelectorAncestor: "#jp_container_1"
	}, [
                % for my $music (@$plist) {
                        % $music =~ /^(.*)\.\w+$/;
                        % my $name = $1;
                        % my $murl = SelfCommon::utf8_to_url($music);
                {
                  title:"<%= $name %>",
                % if ($music =~ /\.mp3$/i) {
                    mp3:"http://<%= $pnet %>/music?user=<%= $puser %>&id=<%= $pid %>&song=<%= $murl %>"
                % } elsif ($music =~ /\.ogg$/i) {
                    oga:"http://<%= $pnet %>/music?user=<%= $puser %>&id=<%= $pid %>&song=<%= $murl %>"
                % } elsif ($music =~ /\.m4a$/i) {
                    m4a:"http://<%= $pnet %>/music?user=<%= $puser %>&id=<%= $pid %>&song=<%= $murl %>"
                % }
                },
            % }
	], {
	    swfPath: "js",
	    supplied: "m4a, oga, mp3",
	    wmode: "window"
	});
    });
//]]>
</script>
<div class="navbar navbar-fixed-top">
  <div class="navbar-inner">
    <div class="container">
      <a class="brand" href="#">
        Self Music - 自己的音乐
      </a>
      <ul class="nav">
        <li class="active">
          <a href="#">播放</a>
        </li>
        <li><a href="http://<%= $pnet %>">账户重置</a></li>
        <li><a href="mailto:<%= $email %>">联系我们</a></li>
        <li><a href="http://mzgcz.github.com/self-music">协助与支持</a></li>
      </ul>
    </div>
  </div>
</div>
<div id="jquery_jplayer_1" class="jp-jplayer"></div>
<div id="jp_container_1" class="jp-audio">
  <div class="jp-type-playlist">
    <div class="subnav navbar-fixed-bottom">
      <div class="jp-gui jp-interface">
        <ul class="jp-controls">
	  <li><a href="javascript:;" class="jp-previous" tabindex="1">previous</a></li>
	  <li><a href="javascript:;" class="jp-play" tabindex="1">play</a></li>
	  <li><a href="javascript:;" class="jp-pause" tabindex="1">pause</a></li>
	  <li><a href="javascript:;" class="jp-next" tabindex="1">next</a></li>
	  <li><a href="javascript:;" class="jp-stop" tabindex="1">stop</a></li>
	  <li><a href="javascript:;" class="jp-mute" tabindex="1" title="mute">mute</a></li>
	  <li><a href="javascript:;" class="jp-unmute" tabindex="1" title="unmute">unmute</a></li>
	  <li><a href="javascript:;" class="jp-volume-max" tabindex="1" title="max volume">max volume</a></li>
        </ul>
        <div class="jp-progress">
	  <div class="jp-seek-bar">
	    <div class="jp-play-bar"></div>
	  </div>
        </div>
        <div class="jp-volume-bar">
	  <div class="jp-volume-bar-value"></div>
        </div>
        <div class="jp-time-holder">
	  <div class="jp-current-time"></div>
	  <div class="jp-duration"></div>
        </div>
        <ul class="jp-toggles">
	  <li><a href="javascript:;" class="jp-shuffle" tabindex="1" title="shuffle">shuffle</a></li>
	  <li><a href="javascript:;" class="jp-shuffle-off" tabindex="1" title="shuffle off">shuffle off</a></li>
	  <li><a href="javascript:;" class="jp-repeat" tabindex="1" title="repeat">repeat</a></li>
	  <li><a href="javascript:;" class="jp-repeat-off" tabindex="1" title="repeat off">repeat off</a></li>
        </ul>
      </div>
    </div>
    <div class="jp-playlist">
      <ul>
	<li></li>
      </ul>
    </div>
    <div class="jp-no-solution">
      <span>Update Required</span>
      To play the media you will need to either update your browser to a recent version or update your <a href="http://get.adobe.com/flashplayer/" target="_blank">Flash plugin</a>.
    </div>
  </div>
</div>

@@ layouts/index.html.ep
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title><%= title %></title>
    <link href="bootstrap/css/bootstrap.min.css" rel="stylesheet" type="text/css" />
  </head>
  <body>
    <div class="container">
      <%= content %>
    </div>
  </body>
</html>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title><%= title %></title>
    <link href="bootstrap/css/bootstrap.min.css" rel="stylesheet" type="text/css" />
  </head>
  <body>
    <div class="container">
      <div class="row-fluid">
        <div class="span12">
          <%= content %>
        </div>
      </div>
    </div>
  </body>
</html>

@@ layouts/player.html.ep
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title><%= title %></title>
    <link href="bootstrap/css/bootstrap.min.css" rel="stylesheet" type="text/css" />
    <link href="skin/blue.monday/jplayer.blue.monday.css" rel="stylesheet" type="text/css" />
    <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.6/jquery.min.js"></script>
    <script type="text/javascript" src="js/jquery.jplayer.min.js"></script>
    <script type="text/javascript" src="js/jplayer.playlist.min.js"></script>
    <style type="text/css">
      .top-bottom{padding-top:40px;padding-bottom:80px;}
    </style>
  </head>
  <body class="top-bottom">
    <div class="container">
      <div class="row-fluid">
        <div class="span12">
          <%= content %>
        </div>
      </div>
    </div>
  </body>
</html>
