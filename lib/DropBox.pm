package DropBox;

use strict;
use warnings;
use SelfConf;
use File::Basename;
use WebService::Dropbox;

sub new { bless {}, shift }

sub request_token {
  my ($self, $cb_url) = @_;
  my $dropbox = WebService::Dropbox->new({
                                          key => SelfConf::DROPBOX_KEY,
                                          secret => SelfConf::DROPBOX_SECRET
                                         });
  my $url = $dropbox->login($cb_url);
  return ($url, $dropbox->request_token, $dropbox->request_secret);
}

sub access_token {
  my ($self, $token, $token_secret) = @_;
  my $dropbox = WebService::Dropbox->new({
                                          key => SelfConf::DROPBOX_KEY,
                                          secret => SelfConf::DROPBOX_SECRET,
                                          request_token => $token,
                                          request_secret => $token_secret
                                         });
  $dropbox->auth;
  return($dropbox->access_token, $dropbox->access_secret);
}

sub get_one_list {
  my @musics;
  my ($self_music, $self_path, $token, $token_secret, $level, $path) = @_;
  my $dropbox = WebService::Dropbox->new({
                                          key => SelfConf::DROPBOX_KEY,
                                          secret => SelfConf::DROPBOX_SECRET,
                                          access_token => $token,
                                          access_secret => $token_secret,
                                          root => 'sandbox'
                                         });
  my $access_json = $dropbox->metadata($path);
  unless ($access_json->{"is_deleted"}) {
    foreach my $file (@{$access_json->{"contents"}}) {
      unless ($file->{"is_deleted"}) {
        if ($file->{"is_dir"} eq "false") {
          if ($file->{"path"} =~ /\.mp3$/i) {
            push @musics, basename($file->{"path"});
          }
        } elsif ($file->{"is_dir"} eq "true") {
          if (0 == $level) {
            get_one_list($self_music, $self_path, $token, $token_secret, $level+1, $file->{"path"});
          }
        }
      }
    }
    my $list_name;
    if (basename($access_json->{"path"}) eq '/') {
      $list_name = 'self-music';
    } else {
      $list_name = basename($access_json->{"path"});
    }
    @musics = SelfCommon::sort_by_pinyin(@musics);
    $self_music->{$list_name} = \@musics;
    $self_path->{$list_name} = $access_json->{"path"};
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
  my $dropbox = WebService::Dropbox->new({
                                          key => SelfConf::DROPBOX_KEY,
                                          secret => SelfConf::DROPBOX_SECRET,
                                          access_token => $token,
                                          access_secret => $token_secret,
                                          root => 'sandbox'
                                         });
  my $url = $dropbox->oauth_request_url({
                                         method => 'GET',
                                         url => $dropbox->url('https://api-content.dropbox.com/1/files/'.$dropbox->root,$file),
                                        });
  
  return $url;
}

1;

__END__
