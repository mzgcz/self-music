package BaiDuYun;

use strict;
use warnings;
use SelfConf;
use Mojo::JSON;
use File::Basename;
use LWP::UserAgent;

sub new { bless {}, shift }

sub request_token {
    my ($self, $cb_url) = @_;
    my $oauth_url = 'https://openapi.baidu.com/oauth/2.0/authorize';
    my %parameters = (
        response_type => 'code',
        client_id => SelfConf::BAIDUYUN_KEY,
        redirect_uri => SelfCommon::url_to_url($cb_url),
        scope => 'netdisk',
        );
    
    return $oauth_url.'?'.SelfCommon::combination_parameters(\%parameters);
}

sub access_token {
    my ($self, $code, $cb_url) = @_;
    my $access_url = 'https://openapi.baidu.com/oauth/2.0/token';
    my %parameters = (
        grant_type => 'authorization_code',
        code => $code,
        client_id => SelfConf::BAIDUYUN_KEY,
        client_secret => SelfConf::BAIDUYUN_SECRET,
        redirect_uri => SelfCommon::url_to_url($cb_url),
        );
    
    my $url = $access_url.'?'.SelfCommon::combination_parameters(\%parameters);
    my $ua = LWP::UserAgent->new;
    $ua->timeout(5);
    my $req = HTTP::Request->new(GET => $url);
    my $res = $ua->request($req);
    my ($refresh_token, $access_token);
    if ($res->is_success) {
        my $json = Mojo::JSON->new;
        my $access_info = $json->decode($res->content);
        $refresh_token = $access_info->{'refresh_token'};
        $access_token = $access_info->{'access_token'};
    }
    
    return  ($refresh_token, $access_token);
}

sub refresh_token {
    my ($self, $refresh_token) = @_;
    my $access_url = 'https://openapi.baidu.com/oauth/2.0/token';
    my %parameters = (
        grant_type => 'refresh_token',
        refresh_token => $refresh_token,
        client_id => SelfConf::BAIDUYUN_KEY,
        client_secret => SelfConf::BAIDUYUN_SECRET,
        scope => 'netdisk',
        );
    
    my $url = $access_url.'?'.SelfCommon::combination_parameters(\%parameters);
    my $ua = LWP::UserAgent->new;
    $ua->timeout(5);
    my $req = HTTP::Request->new(GET => $url);
    my $res = $ua->request($req);
    my ($new_refresh_token, $new_access_token);
    if ($res->is_success) {
        my $json = Mojo::JSON->new;
        my $access_info = $json->decode($res->content);
        $new_refresh_token = $access_info->{'refresh_token'};
        $new_access_token = $access_info->{'access_token'};
    }
    
    return ($new_refresh_token, $new_access_token);
}

sub get_one_list {
  my @musics;
  my ($self_music, $self_path, $token, $token_secret, $level, $path) = @_;
  my $list_url = 'https://pcs.baidu.com/rest/2.0/pcs/file';
  my %parameters = (
      method => 'list',
      access_token => $token,
      path => SelfCommon::utf8_to_url($path),
      );
  
  my $url = $list_url.'?'.SelfCommon::combination_parameters(\%parameters);
  my $ua = LWP::UserAgent->new;
  $ua->timeout(5);
  my $req = HTTP::Request->new(GET => $url);
  my $res = $ua->request($req);
  if ($res->is_success) {
      my $json = Mojo::JSON->new;
      my $access_json = $json->decode($res->content);
      foreach my $file (@{$access_json->{"list"}}) {
          if ($file->{"isdir"} eq '0') {
              if ($file->{"path"} =~ /\.mp3$/i) {
                  push @musics, basename($file->{"path"});
              }
          } elsif ($file->{"isdir"} eq '1') {
              if (0 == $level) {
                  get_one_list($self_music, $self_path, $token, $token_secret, $level+1, $file->{"path"});
              }
          }
      }
  }
  my $list_name = basename($path);
  @musics = SelfCommon::sort_by_pinyin(@musics);
  $self_music->{$list_name} = \@musics;
  $self_path->{$list_name} = $path;
}

sub get_play_list {
  my ($self, $token, $token_secret) = @_;
  
  my (%self_music, %self_path);
  get_one_list(\%self_music, \%self_path, $token, $token_secret, 0, '/apps/self-music');
  
  my %self_plist;
  $self_plist{"music"} = \%self_music;
  $self_plist{"path"} = \%self_path;
  
  return \%self_plist;
}

sub get_file_url {
  my ($self, $file, $token, $token_secret) = @_;
  my $file_url = 'https://pcs.baidu.com/rest/2.0/pcs/stream';
  my %parameters = (
      method => 'download',
      access_token => $token,
      path => SelfCommon::utf8_to_url($file),
      );
  
  return $file_url.'?'.SelfCommon::combination_parameters(\%parameters);
}

1;

__END__
