package Document::Transform::Role::Transformer;

#ABSTRACT: Provides an interface role for Transformers implementations

use Moose::Role;
use namespace::autoclean;

=role_require transform

This role requires that you provide the transform method. If merely substituting
your own Transformer implementation, transform will need to take two arguments,
a L<Document::Transform::Types/Document> and a
L<Document::Transform::Types/Transform> with the expectation that the operations
contained with in the Transform are executed against the Document, and the
result returned. 

=cut

requires 'transform';

1;
__END__

=head1 SYNOPSIS

    package MyTransformer;
    use Moose;

    sub transform() { say 'Yarp!'; }

    with 'Document::Transform::Role::Transformer';
    1;

=head1 DESCRIPTION

Want to implement your own transformer and feed it directly to
L<Document::Transform>? Then this is your role.

Simply implement a suitable transform method and consume the role.

