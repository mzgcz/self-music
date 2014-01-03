package SelfDB;

use strict;
use warnings;
use DBI;
use Mojo::JSON;

sub new { bless {}, shift }

my $tmp_db = "/tmp/self-music-tmp.db";
my $user_db = "/opt/self-db/self-music-user.db";
my $plist_db_path = "/opt/self-db/self-music/";

sub db_do {
  my ($db, $do) = @_;
  
  my $dbh = DBI->connect("dbi:SQLite:dbname=$db", "", "");
  $dbh->do($do);
  $dbh->disconnect();
}

sub db_select_arrayref {
  my ($db, $select) = @_;
  
  my $dbh = DBI->connect("dbi:SQLite:dbname=$db", "", "");
  my $db_info = $dbh->selectall_arrayref($select);
  my ($num, @ary);
  if ($db_info) {
    $num = @$db_info;
    foreach my $info (@$db_info) {
      @ary = @$info;
    }
  } else {
    $num = 0;
  }
  $dbh->disconnect();
  
  return ($num, @ary);
}

sub db_select_arrayref_s {
    my ($db, $select) = @_;
    
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db", "", "");
    my $db_info = $dbh->selectall_arrayref($select);
    my ($num, @ary);
    if ($db_info) {
        $num = @$db_info;
        foreach my $info (@$db_info) {
            push @ary, $info;
        }
    } else {
        $num = 0;
    }
    $dbh->disconnect();
    
    return ($num, \@ary);
}

sub create_db {
  my ($self) = @_;
  db_do($user_db, "create table if not exists user_info (user text primary key, id text, oauth_token text, oauth_token_secret text, netbox text)");
  db_do($tmp_db, "create table if not exists pre_token_info (user text primary key, id text, pre_token text, pre_token_secret text, netbox text)");
}

sub record_pretoken {
  my ($self, $user, $id, $pre_token, $pre_token_secret, $netbox) = @_;
  db_do($tmp_db, qq{replace into pre_token_info (user, id, pre_token, pre_token_secret, netbox) values ("$user", "$id", "$pre_token", "$pre_token_secret", "$netbox")});
}

sub get_pretoken_secret {
  my ($self, $user, $id, $pre_token) = @_;
  my ($num, ($pretoken_secret, $netbox)) = db_select_arrayref($tmp_db, qq{select pre_token_secret, netbox from pre_token_info where user="$user" and id="$id" and pre_token="$pre_token"});
  
  return ($num, $pretoken_secret, $netbox);
}

sub delete_pretoken_secret {
  my ($self, $user, $id, $pre_token) = @_;
  db_do($tmp_db, qq{delete from pre_token_info where user="$user" and id="$id" and pre_token="$pre_token"});
}

sub user_register {
  my ($self, $user, $id, $netbox) = @_;
  db_do($user_db, qq{replace into user_info (user, id, netbox) values ("$user", "$id", "$netbox")});
}

sub get_user_info {
  my ($self, $user) = @_;
  my ($num, ($id, $token, $token_secret, $netbox)) = db_select_arrayref($user_db, qq{select id, oauth_token, oauth_token_secret, netbox from user_info where user="$user"});
  
  return ($num, $id, $token, $token_secret, $netbox);
}

sub save_user_info {
  my ($self, $user, $id, $oauth_token, $oauth_token_secret) = @_;
  db_do($user_db, qq{update user_info set oauth_token="$oauth_token", oauth_token_secret="$oauth_token_secret" where user="$user" and id="$id"});
}

sub get_user_refresh_info {
    my ($self) = @_;
    my ($num, $refresh_info) = db_select_arrayref_s($user_db, qq{select user, id, oauth_token_secret from user_info where netbox="bdwp" and oauth_token_secret is not null});

    return $refresh_info;
}

sub get_user_plist {
  my ($self, $user) = @_;
  my $file_name = $plist_db_path.$user;
  
  my $bytes;
  if (-e $file_name) {
    open(my $fh, '<', $file_name);
    $bytes = <$fh>;
    close $fh;
  }
  
  my $json  = Mojo::JSON->new;
  my $self_plist = $json->decode($bytes);
  
  return $self_plist;
}

sub save_user_plist {
  my ($self, $user, $self_plist) = @_;
  my $file_name = $plist_db_path.$user;
  
  my $json = Mojo::JSON->new;
  my $bytes = $json->encode($self_plist);
  
  open(my $fh, '>', $file_name);
  print $fh $bytes;
  close $fh;
}

1;

__END__
