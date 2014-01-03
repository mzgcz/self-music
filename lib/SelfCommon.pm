package SelfCommon;
use parent qw(Exporter);

use strict;
use warnings;
use Mojo::Util;
use Digest::HMAC_SHA1;
use Unicode::Collate::Locale;

our @EXPORT = qw(rand_str utf8_to_url url_to_url b64_and_url create_autograph sort_by_pinyin);
our $VERSION = 0.10;

sub rand_str {
  my $max_len = shift;
  my @char_set = (0..9, 'a'..'z', 'A'..'Z', '_');
  my $str = join '', map { $char_set[int rand @char_set] } 0..($max_len-1);
  
  return $str;
}

sub utf8_to_url {
  my $str = shift;
  
  return Mojo::Util::url_escape(Mojo::Util::encode('UTF-8', $str));
}

sub url_to_url {
  my $str = shift;
  
  return Mojo::Util::url_escape($str);
}

sub b64_and_url {
  my $str = shift;
  
  $str = Mojo::Util::b64_encode($str);
  chomp($str);
  $str = Mojo::Util::url_escape($str);
  
  return $str;
}

sub create_autograph {
  my ($source, $secret) = @_;
  
  return b64_and_url(Digest::HMAC_SHA1::hmac_sha1($source, $secret));
}

sub sort_by_pinyin {
  my @list = @_;
  
  my $collator = Unicode::Collate::Locale->new(locale => "zh__pinyin");
  
  return $collator->sort(@list);
}

sub combination_parameters {
    my $parameters = shift;
    my ($key, $value, @arguments);
    
    while (($key, $value) = each %$parameters) {
        push @arguments, $key.'='.$value;
    }
    
    return join('&', @arguments);
}

1;

__END__
