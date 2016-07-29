package zw5ap;
##
## $Id$
##
## rancid 3.2
## Copyright (c) 1997-2015 by Terrapin Communications, Inc.
## All rights reserved.
##
## This code is derived from software contributed to and maintained by
## Terrapin Communications, Inc. by Henry Kilmer, John Heasley, Andrew Partan,
## Pete Whiting, Austin Schutz, and Andrew Fort.
##
## Redistribution and use in source and binary forms, with or without
## modification, are permitted provided that the following conditions
## are met:
## 1. Redistributions of source code must retain the above copyright
##    notice, this list of conditions and the following disclaimer.
## 2. Redistributions in binary form must reproduce the above copyright
##    notice, this list of conditions and the following disclaimer in the
##    documentation and/or other materials provided with the distribution.
## 3. All advertising materials mentioning features or use of this software
##    must display the following acknowledgement:
##        This product includes software developed by Terrapin Communications,
##        Inc. and its contributors for RANCID.
## 4. Neither the name of Terrapin Communications, Inc. nor the names of its
##    contributors may be used to endorse or promote products derived from
##    this software without specific prior written permission.
## 5. It is requested that non-binding fixes and modifications be contributed
##    back to Terrapin Communications, Inc.
##
## THIS SOFTWARE IS PROVIDED BY Terrapin Communications, INC. AND CONTRIBUTORS
## ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
## TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
## PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COMPANY OR CONTRIBUTORS
## BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
## CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
## SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
## INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
## CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
## ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
## POSSIBILITY OF SUCH DAMAGE.
#
#  RANCID - Really Awesome New Cisco confIg Differ
#
#  zw5ap.pm - Zebra WiNG5 Access Point support by Thomas Equeter

use 5.010;
use strict;
use warnings;

use Exporter 'import';
use rancid 3.2;

use base qw( rancid main );

## All these exported variables are used by the calling rancid script
#@EXPORT = qw( $timeo $clean_run $prompt );
our $timeo = 10;    # These devices are SLOW
our $clean_run = 1; # No logout message we could use, so assume clean run
                    # unless set otherwise.
#our $prompt;
# imports: $filter_commstr $found_end

# post-open(collection file) initialization
sub init {
    # add content lines and separators
    ProcessHistory("","","","!RANCID-CONTENT-TYPE: $devtype\n!\n");

    0;
}

# main loop of input of device output
sub inloop {
    use strict;
    use warnings;

    my($INPUT, $OUTPUT) = @_;
    my($cmd, $rval);

    LINE: while(<$INPUT>) {
        # Only remove \r, rancid expects \n at the end of string!
	tr/\r//d;
	if (/^Error:/) {
	    print STDOUT ("$host clogin error: $_");
	    print STDERR ("$host clogin error: $_") if ($debug);
	    $clean_run = 0;
	    last;
	}
        if (!defined $prompt) {
            if (/^([^#>]+)>$/) {
                # clogin sends us the first prompt at some point. Use it to match
                # "prompt>command" lines later.
                $prompt = ( quotemeta $1 ) . '[#>]';
                print STDERR ("PROMPT MATCH: $prompt\n") if ($debug);
            }

            # And nothing really interesting happens before that anyway
            next;
        }
	if (/$prompt($cmds_regexp)/) {
	    my $cmd = $1;
	    print STDERR ("HIT COMMAND:$_") if ($debug);
	    if (! defined($commands{$cmd})) {
		print STDERR "$host: found unexpected command - \"$cmd\"\n";
		$clean_run = 0;
		last LINE;
	    }
            my $rval;
            {
                no strict 'refs';
                $rval = &{$commands{$cmd}}($INPUT, $OUTPUT, $cmd);
            }
	    delete($commands{$cmd});
	    if ($rval == -1) {
		$clean_run = 0;
		last LINE;
	    }
            # The command function consumes the (only) $prompt line between the
            # commands:
            # ...cmd1 output...
            # ap0000>cmd2
            # ...cmd2 output...
            # Therefore, do not read the next line, use the $_ set by the
            # command function instead.
            redo LINE;
	}
    }
}

# This routine parses "show running-config"
sub ShowConfig {
    use strict;
    my($INPUT, $OUTPUT, $cmd) = @_;
    print STDERR "    In ShowConfig: $_" if ($debug);
    ProcessHistory("","","","\n!--zw5ap Begin Config Data--!\n");

    while (<$INPUT>) {
        tr/\r//d;

        # remove snmp community string data
	if (/^(\s*snmp-server community\b)/ && $filter_commstr) {
	    ProcessHistory("","","","!$1 <removed>\n"); next;
	}
	if (/^(\s*snmp-server user \w+ v3 encrypted \w+ auth \w+ 0\b)/ && $filter_commstr) {
	    ProcessHistory("","","","!$1 <removed>\n"); next;
	}

        # Remove passwords
        if (/^(\s*(?:user \w+ password|\S+ psk) 0\b)/ && $filter_pwds) {
            ProcessHistory("","","","!$1 <removed>\n"); next;
        } elsif (/^(\s*(?:user \w+ password|\S+ psk)\b)/ && $filter_pwds >= 2) {
            ProcessHistory("","","","!$1 <removed>\n"); next;
        }

	if (/^end$/) {
            $found_end = 1;
        }

	if (/^$prompt/) {
            last;
        } else {
	    print(STDERR "      ShowConfig Data: $_") if ($debug);
	    ProcessHistory("","","","$_");
	}
    }
    ProcessHistory("","","","\n!--zw5ap End Config Data--!\n");
    print STDERR "    Exiting ShowConfig: $_" if ($debug);

    return $found_end;
}

sub ShowVersion {
    use strict;
    my($INPUT, $OUTPUT, $cmd) = @_;
    print STDERR "    In ShowVersion: $_" if ($debug);
    ProcessHistory("","","","\n!--zw5ap Begin Command $cmd--!\n");

    while (<$INPUT>) {
        tr/\r//d;

	next if (/uptime is/);

	if (/^$prompt/) {
            $found_end = 1;
            last;
        } else {
	    print(STDERR "      ShowVersion $cmd: $_") if ($debug);
	    ProcessHistory("","","","$_");
	}
    }
    ProcessHistory("","","","\n!--zw5ap End Command $cmd--!\n");
    print STDERR "    Exiting ShowVersion $cmd: $_" if ($debug);

    return $found_end;
}

1;
