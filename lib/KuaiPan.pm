package KuaiPan;

use strict;
use warnings;
use SelfConf;
use SelfCommon;
use Mojo::JSON;
require LWP::UserAgent;

sub new { bless {}, shift }

my $consumer_secret = SelfConf::JSKP_SECRET;

sub get_signature {
  return 'oauth_signature='.SelfCommon::create_autograph(@_);
}

sub get_consumer_key {
  my $consumer_key = SelfConf::JSKP_KEY;
  
  return 'oauth_consumer_key='.$consumer_key;
}

sub get_nonce {
  return 'oauth_nonce='.SelfCommon::rand_str(31);
}

sub get_signature_method {
  return 'oauth_signature_method='.'HMAC-SHA1';
}

sub get_timestamp {
  return 'oauth_timestamp='.time();
}

sub get_token {
  my $token = shift;
  
  return 'oauth_token='.$token;
}

sub get_version {
  return 'oauth_version='.'1.0';
}

sub get_callback {
  my $cb_url = shift;
  
  return 'oauth_callback='.SelfCommon::url_to_url($cb_url);
}

sub get_file_path {
  my $file = shift;
  
  return 'path='.SelfCommon::utf8_to_url($file);
}

sub get_file_root {
  return 'root='.'app_folder';
}

sub combination_para {
  my $para_str = join '&', @_;
  
  return $para_str;
}

sub request_token {
  my ($self, $cb_url) = @_;
  my $url = 'https://openapi.kuaipan.cn/open/requestToken';
  my $oauth_callback = get_callback($cb_url);
  my $oauth_consumer_key = get_consumer_key();
  my $oauth_nonce = get_nonce();
  my $oauth_signature_method = get_signature_method();
  my $oauth_timestamp = get_timestamp();
  my $oauth_version = get_version();
  my $request_para = combination_para($oauth_callback, $oauth_consumer_key,$oauth_nonce,$oauth_signature_method,$oauth_timestamp,$oauth_version);
  my $request_src = combination_para('GET',SelfCommon::url_to_url($url),SelfCommon::url_to_url($request_para));
  my $oauth_signature = get_signature($request_src, $consumer_secret.'&');
  my $request_url = $url.'?'.combination_para($oauth_signature,$request_para);
  my $json = Mojo::JSON->new;
  my $ua = LWP::UserAgent->new;
  $ua->timeout(60);
  $ua->env_proxy;
  my $response = $ua->get($request_url);
  my ($request_json, $oauth_token, $oauth_token_secret);
  if ($response->is_success) {
    $request_json = $json->decode($response->decoded_content);
    $oauth_token = $request_json->{"oauth_token"};
    $oauth_token_secret = $request_json->{"oauth_token_secret"};
  }
  
  return ($oauth_token, $oauth_token_secret);
}

sub authorize_token {
  my ($self, $oauth_token) = @_;
  my $url = 'https://www.kuaipan.cn/api.php?ac=open&op=authorise';
  
  return combination_para($url,get_token($oauth_token));
}

sub access_token {
  my ($self, $token, $token_secret) = @_;
  my $url = 'https://openapi.kuaipan.cn/open/accessToken';
  my $oauth_consumer_key = get_consumer_key();
  my $oauth_nonce = get_nonce();
  my $oauth_signature_method = get_signature_method();
  my $oauth_timestamp = get_timestamp();
  my $pre_oauth_token = get_token($token);
  my $oauth_version = get_version();
  my $access_para = combination_para($oauth_consumer_key,$oauth_nonce,$oauth_signature_method,$oauth_timestamp,$pre_oauth_token,$oauth_version);
  my $access_src = combination_para('GET',SelfCommon::url_to_url($url),SelfCommon::url_to_url($access_para));
  my $oauth_signature = get_signature($access_src, combination_para($consumer_secret,$token_secret));
  my $access_url = $url.'?'.combination_para($oauth_signature,$access_para);
  my $json = Mojo::JSON->new;
  my $ua = LWP::UserAgent->new;
  $ua->timeout(60);
  $ua->env_proxy;
  my $response = $ua->get($access_url);
  my ($access_json, $oauth_token, $oauth_token_secret);
  if ($response->is_success) {
    $access_json = $json->decode($response->decoded_content);
    $oauth_token = $access_json->{"oauth_token"};
    $oauth_token_secret = $access_json->{"oauth_token_secret"};
  }
  
  return ($oauth_token, $oauth_token_secret);
}

sub get_file_list {
  my @music_list;
  my ($self, $token, $token_secret) = @_;
  my $url = 'http://openapi.kuaipan.cn/1/metadata/app_folder';
  my $oauth_consumer_key = get_consumer_key();
  my $oauth_nonce = get_nonce();
  my $oauth_signature_method = get_signature_method();
  my $oauth_timestamp = get_timestamp();
  my $oauth_token = get_token($token);
  my $oauth_version = get_version();
  my $access_para = combination_para($oauth_consumer_key,$oauth_nonce,$oauth_signature_method,$oauth_timestamp,$oauth_token,$oauth_version);
  my $access_src = combination_para('GET',SelfCommon::url_to_url($url),SelfCommon::url_to_url($access_para));
  my $oauth_signature = get_signature($access_src, combination_para($consumer_secret,$token_secret));
  my $access_url = $url.'?'.combination_para($oauth_signature,$access_para);
  my $json = Mojo::JSON->new;
  my $ua = LWP::UserAgent->new;
  $ua->timeout(60);
  $ua->env_proxy;
  my $response = $ua->get($access_url);
  if ($response->is_success) {
    my $access_json = $json->decode($response->decoded_content);
    foreach my $file (@{$access_json->{"files"}}) {
      unless ($file->{"is_deleted"}) {
        if ($file->{"name"} =~ /\.(mp3|ogg|m4a)$/i) {
          push @music_list, $file->{"name"};
        }
      }
    }
  }
  
  return SelfCommon::sort_by_pinyin(@music_list);
}

sub get_file_url {
  my @music_list;
  my ($self, $file, $token, $token_secret) = @_;
  my $url = 'http://api-content.dfs.kuaipan.cn/1/fileops/download_file';
  my $oauth_consumer_key = get_consumer_key();
  my $oauth_nonce = get_nonce();
  my $oauth_signature_method = get_signature_method();
  my $oauth_timestamp = get_timestamp();
  my $oauth_token = get_token($token);
  my $oauth_version = get_version();
  my $path = get_file_path($file);
  my $root = get_file_root();
  my $access_para = combination_para($oauth_consumer_key,$oauth_nonce,$oauth_signature_method,$oauth_timestamp,$oauth_token,$oauth_version,$path,$root);
  my $access_src = combination_para('GET',SelfCommon::url_to_url($url),SelfCommon::url_to_url($access_para));
  my $oauth_signature = get_signature($access_src, combination_para($consumer_secret,$token_secret));
  my $file_url = $url.'?'.combination_para($oauth_signature,$access_para);
  
  return $file_url;
}

1;

__END__
