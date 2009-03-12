package App::SimpleScan::Plugin::Snapshot;

our $VERSION = '0.07';

use warnings;
use strict;
use Carp;
use File::Path;

my($snapdir, $snapshot, $snap_prefix);

sub import {
  no strict 'refs';
  *{caller() . '::snapshot'}     = \&snapshot;
  *{caller() . '::snapshots_to'} = \&snapshots_to;
  *{caller() . '::snap_prefix'}  = \&snap_prefix;
}

sub snapshot {
  my($self, $value) = @_;
  $snapshot = $value if defined $value;
  $snapshot;
}

sub snapshots_to {
  my($self, $value) = @_;
  $snapdir = $value if defined $value;
  $snapdir;
}

sub snap_prefix {
  my($self, $value) = @_;
  $snap_prefix = $value if defined $value;
  $snap_prefix;
}

sub options {
  return ('snap_dir=s'    => \$snapdir,
          'snap_prefix=s' => \$snap_prefix,
          'snapshot=s'    => \$snapshot);
}

sub validate_options {
  my($class, $app) = @_;
  if (defined (my $dir = $app->snapshots_to)) {
    $app->pragma('snap_dir')->($app, $dir);
  } 
  if (defined (my $prefix = $app->snap_prefix)) {
    $app->pragma('snap_prefix')->($app, $prefix);
  } 
}

sub pragmas {
  return (['snap_dir'    => \&snapshot_dir_pragma],
          ['snapshot'    => \&snapshot_pragma],
          ['snap_prefix' => \&snap_prefix_pragma],
         );
}

sub snapshot_dir_pragma {
  my ($self, $args) = @_;
  $self->stack_code(qq(mech->snapshots_to("$args");\n));
}

sub snapshot_pragma {
  my($self, $args) = @_;
  if ($args eq 'on') {
    $self->snapshot('on');
  }
  elsif ($args =~ /^error(s?)/) {
    $self->snapshot('error');
  }
  else {
    $self->stack_code(qq(diag "Invalid snapshot type '$args'; 'error' assumed";\n));
    $self->snapshot('error');
  }
}

sub snap_prefix_pragma {
  my ($self, $args) = @_;
  $self->stack_code(qq(mech->snap_prefix("$args");\n));
}

sub per_test {
  my($class, $testspec) = @_;
  my $snap_kind = $testspec->app->snapshot;
  return unless defined $snap_kind;

  my $comment = $testspec->comment;
  my $url = $testspec->uri;
  my $regex = $testspec->regex;
  my $test_kind = $testspec->kind;

  if ($snap_kind eq 'on') {
    return <<EOS;
diag "See snapshot " . mech->snapshot( qq($comment<br>$url<br>$regex $test_kind) );
EOS
  }
  elsif ($snap_kind eq 'error') {
    return <<EOS;
if (!last_test->{ok}) {
  diag "See snapshot " . mech->snapshot( qq($comment<br>$url<br>$regex $test_kind) );
}
EOS
  }
}

1; # Magic true value required at end of module
__END__

=head1 NAME

App::SimpleScan::Plugin::Snapshot - Allow tests to snapshot results


=head1 VERSION

This document describes App::SimpleScan::Plugin::Snapshot version 0.01


=head1 SYNOPSIS

    use App::SimpleScan;
    my $app = new App::SimpleScan;
    $app->go; # plugin loaded automatically here

  
=head1 DESCRIPTION

Supports the C<%%snapshot_dir> and C<%%snapshot> pragmas plus the 
C<--snapshot_dir> and C<--snap_all> and C<-snap_errors> options.

=head1 INTERFACE 

=head2 pragmas

Installs the pragmas into C<App::SimpleScan>.

=head2 options

Installs the command line options into C<App::SimpleScan>.

=head2 snapshots_to

Accessor allowing pragmas and command line options to share the
variable containing the current value for this combined option.

=head2 snapshot 

Accessor allowing pragmas and command line options to share the
variable containing the current value for this combined option.

=head2 snap_prefix

Accessor allowing pragmas and command line options to share the
variable containing the current value for this combined option.

=head2 snapshot_dir_pragma

Actually implements the C<%%snapshot_dir> pragma, stacking the 
necessary code.

=head2 snapshot_pragma

Sets the current snapshotting: 'on' (snapshot everything), or
'error' (only snapshot on errors).

=head2 snap_prefix_pragma

Set the current snapshot "prefix" - substituted for the 
directory that the snapshots are stored in when the 
snapshot frame file name is printed. This makes it possible
to do things like transform a filename into a URL so that
you can link to snapshots from a report.

=head2 validate_options

Standard C<App::SimpleScan> callback: validates the command-line
arguments, calling the appropriate pragma methods as necessary.

=head2 per_test

Actually implements the snapshotting. Stacks code after every test
that either snapshots every transaction (snapshot 'on') or
only after an error occurs (snapshot 'error').

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
App::SimpleScan::Plugin::Snapshot requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-simplescan-plugin-snapshot@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Joe McMahon  C<< <mcmahon@yahoo-inc.com > >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Joe McMahon C<< <mcmahon@yahoo-inc.com > >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
