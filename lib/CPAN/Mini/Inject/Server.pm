package CPAN::Mini::Inject::Server;
use base 'CGI::Application';

use strict;
use warnings;
use Carp;
use CGI::Application::Plugin::AutoRunmode;
use CPAN::Mini::Inject;

=head1 NAME

CPAN::Mini::Inject::Server - module catchphrase

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

describe the module, working code example

=cut

=head1 DESCRIPTION

=cut

=head1 FUNCTIONS

=cut


######
#
# _mcpi
#
# Accessor for a mini cpan instance
#
###

sub _mcpi {
    my $self = shift;    

    if (not $self->{mcpi})
    {
        $self->{mcpi} = CPAN::Mini::Inject->new;
        $self->{mcpi}->load_config();
        $self->{mcpi}->parsecfg();
    }

    return $self->{mcpi};
} # end of method _mcpi


=head2 add

Invokes the controller to add a new module to the CPAN::Mini server

=cut

sub add :Runmode {
    my $self = shift;
    $self->header_add(-status => '501 Not Implemented');

    my $query = $self->query();

    my $module_name = $query->param('module');
    my $module_author = $query->params('authorid');
    my $module_version = $query->params('version');

    my $module_filename = $query->param('file');

    if (not $module_filename)
    {
        $self->header_add(-status => '400 No module archive supplied'); 
        return;
    }

    # check filename ends with tar.gz

    my $module_filetype = $query->uploadInfo($module_filename)->{'Content-Type'};

    # check filetype matches a targz

    my $bytesread;
    my $tmp_fh;

    # -e tmp file here to check we don't bash on it can be racey, just forget
    # about it

    if (not open ($tmp_fh, '>', "/tmp/$module_name-$module_version.tar.gz"))
    {
        $self->header_add(-status => '500 Internal System Error');
        return;
    }

    while ($bytesread = read($module_filename, my $buffer, 1024))
    {
        print $tmp_fh $buffer;
    }

    close ($tmp_fh);

    my $mcpi = $self->_mcpi();
    $mcpi->add(
        module => $module_name,
        authorid => $module_author,
        version => $module_version,
        file => "/tmp/$module_name-$module_version.tar.gz",
    );

    unlink "/tmp/$module_name-$module_version.tar.gz";

    $mcpi->writelist();

    $self->header_add(-status => '202 Module added');
    return;
} # end of subroutine add


=head2 update

Updates the cpan mirror

=cut

sub update :Runmode {
    my $self = shift;

    my $mcpi = $self->_mcpi();

    $mcpi->update_mirror({});
    $mcpi->inject();

    $self->header_add(-status => '202 Mirror updated');
    return;
} # end of subroutine update


=head2 inject

Injects all added modules into the cpan mirror

=cut

sub inject {
    my $self = shift;

    my $mcpi = $self->_mcpi();

    $mcpi->inject();

    $self->header_add(-status => '202 Modules injected');
    return;
} # end of subroutine inject


=head1 AUTHOR

Christopher Mckay, C<< <potatohead at potatolan.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cpan-mini-inject-server at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-Mini-Inject-Server>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CPAN::Mini::Inject::Server


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CPAN-Mini-Inject-Server>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CPAN-Mini-Inject-Server>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CPAN-Mini-Inject-Server>

=item * Search CPAN

L<http://search.cpan.org/dist/CPAN-Mini-Inject-Server/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Christopher Mckay.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of CPAN::Mini::Inject::Server
