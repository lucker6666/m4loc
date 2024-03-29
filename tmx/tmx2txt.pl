#!/usr/bin/perl -w

require 5.010;

#
# Extraction of a bilingual corpus from a TMX file
#
# Copyright 2010 Digital Silk Road
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http:/$replace/www.gnu.org/licenses/>.
#

use strict;
use XML::TMX::Reader;
use Getopt::Std;

our $opt_s;
getopts('s');
my $replace = $opt_s?' ':'';

if(@ARGV != 4) {
    print STDERR "Usage: perl $0 [-s] <source language> <target language> <output basename> <tmx file>\n";
    exit;
}

my ($srcLang,$tgtLang,$outBase,$tmxFile) = @ARGV;

my $reader = XML::TMX::Reader->new($tmxFile);
die "TMX file $tmxFile could not be opened" unless defined($reader);
if($opt_s) {
    # bad: encapsulation broken, but ignore_markup member function has bug
    $reader->{ignore_markup} = 0;
}
open(SRCOUT,">:utf8",$outBase.".".$srcLang) || die "Cannot open source output file: $outBase.$srcLang";
open(TGTOUT,">:utf8",$outBase.".".$tgtLang) || die "Cannot open target output file: $outBase.$tgtLang";

# Cannot use the for_tu interface here - process will run out of memory on larger files
$reader->for_tu(sub{
    my $tu = shift;
    if(exists($$tu{$srcLang}) && exists($$tu{$tgtLang})) {
	# Necessary as some tu's can contain newlines
	my $srcText = $$tu{$srcLang}{'-seg'};
	my $tgtText = $$tu{$tgtLang}{'-seg'};
	# Workaround for bug in XML::TMX::Reader
	$srcText =~ s/ARRAY\(.*?\)/$replace/g;
	$srcText =~ s/<ut>.*?<\/ut>/$replace/g;
	$srcText =~ s/<.*?>/$replace/g;
	$srcText =~ s/^\s*//;
	$srcText =~ s/\s*$//;
	$srcText =~ s/\R/$replace/g;
	# Workaround for bug in XML::TMX::Reader
	$tgtText =~ s/ARRAY\(.*?\)/$replace/g;
	$tgtText =~ s/<ut>.*?<\/ut>/$replace/g;
	$tgtText =~ s/<.*?>/$replace/g;
	$tgtText =~ s/^\s*//;
	$tgtText =~ s/\s*$//;
	$tgtText =~ s/\R/$replace/g;
	chomp $srcText;
	chomp $tgtText;
	if($srcText && $tgtText) {
	    print SRCOUT $srcText."\n";
	    print TGTOUT $tgtText."\n";
	}
    }
});

close(TGTOUT);
close(SRCOUT);

__END__

=head1 tmx2txt.pl: Extraction of a bilingual corpus from a TMX file

=head2 USAGE

    perl tmx2txt.pl [-s] <source language> <target language> <output basename> <tmx file>

This tool extracts a bilingual corpus from a TMX file that contains segments in at least two languages. The resulting parallel corpus is stored in two files named C<< <output basename>.<source language> >> and C<< <output basename>.<target language> >> which are UTF-8 encoded. The tool does not verify if the two languages specified on the command line actually exist in the TMX file.

The tool removes any inline formatting markup to allow the use of the corpus for the training of statistical MT systems.

C<< <output basename> >> and C<< <tmx file> >> can contain a path component in case the files are contained in a different directory. The tool needs write permission in the output directory.

=over

=item B<-s>

If option C<< -s >> is set, inserts a single space for deleted markup instead of just deleting it.

=back

=head2 PREREQUISITES

XML::TMX::Reader
