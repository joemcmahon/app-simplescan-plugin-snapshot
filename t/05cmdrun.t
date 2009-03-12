use Test::More;
use Test::Differences;

my $simple_scan = `which simple_scan`;
chomp $simple_scan;

unlink $_ foreach (glob('t/*.html'));

my %test_pairs = (
  "-snap_dir t" => <<EOS,
1..1
ok 1 - branding [http://perl.org/] [/Perl/ should match]
EOS
  "--snap_dir /nonexistent" => <<EOS,
1..2
not ok 1 - /nonexistent is not a directory; no snapshots can be taken

#   Failed test '/nonexistent is not a directory; no snapshots can be taken'
#   in (eval 79) at line 6.
ok 2 - branding [http://perl.org/] [/Perl/ should match]
No TMPDIR/TEMP defined on this system!

# Looks like you failed 1 test of 2.
EOS
);

if (defined($ENV{TMP}||$ENV{TMPDIR})) {
  $test_pairs{'--snap_dir /nonexistent'} =~ 
    s|No TMPDIR/TEMP defined on this system!\n\n||g;
}

plan tests=>(int keys %test_pairs) + 6;

for my $test_input (keys %test_pairs) {
  my $cmd = qq(perl -Iblib/lib $simple_scan $test_input 2>&1 <t/testsnap.in);
  my $results = `$cmd`;
  eq_or_diff $results, $test_pairs{$test_input}, "expected output";
  if ($test_input eq "-snap_dir t") {
    for my $which (qw(content debug frame)) {
      my @file = glob("t/${which}*.html");
      ok -e $file[0], "$which file exists";
      ok -s $file[0], "$which file has content";
    }
  }
}
unlink $_ foreach (glob('t/*.html'));
