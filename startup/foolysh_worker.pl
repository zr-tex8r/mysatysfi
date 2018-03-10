#!/usr/bin/perl
use strict;
my $program = "foolysh_worker";
my $debug = 0;

my ($target, $dir, $name, $ok);

sub main {
  $target = shift(@ARGV);
  debug("target", $target);
  (-f $target) or exit;
  ($dir, $name) = ($target =~ m|^(/.*/([-\w]+))\.sh$|) or exit;
  mkdir("$dir.lock") or next;
  debug("lock", "$dir.lock");

  $ok = 1;
  (-d $dir) or error("no work directory", $dir);
  chdir($dir);
  process();
}

sub process {
  my ($in, $out, $err) = ("__stdin", "__stdout", "__stderr");
  (-f $in) or $in = "/dev/null";
  system("bash $target < $in > $out 2> $err");
}

END {
  $? = 0;
  if ($ok) {
    debug("unlink", "$target");
    unlink($target);
    debug("unlock", "$dir.lock");
    rmdir("$dir.lock");
  }
}

sub info {
  print STDERR (join(": ", $program, @_), "\n");
}
sub debug {
  info(@_) if ($debug);
}
sub error {
  info(@_); exit(-1);
}

main();
# EOF
