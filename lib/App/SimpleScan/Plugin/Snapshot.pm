package App::SimpleScan::Plugin::Snapshot;

our $VERSION = '0.01';

use warnings;
use strict;
use Carp;

my($snapdir, $snapshot);

sub import {
  no strict 'refs';
  *{caller() . '::snapshot'}     = \&snapshot;
  *{caller() . '::snapshots_to'} = \&snapshots_to;
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

sub options {
  return ('snap_dir=s'   => \$snapdir,
          'snapshot=s' => \$snapshot);
}

sub validate_options {
  my($class, $app) = @_;
  if (defined (my $dir = $app->snapshots_to)) {
    $app->pragma('snap_dir')->($app, $dir);
  } 
}

sub pragmas {
  return (['snap_dir' => \&snapshot_dir_pragma],
          ['snapshot'     => \&snapshot_pragma],
         );
}

sub snapshot_dir_pragma {
  my ($self, $args) = @_;
  if (-d $args) {
    if (-w $args) {
      $self->stack_code(qq(mech->snapshots_to("$args");\n));
    }
    else {
      $self->stack_test(qq(fail "Snapshot directory $args is not writable";\n));
    }
  }
  else {
    $self->stack_test(qq(fail "$args is not a directory; no snapshots can be taken";\n));
  }
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

sub per_test {
  my($class, $testspec) = @_;
  my $kind = $testspec->app->snapshot;
  _per_test_assist($testspec, $kind, 0);
}

sub _per_test_assist {
  my($testspec, $kind, $indent) = @_;
  return unless defined $kind;

  if ($kind eq 'on') {
    return <<EOS;
mech->snapshot;
EOS
  }
  elsif ($kind eq 'error') {
    return <<EOS;
if (!last_test->{ok}) {
  mech->snapshot;
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

=head2 snapshot_dir_pragma

Actually implements the C<%%snapshot_dir> pragma, stacking the 
necessary code.

=head2 snapshot_pragma

Sets the current snapshotting: 'on' (snapshot everything), or
'error' (only snapshot on errors).

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
