package SelfDB;
use parent qw(Exporter);

use strict;
use DBI;

our @EXPORT = qw(create_db record_pretoken get_pretoken_secret delete_pretoken_secret user_register get_user_info save_user_info);
our $VERSION = 0.10;

my $tmp_db = "/tmp/self-music-tmp.db";
my $user_db = "/opt/self-db/self-music-user.db";

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

sub create_db {
  db_do($user_db, "create table if not exists user_info (user text primary key, id text, oauth_token text, oauth_token_secret text)");
  db_do($tmp_db, "create table if not exists pre_token_info (user text primary key, id text, pre_token text, pre_token_secret text)");
}

sub record_pretoken {
  my ($user, $id, $pre_token, $pre_token_secret) = @_;
  db_do($tmp_db, qq{replace into pre_token_info (user, id, pre_token, pre_token_secret) values ("$user", "$id", "$pre_token", "$pre_token_secret")});
}

sub get_pretoken_secret {
  my ($user, $id, $pre_token) = @_;
  my ($num, ($pretoken_secret)) = db_select_arrayref($tmp_db, qq{select pre_token_secret from pre_token_info where user="$user" and id="$id" and pre_token="$pre_token"});
  
  return ($num, $pretoken_secret);
}

sub delete_pretoken_secret {
  my ($user, $id, $pre_token) = @_;
  db_do($tmp_db, qq{delete from pre_token_info where user="$user" and id="$id" and pre_token="$pre_token"});
}

sub user_register {
  my ($user, $id) = @_;
  db_do($user_db, qq{replace into user_info (user, id) values ("$user", "$id")});
}

sub get_user_info {
  my $user = shift;
  my ($num, ($id, $token, $token_secret)) = db_select_arrayref($user_db, qq{select id, oauth_token, oauth_token_secret from user_info where user="$user"});
  
  return ($num, $id, $token, $token_secret);
}

sub save_user_info {
  my ($user, $id, $oauth_token, $oauth_token_secret) = @_;
  db_do($user_db, qq{update user_info set oauth_token="$oauth_token", oauth_token_secret="$oauth_token_secret" where user="$user" and id="$id"});
}

1;

__END__
