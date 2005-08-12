package eBay;

use warnings;
use strict;

use Carp;
use Error::Dumb;
use LWP::UserAgent;
use XML::Simple;

use lib '.';

use Log;

use base qw( Error::Dumb );

use vars qw( $AUTOLOAD );

# If under development make uncomment this line and comment the next
our $VERSION = sprintf "%s%s", ( q$Revision: 1.2 $ =~ /[\d\.]+/g ), '_devel';
#our $VERSION = sprintf "%s", ( q$Revision: 1.2 $ =~ /[\d\.]+/g );

# Comment this out for public release
$VERSION .= '_devel';

sub new {
  my ( $class, $args ) = @_;

  carp "args should be a reference to a hash, ignoring args" unless ref $args eq 'HASH';

  # Put methods you want AUTOLOAD to handle here

  my %class;  @class{  qw( api_url live call_counter call_counter_file ) } = undef;
  my %header; @header{ qw( compatibility_level session_certificate dev_name app_name cert_name call_name siteid detail_level ) } = undef;
  my %log;    @log{    qw( debug info notice warning error critical alert emergency ) } = undef;

  my %valid_method;

  @valid_method{ keys %class  } = ( 'class'  ) x scalar keys %class;
  @valid_method{ keys %header } = ( 'header' ) x scalar keys %header;
  @valid_method{ keys %log    } = ( 'log'    ) x scalar keys %log;

  # Set defaults

  $class{ 'api_url' } = 'https://api.sandbox.ebay.com/ws/api.dll';
  $class{ 'live' }    = $args->{ 'live' } || '';

  $header{ 'compatibility_level' } = 391;
  $header{ 'siteid' } = 0;

  my $self = {
    'class'  => \%class,
    'header' => \%header,
    'valid_method' => \%valid_method,
  };

  $self->{ 'loghandler' } = ( exists $args->{ 'loghandler' } && ref $args->{ 'loghandler' } ne '' ) ? $args->{ 'loghandler' } : 'none';

  bless $self, ref $class || $class;

  return $self;
}

sub DESTROY {}

sub AUTOLOAD {
  my ( $self, $arg ) = @_;

  ( my $method = $AUTOLOAD ) =~ s/.*:://;

  return $self->_setError( 'Unknown method: $method' )
    unless exists $self->{ 'valid_method' }{ $method };

  if ( $self->{ 'valid_method' }{ $method } eq 'log' ) {
    $self->{ 'loghandler' }{ $method }( $arg ) if $self->{ 'loghandler' } ne 'none';
  } elsif ( $arg eq '' ) {
    return $self->{ $self->{ 'valid_method' }{ $method } }{ $method };
  } else {
    $self->{ $self->{ 'valid_method' }{ $method } }{ $method } = $arg;
    return undef;
  }
}

sub submitrequest {
  my ( $self, $args ) = shift;

  return _setError( 'Must pass a reference to a hash to submitrequest' )
    unless ref $args eq 'HASH';

  #return _setError( 'DevID is not set' ) unless $self->devid ne '';
  #return _setError( 'AppID is not set' ) unless $self->appid ne '';
  #return _setError( 'CertID is not set' ) unless $self->certid ne '';
  #return _setError( 'Call_Name is not set' ) unless $self->call_name ne '';

  for ( qw( devid appid certid call_name ) ) { return _setError( $_ . ' is not set' ) unless $self->$_ ne '' }

  my $header = HTTP::Headers->new;
  $header->header('Content-Type' => 'text/xml'); 

  $self->session_certificate( join ';', $self->devid, $self->appid, $self->certid );

  for my $h ( keys %{ $self->{ 'header' } } ) {
    ( my $H = uc $h ) =~ s/_/-/g ;
    #$header->header( ( 'X-EBAY-API-' . $H ) => $self->{ 'header' }{ $h } );
    $header->header( ( 'X-EBAY-API-' . $H ) => $self->$h );
  }

  $args->{ 'xmlns' } = 'urn:ebay:apis:eBLBaseComponents';

  my $body = XMLout( $args,
    'AttrIndent' => 1,
    'KeyAttr'  => '',
    'NoAttr'   => 1,
    'RootName' => $self->call_name . 'Request',
    'XMLDecl'  => "<?xml version='1.0' encoding='utf-8'?>",
    'NSExpand' => 1,
  );

  my $request = HTTP::Request->new( 'POST', $self->get_api_url, $header, $body );

  my $ua = LWP::UserAgent->new;
  $ua->agent( 'SmoothSellin eBay Bot/$VERSION' );

  $self->debug( "REQUEST:\n" . '=' x 72 . "\n", $request->as_string );

  my $response = $ua->request( $request );

  $self->debug( "RESPONSE:\n" . '=' x 72 . "\n", $response->as_string );

  return $self->_setError( "Error connecting to eBay: $response" ) unless $response->is_success;

  $self->response( XMLin( $response->content,
    'ForceArray' => 1,
    'KeyAttr'    => '',
    'NoAttr'     => 1,
  ));

  return 1;
}

sub get_api_url {
  my $self = shift;

  my $url = $self->api_url;
  $url =~ s/sandbox//i if $self->live;

  return $url;
}

1;
