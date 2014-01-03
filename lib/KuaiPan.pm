package KuaiPan;

use strict;
use warnings;
use SelfConf;
use WebService::Kuaipan;

sub new { bless {}, shift }

sub request_token {
  my ($self, $cb_url) = @_;
  my $kuaipan = WebService::Kuaipan->new({
                                          key => SelfConf::JSKP_KEY,
                                          secret => SelfConf::JSKP_SECRET
                                         });
  my $url = $kuaipan->login($cb_url);
  return ($url, $kuaipan->request_token, $kuaipan->request_secret);
}

sub access_token {
  my ($self, $token, $token_secret, $verifier) = @_;
  my $kuaipan = WebService::Kuaipan->new({
                                          key => SelfConf::JSKP_KEY,
                                          secret => SelfConf::JSKP_SECRET,
                                          request_token => $token,
                                          request_secret => $token_secret
                                         });
  $kuaipan->auth($verifier);
  return($kuaipan->access_token, $kuaipan->access_secret);
}

sub get_one_list {
  my @musics;
  my ($self_music, $self_path, $token, $token_secret, $level, $path) = @_;
  my $kuaipan = WebService::Kuaipan->new({
                                          key => SelfConf::JSKP_KEY,
                                          secret => SelfConf::JSKP_SECRET,
                                          access_token => $token,
                                          access_secret => $token_secret,
                                          root => 'app_folder'
                                         });
  my $access_json = $kuaipan->metadata($path);
  unless ($access_json->{"is_deleted"}) {
    foreach my $file (@{$access_json->{"files"}}) {
      unless ($file->{"is_deleted"}) {
        if ($file->{"type"} eq "file") {
          if ($file->{"name"} =~ /\.mp3$/i) {
            push @musics, $file->{"name"};
          }
        } elsif ($file->{"type"} eq "folder") {
          if (0 == $level) {
            get_one_list($self_music, $self_path, $token, $token_secret, $level+1, $path.$file->{"name"});
          }
        }
      }
    }
    @musics = SelfCommon::sort_by_pinyin(@musics);
    $self_music->{$access_json->{"name"}} = \@musics;
    $self_path->{$access_json->{"name"}} = $access_json->{"path"};
  }
}

sub get_play_list {
  my ($self, $token, $token_secret) = @_;
  
  my (%self_music, %self_path);
  get_one_list(\%self_music, \%self_path, $token, $token_secret, 0, '');
  
  my %self_plist;
  $self_plist{"music"} = \%self_music;
  $self_plist{"path"} = \%self_path;
  
  return \%self_plist;
}

sub get_file_url {
  my ($self, $file, $token, $token_secret) = @_;
  my $kuaipan = WebService::Kuaipan->new({
                                          key => SelfConf::JSKP_KEY,
                                          secret => SelfConf::JSKP_SECRET,
                                          access_token => $token,
                                          access_secret => $token_secret,
                                          root => 'app_folder'
                                         });
  my $url = $kuaipan->oauth_request_url({
                                         method => 'GET',
                                         url => $kuaipan->url('http://api-content.dfs.kuaipan.cn/1/fileops/download_file'),
                                         extra_params => {
                                                          root => $kuaipan->root,
                                                          path => $file,
                                                         }
                                        });
  
  return $url;
}

1;

__END__
