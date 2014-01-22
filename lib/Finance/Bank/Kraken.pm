package Finance::Bank::Kraken;

#
# $Id: Kraken.pm 2 2014-01-22 15:04:34Z phil $
#
# Kraken API connector
# author, (c): Philippe Kueck <projects at unixadm dot org>
#

use strict;
use warnings;

use HTTP::Request;
use LWP::UserAgent;
use MIME::Base64;
use Digest::SHA qw(hmac_sha512_base64 sha256);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(Private Public);
our $VERSION = "0.1";
use constant Private => 1;
use constant Public => 0;

sub new {bless {'uri' => 'https://api.kraken.com', 'nonce' => time}, $_[0]}

sub key {
	return $_[0]->{'key'} unless $_[1];
	$_[0]->{'key'} = $_[1]
}

sub secret {
	return $_[0]->{'secret'} unless $_[1];
	$_[0]->{'secret'} = decode_base64($_[1])
}

sub call {
	my $self = shift;
	my $uripath = sprintf "/0/%s/%s", $_[0]?"private":"public", $_[1];
	my $req = new HTTP::Request($_[0]?'POST':'GET');
	my $ua = new LWP::UserAgent('agent' => "Mozilla/5.0 (X11; Linux i686; rv:26.0) Gecko/20100101 Firefox/26.0");
	my $qry = defined $_[2]?(join "&", @{$_[2]}):undef;
	if ($_[0]) {
		$req->uri($self->{'uri'} . $uripath);
		$req->content(sprintf "nonce=%d%s", $self->{'nonce'}, defined $qry?"&$qry":"");
		$req->header("API-Key" => $self->{'key'});
		$req->header("API-Sign" => hmac_sha512_base64(
			$uripath . sha256($self->{'nonce'} . $req->content),
			$self->{'secret'})
		);  
		$self->{'nonce'}++
	} else {
		$req->uri(sprintf "%s%s%s", $self->{'uri'}, $uripath, defined $qry?"?$qry":"")
	}
	my $res = $ua->request($req);
	return $res->content if $res->is_success;
	return
}


1;

__END__

=head1 NAME

Finance::Bank::Kraken - api.kraken.com connector

=head1 VERSION

0.1

=head1 SYNOPSIS

 require Finance::Bank::Kraken;
 $api = new Finance::Bank::Kraken;
 $api->key($mykrakenkey);
 $api->secret($mykrakensecret);
 $result = $api->call(Private, $method, [$arg1, $arg2, ..]);

=head1 DESCRIPTION

This module allows to connect to the api of the bitcoin market Kraken.

Please see L<the Kraken API documentation|https://www.kraken.com/help/api> for a catalog of api methods.

=head1 METHODS

=over 4

=item $api = new Finance::Bank::Kraken

The constructor. Returns a C<Finance::Bank::Kraken> object.

=item $api->key($key)

Sets or gets the API key.

=item $api->secret($secret)

Sets the API secret to C<$secret> or returns the API secret base64 decoded.

=item $result = $api->call(Public, $method)

=item $result = $api->call(Private, $method)

=item $result = $api->call(Private, $method, [$param1, $param2, ..])

Calls the C<Public> or C<Private> API method C<$method> (with the given C<$params>, where applicable) and returns either undef or a JSON string.

=back

=head1 DEPENDENCIES

=over 8

=item L<HTTP::Request>

=item L<LWP::UserAgent>

=item L<MIME::Base64>

=item L<Digest::SHA>

=back

=head1 AUTHOR and COPYRIGHT

Copyright Philippe Kueck <projects at unixadm dot org>

=cut

