#!/usr/bin/perl
use v5.12;
use File::Copy 'copy';
use Cwd 'getcwd';
use Time::HiRes 'sleep';
my $program = "wynhotep";
my $version = "0.3.1";

my $tempb = "__whtp";
my $windows = ($^O eq 'MSWin32');

sub main {
  if ($ENV{WYNHOTEP_FOOLYSH_DIR} ne '') {
    foolysh_main();
  } elsif ($ENV{WYNHOTEP_DOCKER_IMAGE} ne '') {
    if ($ENV{WYNHOTEP_DOCKER_USE_PIPE} ne '') {
      dockerwh_main();
    } else {
      docker_main();
    }
  } else {
    my $opt = shift(@ARGV) // '';
    if ($opt eq '-help' || $opt eq '--help') {
      show_usage();
    } elsif ($opt eq '-v' || $opt eq '--version') {
      say("$program version $version");
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
sub panic {
  info("PANIC(@_)"); exit(-2);
}
sub error {
  info(@_); exit(-1);
}

#-----------------------------------------------------------
# Foolysh

use constant {
  FOOLYSH_WAIT_INTV => 0.5,
  FOOLYSH_WAIT_LIMIT => 600,
};

my $foolysh_dir;

sub foolysh_main {
  $foolysh_dir = $ENV{WYNHOTEP_FOOLYSH_DIR};
  (-d $foolysh_dir) or error("no such directory", $foolysh_dir);
  my $name = "whtp$$";
  my $dir = "$foolysh_dir/$name";
  my $sh = "$foolysh_dir/$name.sh";
  mkdir($dir) or error("failure", $dir);
  foolysh_export($dir);

  write_whole($sh, "satysfi @ARGV");
  for (my $w = 0; $w < FOOLYSH_WAIT_LIMIT; $w += FOOLYSH_WAIT_INTV) {
    sleep(FOOLYSH_WAIT_INTV);
    (! -f $sh) and last;
  }
  (! -f $sh) or error("failure in foolysh");
  foolysh_import($dir);
  my $out = read_whole("$dir/__stdout");
  my $err = read_whole("$dir/__stderr");
  unlink($sh, glob("$dir/*"));
  rmdir($dir);

  print STDERR ($err);
  print($out);
}

sub foolysh_export {
  my ($dir) = @_;
  foreach my $f (glob("*.*")) {
    copy($f, "$dir/$f");
  }
}

sub foolysh_import {
  my ($dir) = @_;
  foreach my $f (glob("$dir/*.pdf")) {
    my $ff = $f =~ s|.*/||r;
    copy($f, $ff);
  }
}

#-----------------------------------------------------------
# Docker helpers

use constant DOCKER => 'docker';

my $docker = DOCKER;

sub docker_check_image {
  my ($image) = @_;
  local $_ = `$docker images`;
  ($? == 0) or error("Docker is not working");
  foreach (split(m/\n/, $_)) {
    my $id = (split(m/\s+/, $_, 2))[0];
    ($id eq $image) and return 1;
  }
  return;
}

sub docker_get_workdir {
  my ($image) = @_;
  local $_ = `$docker run --rm $image pwd`; chomp($_);
  ($? == 0 && $_ ne '') or docker_error();
  return $_;
}

sub docker_get_user {
  my ($image) = @_;
  local $_ = `$docker run --rm $image id -u -n`; chomp($_);
  ($? == 0 && $_ ne '') or docker_error();
  return $_;
}

sub docker_get_hostdir {
  local $_ = getcwd();
  if ($windows) {
    if (m|^\w:/|ai) {
      substr($_, 0, 2) = lc(substr($_, 0, 1)) . '/';
    } else {
      error("cannot use the current dicctory", $_);
    }
  }
  return $_;
}

sub docker_error {
  info("DOCKER ERROR"); exit(-1);
}

#-----------------------------------------------------------
# Docker

use constant {
  DOCKER_DEFAULT_WORKDIR => '/tmp',
};

my $docker_image;

sub docker_main {
  $docker_image = $ENV{WYNHOTEP_DOCKER_IMAGE};
  if (!docker_check_image($docker_image)) {
    if ($ARGV[0] ne '--version') {
      print STDERR ("Docker image '$docker_image' is yet not loaded.\n");
      print STDERR ("Hit Enter to start loading...");
      <STDIN>;
    }
    system("$docker pull $docker_image");
    ($? == 0) or docker_error();
  }

  my $workdir = DOCKER_DEFAULT_WORKDIR;
  local $_ = $ENV{WYNHOTEP_DOCKER_WORKDIR};
  ($_ ne '') and $workdir = docker_resolve_workdir($_);

  my $hostdir = docker_get_hostdir();
  system("$docker run -it --rm -v $hostdir:$workdir -w $workdir $docker_image"
   . " satysfi @ARGV");

  exit($? >> 8);
}

sub docker_resolve_workdir {
  local ($_) = @_;
  (m|^/|) and return $_;
  my $wd = docker_get_workdir($docker_image);
  s|/$||; s|^\.$||;
  return $wd . (($_ eq '') ? '' : "/$_");
}

#-----------------------------------------------------------
# DockerWH (use pipe)

use constant {
  DOCKERWH_IMAGE_NAME => 'zr-tex8r/wynhotep',
};

my $docker_base_image;

sub dockerwh_main {
  $docker_base_image = $ENV{WYNHOTEP_DOCKER_IMAGE};
  $docker_image = DOCKERWH_IMAGE_NAME;
  if (!docker_check_image($docker_image)) {
    if ($ARGV[0] ne '--version') {
      print STDERR ("Docker image '$docker_image' is yet not built.\n");
      print STDERR ("Hit Enter to start building...");
      <STDIN>;
    }
    dockerwh_build_image();
  }

  my $input = dockerwh_make_input();
  my $output = dockerwh_run_container($input);
  dockerwh_make_output($output);
}

sub dockerwh_make_input {
  my $tar = "$tempb-in.tar.gz";
  my $probe = "probe.whtp";
  unlink($tar);
  write_whole($probe, "SATySFi");
  system("tar cfz $tar *.* 1>$tempb.out 2>$tempb.err");
  ($? == 0 && -s $tar) or error("failure in tar");
  unlink($probe, "$tempb.out", "$tempb.err");
  return $tar;
}

sub dockerwh_make_output {
  my ($tar) = @_;
  if (-s $tar) { # output files exist
    system("tar xfz $tar 1>$tempb.out 2>$tempb.err");
    #($? == 0) or error("failure in tar");
    unlink("$tempb.out", "$tempb.err");
  }
  unlink($tar);
}

sub dockerwh_run_container {
  my ($in) = @_;
  my $out = "$tempb-out.tar.gz";
  system("$docker run --rm -i $docker_image @ARGV <$in >$out");
  ($? == 0 && -f $out) or docker_error();
  unlink($in);
  return $out;
}

sub dockerwh_build_image {
  if (!docker_check_image($docker_base_image)) {
    info("pull docker base image", $docker_base_image);
    system("$docker pull $docker_base_image");
    ($? == 0) or docker_error();
  }
  info("build docker image", $docker_image);
  my $user = docker_get_user($docker_base_image);
  my $wd = docker_get_workdir($docker_base_image);
  my ($dockerfile, $script) = dockerwh_build_source($user, $wd);
  mkdir("$tempb-build") or error("cannot create directory");
  chdir("$tempb-build") or panic();
  write_whole("Dockerfile", $dockerfile);
  write_whole("run-satysfi.sh", $script);
  system("$docker build -t $docker_image .");
  ($? == 0) or docker_error();
  (-f "Dockerfile") and unlink("Dockerfile", glob("*.*"));
  chdir("..") or panic();
  rmdir("$tempb-build") or error("cannot remove directory");
}

sub dockerwh_build_source {
  my ($user, $workdir) = @_;
  my $dockerfile = <<"EOT";
FROM $docker_base_image
ADD run-satysfi.sh /tmp/
USER $user
RUN mkdir -p $workdir/_scripts && mkdir -p $workdir/_work \\
  && cp /tmp/run-satysfi.sh $workdir/_scripts \\
  && chmod +x $workdir/_scripts/run-satysfi.sh
WORKDIR $workdir/_work
ENTRYPOINT ["$workdir/_scripts/run-satysfi.sh"]
EOT
  my $script =  <<"EOT";
#!/bin/bash
if [ -f ~/.profile ]; then
  . ~/.profile || true
fi
# receive input files
cat - | tar xfz - >/dev/null 2>&1
# do it
satysfi \$* 1>&2
if ls *.pdf >/dev/null 2>&1
then
  # send output files
  tar cfz __out.tar.gz *.pdf *.satysfi-aux >/dev/null 2>&1
  cat __out.tar.gz
fi
EOT
  return ($dockerfile, $script);
}

#-----------------------------------------------------------
main();
# EOF
