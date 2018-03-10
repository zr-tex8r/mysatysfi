#!/usr/bin/perl
use v5.12;
use File::Copy 'copy';
use Time::HiRes 'sleep';
my $program = "wynhotep";
my $version = "0.2.0";

my $tempb = "__whtp";

sub main {
  if ($ENV{WYNHOTEP_FOOLYSH_DIR} ne '') {
    main_foolysh();
  } elsif ($ENV{WYNHOTEP_DOCKER_IMAGE} ne '') {
    main_docker();
  } else {
    my $opt = shift(@ARGV) // "";
    if ($opt =~ m/^--?h(?:elp)?$/) {
      show_usage();
    } else {
      error("not properly set up (try '--help')");
    }
  }
}

sub show_usage {
  print <<"EOT";
This is $program, version $version.

If you use foolysh linking, set the name of the share-base directory
to the environment variable WYNHOTEP_FOOLYSH_DIR.
If you use a Docker container, set the name of the Docker image
to the environment variable WYNHOTEP_DOCKER_IMAGE.
EOT
}

sub read_whole {
  my ($fn) = @_; local ($_, $/);
  open(my $h, '<', $fn) or error("cannot open for read", $fn);
  binmode($h); $_ = <$h>;
  close($h);
  return $_;
}

sub write_whole {
  my ($fn, $dat) = @_;
  open(my $h, '>', $fn) or error("cannot open for write", $fn);
  binmode($h); print $h ($dat);
  close($h);
}

sub info {
  say STDERR (join(": ", $program, @_));
}
sub error {
  info(@_); exit(-1);
}

#-----------------------------------------------------------
# Foolysh

my $foolysh_dir = "C:/Users/yato/Repos/mysatisfi/foolysh";
my ($wait_intv, $wait_limit) = (0.5, 600);

sub main_foolysh {
  $foolysh_dir = $ENV{WYNHOTEP_FOOLYSH_DIR};
  (-d $foolysh_dir) or error("no such directory", $foolysh_dir);
  my $name = "whtp$$";
  my $dir = "$foolysh_dir/$name";
  my $sh = "$foolysh_dir/$name.sh";
  mkdir($dir) or error("failure", $dir);
  export_files($dir);

  write_whole($sh, "satysfi @ARGV");
  for (my $w = 0; $w < $wait_limit; $w += $wait_intv) {
    sleep($wait_intv);
    (! -f $sh) and last;
  }
  (! -f $sh) or error("failure in foolysh");
  import_files($dir);
  my $out = read_whole("$dir/__stdout");
  my $err = read_whole("$dir/__stderr");
  unlink($sh, glob("$dir/*"));
  rmdir($dir);

  print STDERR ($err);
  print($out);
}

sub export_files {
  my ($dir) = @_;
  foreach my $f (glob("*.*")) {
    copy($f, "$dir/$f");
  }
}

sub import_files {
  my ($dir) = @_;
  foreach my $f (glob("$dir/*.pdf")) {
    my $ff = $f =~ s|.*/||r;
    copy($f, $ff);
  }
}

#-----------------------------------------------------------
# Docker

my $image_name = "test/satysfi";
my $docker = "docker";

sub main_docker {
  $image_name = $ENV{WYNHOTEP_DOCKER_IMAGE};
  (check_docker()) or error("Docker is not working");
  (check_image()) or build_image();

  my $input = make_input();
  my $output = run_container($input);
  make_output($output);
}

sub make_input {
  my $tar = "$tempb-in.tar.gz";
  unlink($tar);
  write_whole("probe.whtp", "SATySFi");
  local $_ = `tar cfz $tar *.saty *.satyh probe.whtp 2>$tempb.err`;
  unlink("probe.whtp", "$tempb.err");
  (-s $tar) or error("failure in tar");
  return $tar;
}

sub make_output {
  my ($tar) = @_;
  if (-s $tar) { # output files exist
    local $_ = `tar xfz $tar 2>$tempb.err`;
    ($? == 0) or error("failure in tar");
    unlink("$tempb.err");
  }
  unlink($tar);
}

sub check_docker {
  local $_ = `$docker ps`;
  return ($? == 0);
}

sub check_image {
  local $_ = `$docker images`;
  ($? == 0) or docker_error();
  foreach (split(m/\n/, $_)) {
    my $id = (split(m/\s+/, $_, 2))[0];
    ($id eq $image_name) and return 1;
  }
  return;
}

sub run_container {
  my ($input) = @_;
  my $output = "$tempb-out.tar.gz";
  local $_ = `$docker run --rm -i $image_name @ARGV <$input >$output`;
  ($? == 0) or docker_error();
  (-f $output) or error("ERR(1)");
  unlink($input);
  return $output;
}

sub build_image {
  info("build docker image", $image_name);
  my ($dockerfile, $script) = build_source();
  mkdir("$tempb-build") or error("cannot create directory");
  chdir("$tempb-build") or error("ERR(1)");
  write_whole("Dockerfile", $dockerfile);
  write_whole("run-satysfi.sh", $script);
  system("$docker build -t $image_name .");
  ($? == 0) or docker_error();
  (-f "Dockerfile") and unlink("Dockerfile", glob("*.*"));
  chdir("..");
  rmdir("$tempb-build") or error("cannot remove directory");
}

sub docker_error {
  info("DOCKER ERROR"); exit(-1);
}

sub build_source {
  return (<<'EOT1', <<'EOT2');
FROM pandaman64/satysfi
USER opam
RUN mkdir -p /home/opam/scripts && mkdir -p /home/opam/work
WORKDIR /home/opam/work
ADD run-satysfi.sh /home/opam/scripts/
ENTRYPOINT ["/home/opam/scripts/run-satysfi.sh"]
EOT1
#!/bin/bash
# receive input files
cat - | tar xfz - >/dev/null
# opam init
. /home/opam/.opam/opam-init/init.sh > /dev/null 2>&1 || true
# do it
satysfi $* 1>&2
if ls *.pdf >/dev/null 2>&1
then
  # send output files
  tar cfz __out.tar.gz *.pdf >/dev/null 2>&1
  cat __out.tar.gz
fi
EOT2
}

main();
# EOF
