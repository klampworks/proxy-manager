#!/usr/bin/perl -w

use LWP::UserAgent;
use POSIX qw/strftime/;

use HTTP::Request::Common qw(POST);
use HTTP::Cookies;
use File::Copy qw(move);

$user_agent = new LWP::UserAgent;
#$user_agent->proxy([qw/ http https /] => 'socks://localhost:9050');
$user_agent->agent('Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)');
$user_agent->timeout(60);

$site = 'http://hidemyass.com/proxy-list/';

for (my $page = 0; $page < 14; $page++) {

	get(($site . $page));
	parse("tmp");
}


@blocks;
sub parse_ip {

	$block = shift;

	@bad = ();

	while ($block =~ m/\.([^{]+){display:none}/g) {
		push(@bad, $1);
	}

	$block =~ s/\.([^{]+){display:.*\s//g;
	
	$block =~ s/<(?:span|div)[^>]+display\s*:\s*none[^>]+>\d+<\/(?:span|div)>//g;
	$block =~ s/<span><\/span>//g;


	$ban = shift @bad;

	foreach my $baddie (@bad) {
		$ban .= "|" . $baddie;
	}

	$block =~ s/<(?:span|div)[^>]+class\s*=\s*\"($ban)\"[^>]*>\d+<\/(?:span|div)>//g;

	$block =~ s/<[^>]+>//g;

	$block =~ s/\s//g;

	return $block;
}

sub parse {

	$file 	=  $_[0];

	open IN, '<', $file;

	$index = -1;
	$flag = 0;
	$block2 = "";
	while (<IN>) {

		if ($flag == 0) {
			if ($_ =~ m/<td><span><style>/) {
				$flag = 1;
			}	
		} else {
			$block2 .= $_;

			if ($_ =~ m/<\/span><\/td>/) {
				$flag = 0;
				$ip = parse_ip($block2);
				$block2 = "";
			}	
		}

		if ($_ =~ m/^(\d+)<\/td>/) {
			$port = $1;
		}

		if ($_ =~ m/alt=\"flag\" \/> ([^<]+)<\/span><\/td>/) {
			$country = $1;
		}

		if ($_ =~ m/<td>(HTTP|HTTPS|socks4\/5)<\/td>/) {
			$proto = $1;
			$proto =~ s/\//-/g;
			
			if ($ip !~ m/(^\d+\.\d+\.\d+\.\d+$)/) {
				next;
			}

			mkdir $country;

			to_file(($country . "/" . $proto), ($ip . ":" . $port));
			print "$ip\n";
			print "$port\n";
			print "$country\n";
			print "$proto\n\n";
		}

	}
}

sub to_file {

	$filename = shift;
	$value = shift;

	open INNN, '<', $filename;

	while (<INNN>) {
		if ($_ =~m/^$value\s$/) {
			close INNN;
			return;
		}
	}

	close INNN;

	open OUT, '>>', $filename;
		print OUT "$value\n";
	close OUT;
}

sub get {

	$url_to_get 	=  $_[0];
	$ref 		=  $_[2];
	
	print get_time() . "Fetching $url_to_get...\n";

	$request = new HTTP::Request('GET', $url_to_get);
	$request->header('Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8');
	$request->header('Accept-Charset' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7');
	$request->header('Referer' => $ref);
	
	$response = $user_agent->request($request);
	
	print get_time() . "...[DONE]\n";


        open OUT, '>', "tmp" or die "Cant open $file_to_save:$!";
		print OUT  $response->{_content};
	close OUT;

}


sub get_time {
	return "[" . strftime('%D %T',localtime) . "] ";
}
