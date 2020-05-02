package Misc;

# Copyright (c) 1999-2000 Gabriel M. Deal. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(debug_start debug_end bad_args xdie xsprintf stack_trace);

#my $debug = *STDERR{IO};

use Carp;

=head1 NAME

Misc.pm - miscellaneous functions I find useful

=cut

=head1 sub debug_start($;@)

Prints out useful diagnostic information when entering a function.
The first argument is the filehandle to print to, the second is the
arguments to the function it is called from.

Try calling it like this from class methods:
  Misc::debug_start($debug_fh, @_[ 1 .. $#_ ]) if defined $debug and $debug;

=cut

=head1 sub debug_end($;$)

Prints out useful diagnostic information right before exiting a
function.   Assumes that the function will exit on the next line.
Pass it the filehandle to print to, and the return value of the
function.

=cut

{	# a closure, $count is static and shared between the two functions

	my $count = 0;
	sub debug_start($;@)
	{	my $fh = shift || *STDERR{IO};
		my @arguments = @_;

		my $save = $^W;	# setting $^W to false unsets the '-w' flag
		$^W = 0;
		@arguments = map { chomp $_ ; s/^\s+// ; s/\s+$// ; s/\s+/ /g ; $_ } @arguments;
		$^W = $save;
		my ($package, $filename, $line, $subroutine,
			$hasargs, $wantarray, $evaltext, $is_require) = caller(1);

		$count++;
		print $fh "$subroutine(";
		$^W = 0;
		print $fh join(", ", @arguments);
		$^W = $save;
		print $fh "): entering (called at line $line of $filename, level #$count)\n";
	}
	sub debug_end($;$)
	{	my $fh = shift || *STDERR{IO};
		my @ret_val = @_;

		print $fh +(caller 1)[3] 
			. "(): leaving at line "
			. ((caller 0)[2] + 1)	# assume next line is 'return ...'
			. " (level #$count)"
			. (@ret_val > 0 ? ", returning: '" . join(' ', @ret_val) . "'.\n" : ".\n");
		$count--;
	}
}

=head1 stack_trace()

Return an array containing filename, function, and line information
about each function currently on the stack.

=cut

sub stack_trace
{	debug_start($debug) if defined $debug and $debug;

	my $i = 0;
	my($filename, $line, $subroutine, @stack_trace);
	while(($filename, $line, $subroutine) = (caller $i)[1, 2, 3])
	{
		$i++;
		unshift @stack_trace, "$subroutine() called at line $line of $filename";
	}

	debug_end($debug) if defined $debug and $debug;
	return @stack_trace;
}

=head1 xdie(;@)

Exit by passing the elements of the passed array to die(), if the last
element in the passed array does not end with a newline (or no
arguments are passed), also print out a stack trace after printing the
other passed arguments.

=cut

sub xdie
{	debug_start($debug) if defined $debug and $debug;

	if(@_ == 0 or $_[$#_] !~ /\n$/)
	{
		my @stack_trace = Misc::stack_trace();
		pop @stack_trace;
		die join(' ', @_)
			. "\nStack Trace:\n\t"
			. join("\n\t", @stack_trace)
			. "\n";
	}
	else
	{
		die join(' ', @_);
	}

	debug_end($debug) if defined $debug and $debug;
}

=head1 xsprintf($string) : $string

Takes a format string in which the following strings are treated
specially:

=over

=item %p

the package name

=item %f

the filename name 

=item %l

the line 

=item %s

the subroutine name

=item %S

the package name and the subroutine name (package::subroutine)

=back

You can escape a %C string by %%C.

Returns the string with the %C sequences transformed.

=cut
sub xsprintf
{
	my($string) = @_;

	$string =~ s/%%/%% /g;

	my($pack, $fname, $line, $sub);
	($pack, $fname, $line, undef) = caller(0);
	(undef, undef, undef, $sub) = caller(1);
	$sub =~ s/^${pack}:://;

	$string =~ s/%p/$pack/g;
	$string =~ s/%f/$fname/g;
	$string =~ s/%l/$line/g;
	$string =~ s/%s/$sub/g;
	$string =~ s/%S/${pack}::$sub/g;

	$string =~ s/%% /%%/g;

	return $string;
}


=head1 bad_args($$)

I often use this to at the start of my functions like this:

 @_ == 1 or @_ == 2 Misc::bad_args("1 or 2", scalar @_);

to perform a small sanity check on the number of arguments passed.

=cut

sub bad_args($$) # ($args_expected, $args_given)
{	debug_start($debug) if defined $debug and $debug;
	my($args_expected, $args_given) = @_;

	my @stack_trace = &stack_trace();
	my($filename, $line, $subroutine) = (caller 0)[1, 2, 3];
	($subroutine) = (caller 1)[3];

	xdie "Bad arguments to $subroutine at line $line in $filename.\n"
		. "$args_given arguments given when $args_expected arguments expected.\n"
		. "Stack trace:\n\t"
		. join("\n\t", @stack_trace[0 .. ($#stack_trace - 1)])
		. "\n";

	debug_end($debug) if defined $debug and $debug;
}	


1;

