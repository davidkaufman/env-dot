## no critic (ValuesAndExpressions::ProhibitConstantPragma)
package Env::Dot::Functions;
use strict;
use warnings;
use Data::Dumper;

use Exporter 'import';
our @EXPORT_OK = qw(
    get_dotenv_vars
    interpret_dotenv_filepath_var
    );
our %EXPORT_TAGS = (
    'all'          => [qw( get_dotenv_vars interpret_dotenv_filepath_var )],
);

use English qw( -no_match_vars ); # Avoids regex performance penalty in perl 5.18 and earlier
use Carp;

# ABSTRACT: Read environment variables from .env file

# VERSION: generated by DZP::OurPkgVersion

use constant  {
    OPTION_FILE_TYPE => q{file:type},
    OPTION_FILE_TYPE_PLAIN => q{plain},
    OPTION_FILE_TYPE_SHELL => q{shell},
    DEFAULT_OPTION_FILE_TYPE => q{shell},
};

=pod

=for stopwords params env dotenv

=head1 STATUS

Package L<Env::Dot> is currently being developed so changes in the API are possible,
though not likely.


=head1 SYNOPSIS

    use Env::Dot;
    use Env::Dot qw( assert );

    my %want = (
        options => {
            exact => 1,
        },
        variables => {
            USER => { regexp => '^[[:word:]]{1}$', required => 1 },
        },
    );
    my %parameters;
    $parameters{'break_at_first_error'} = 1;
    my $r = assert( \%ENV, $desc, \%parameters );
    if( ! $r->{'success'} ) {
        say report_errors( $r->{'errors'} );
    }


=head1 DESCRIPTION

This package just contains functions for use
in the main package L<Env::Dot> and in
the command line tool B<envdot>.

=head1 FUNCTIONS

No functions are automatically exported to the calling namespace.

=cut

sub get_dotenv_vars {
    my @dotenv_filepaths = @_;

    my %vars;
    foreach my $filepath (@dotenv_filepaths) {
        if( -f $filepath ) {
            my @rows = _read_dotenv_file( $filepath );
            my %tmp = _interpret_dotenv( @rows );
            @vars{ keys %tmp } = @tmp{ keys %tmp };
        } else {
            carp "No file found: '$filepath'";
        }
    }
    return %vars;
}

=head2 interpret_dotenv_filepath_var( $filepaths )

Return a list of filepaths.

=cut

sub interpret_dotenv_filepath_var { ## no critic (Subroutines::RequireArgUnpacking)
    return split qr{:}msx, $_[0];
}

# Private subroutines

sub _interpret_dotenv {
    my (@rows) = @_;
    my %options = (
        'file:type' => DEFAULT_OPTION_FILE_TYPE,
    ); # Options related to reading the file. Applied as they are read.
    my %vars;
    foreach (@rows) {
        ## no critic (ControlStructures::ProhibitCascadingIfElse)
        ## no critic (RegularExpressions::ProhibitComplexRegexes)
        if(
            # This is dotenv meta command
            m{
            ^ [[:space:]]{0,} [#]{1}
            [[:space:]]{1,} envdot [[:space:]]{1,}
            [(] (?<opts> [^)]{0,}) [)]
            [[:space:]]{0,} $
            }msx
        ) {
            my $opts = _interpret_opts( $LAST_PAREN_MATCH{opts} );
            foreach ( keys %{ $opts } ) {
                $options{$_} = $opts->{$_};
            }
        } elsif(
            # This is comment row
            m{
                ^ [[:space:]]{0,} [#]{1} .* $
            }msx
        ) {
            1;
        } elsif(
            # This is empty row
            m{
                ^ [[:space:]]{0,} $
            }msx
        ) {
            1;
        } elsif(
            # This is env var description
            m{
                ^ (?<name> [^=]{1,}) = (?<value> .*) $
            }msx
        ) {
            my ($name, $value) = ( $LAST_PAREN_MATCH{name}, $LAST_PAREN_MATCH{value} );
            if( $options{ 'file:type' } eq OPTION_FILE_TYPE_SHELL ) {
                if($value =~ m{
                    ^['"]{1} (?<value> .*) ["']{1}  # Get value from between quotes
                    (?: [;] [[:space:]]{0,} export [[:space:]]{1,} $name)?  # optional
                    [[:space:]]{0,} $  # optional whitespace at the end
                }msx) {
                    ($value) = $LAST_PAREN_MATCH{value};
                }
            } elsif( $options{ 'file:type' } eq OPTION_FILE_TYPE_PLAIN ) {
                1;
            }
            $vars{ $name } = $value;
        } else {
            carp "Uninterpretable row: $_";
        }
    }
    return %vars;
}

sub _interpret_opts {
    my ($opts_str) = @_;
    my @opts = split qr{
        [[:space:]]{0,} [,] [[:space:]]{0,}
        }msx,
    $opts_str;
    my %opts;
    foreach (@opts) {
        my ($key, $val) = split qr/=/msx;
        $opts{$key} = $val;
    }
    return \%opts;
}

sub _read_dotenv_file {
    my ($filepath) = @_;
    open my $fh, q{<}, $filepath or croak "Cannot open file '$filepath'";
    my @dotenv_rows;
    while( <$fh> ) { chomp; push @dotenv_rows, $_; }
    close $fh or croak "Cannot close file '$filepath'";
    return @dotenv_rows;
}

1;
