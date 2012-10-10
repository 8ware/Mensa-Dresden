use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Mensa::Dresden',
    VERSION_FROM      => 'lib/Mensa/Dresden.pm', # finds $VERSION
    PREREQ_PM         => {
		'XML::LibXML' => 0,
		'XML::LibXSLT' => 0,
		'YAML::Tiny' => 0,
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Mensa/Dresden.pm', # retrieve abstract from module
       AUTHOR         => '8ware <8wared@googlemail.com>') : ()),
	EXE_FILES => [ 'mensa' ],
);

