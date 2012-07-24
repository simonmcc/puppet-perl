# from http://www.windley.com/archives/2008/10/using_puppet_and_cpan.shtml


class perl {
  if !defined(Package['perl']) { package { "perl": ensure => installed } }
}

class perl::cpan_config {
  include perl

  # TODO: need to find a cleaner way of deoing this
  # use the local_network.6 as the proxy (i.e. install server)
  # default http_proxy for Config.pm
  if $network_eth0 != undef {
    $perl_http_proxy = inline_template("http://<%= network_eth0.split('.')[0..2].join('.')+'.6' %>:3128")
  }
  elsif $network_eth1 != undef {
    $perl_http_proxy = inline_template("http://<%= network_eth1.split('.')[0..2].join('.')+'.6' %>:3128")
  }
  elsif $network_bond0 != undef {
    $perl_http_proxy = inline_template("http://<%= network_bond0.split('.')[0..2].join('.')+'.6' %>:3128")
  }
  else {
    $perl_http_proxiy = '' 
  }
  

  file { '/usr/lib/perl5/5.8.8/CPAN/Config.pm':
        ensure => 'present',
        #source  => 'puppet:///modules/perl/Config.pm',
	content => template("perl/Config.pm.erb"),
  }
  
}

define perl::cpan_load() {
  # make sure that CPAN doesn't loop like crazy at the CPAN config prompt.
  # this is included as a class as a class is only applied to a node once in the evaluation
  # where as te custom type perl::cpan_load will be applied multiple times
  # causing "Duplicate definition" errors
  require perl::cpan_config

  exec{"cpan_load_${name}":
    path    => "/sbin:/bin:/usr/sbin:/usr/bin:/root/bin",
    command => "perl -MCPAN -e '\$ENV{PERL_MM_USE_DEFAULT}=1; CPAN::Shell->install(\"${name}\")'",
    onlyif =>
          "test `perl -M${name} -e 'print 1' 2>/dev/null || echo 0` == '0'",
  }
}

define perl::cpan_load_by_name() {
  # make sure that CPAN doesn't loop like crazy at the CPAN config prompt.
  # this is included as a class as a class is only applied to a node once in the evaluation
  # where as te custom type perl::cpan_load will be applied multiple times
  # causing "Duplicate definition" errors
  require perl::cpan_config

  exec{"cpan_load_by_name_${title}":
    path    => "/sbin:/bin:/usr/sbin:/usr/bin:/root/bin",
    command => "perl -MCPAN -e '\$ENV{PERL_MM_USE_DEFAULT}=1; CPAN::Shell->install(\"${name}\")'",
    onlyif =>
          "test `perl -M${title} -e 'print 1' 2>/dev/null || echo 0` == '0'",
  }
}

# this invocation required you to pass the version & package
# cpan_version { 'File::Path': bundle => 'DLAND/File-Path-2.08.tar.gz', version => '2.08' }
#
# perl -MFile::Path -e 'print File::Path->VERSION'
# http://search.cpan.org/CPAN/authors/id/D/DL/DLAND/File-Path-2.08.tar.gz

define perl::cpan_version($package, $version) {
  # make sure that CPAN doesn't loop like crazy at the CPAN config prompt.
  # this is included as a class as a class is only applied to a node once in the evaluation
  # where as te custom type perl::cpan_load will be applied multiple times
  # causing "Duplicate definition" errors
  require perl::cpan_config

  exec{"cpan_load_by_version_${title}":
    #
    timeout => 600,     # initial CPN operations can take a while
    path    => "/sbin:/bin:/usr/sbin:/usr/bin:/root/bin",
    command => "perl -MCPAN -e '\$ENV{PERL_MM_USE_DEFAULT}=1; CPAN::Shell->install(\"${package}\")'",
    onlyif => "test `perl -M${title} -e 'exit(2) if ${title}->VERSION != \"${version}\"' 2>/dev/null || echo 0` == '0'",
  }

}

