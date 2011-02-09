package Document::Transform::Role::Backend;

#ABSTRACT: Interface role to be consumed by backends

use Moose::Role;
use namespace::autoclean;

=role_requires fetch_transform

This method must accept a string key and should return a
L<Document::Transform::Types/Transform>

=cut

=role_requires fetch_document

This method must accept a string key and should return a
L<Document::Transform::Types/Document>

=cut

=role_requires store_transform

This method should accept a L<Document::Transform::Types/Transform> and store it
in the backend.

=cut

=role_requires store_document

This method should accept a L<Document::Transform::Types/Document> and store it
in the backend.

=cut

requires qw/fetch_transform fetch_document store_transform store_document/;

1;
__END__

=head1 SYNOPSIS

    package MyBackend;
    use Moose;

    sub fetch_document { }
    sub fetch_transform { }
    sub store_document { }
    sub store_transform { }

    with 'Document::Transform::Role::Backend';
    1;

=head1 DESCRIPTION

Want to manage the backend to some other NoSQL database? Then you'll want to
consume this role and implement the needed functions. Generally, the store
functions should take data structures that conform the Types listed in
L<Document::Transform::Types> and the fetch methods should return those as well.

