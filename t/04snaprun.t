use Test::More;
use Test::Differences;

my $simple_scan = `which simple_scan`;
chomp $simple_scan;

unlink $_ foreach glob("t/*.html");

my %counts = (
  'snaponrun.in' => 2,
  'snaperrorrun.in' => 1,
);

my %test_pairs = (
  "snaponrun.in" => <<EOS,
1..2
ok 1 - branding [http://perl.org/] [/Perl/ should match]
not ok 2 - branding [http://python.org/] [/Perl/ should match] # TODO Doesn't match now but should later
#   Failed (TODO) test 'branding [http://python.org/] [/Perl/ should match]'
#   in /home/y/lib/perl5/site_perl/5.6.1/Test/WWW/Simple.pm at line 52.
#          got: "<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Trans"...
#       length: 11445
#     doesn't match '(?-xism:Perl)'
EOS
  "snaperrorrun.in" => <<EOS,
1..2
ok 1 - branding [http://perl.org/] [/Perl/ should match]
not ok 2 - branding [http://python.org/] [/Perl/ should match]
#   Failed test 'branding [http://python.org/] [/Perl/ should match]'
#   in /home/y/lib/perl5/site_perl/5.6.1/Test/WWW/Simple.pm at line 52.
#          got: "<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Trans"...
#       length: 11445
#     doesn't match '(?-xism:Perl)'
# Looks like you failed 1 test of 2.
EOS
);

plan tests=>(int keys %test_pairs)+(3*int keys %counts);

for my $test_input (keys %test_pairs) {
  my $cmd = qq(perl -Iblib/lib $simple_scan 2>&1 <t/$test_input);
  my $results = `$cmd`;
  $results =~ s/\n\n/\n/g;
  eq_or_diff $results, $test_pairs{$test_input}, "expected output";
  for my $which (qw(debug frame content)) {
    my @files = glob("t/$which*.html");
    is int(@files), $counts{$test_input}, "proper number of $which files for $test_input";
  }
  unlink $_ foreach glob("t/*.html");
}
