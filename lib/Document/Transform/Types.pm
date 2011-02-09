package Document::Transform::Types;

#ABSTRACT: Provides simple constraints Document::Transform

use warnings;
use strict;

use MooseX::Types -declare =>
[qw/
    Document
    Transform
    DocumentOrTransform
/];

use MooseX::Types::Moose(':all');
use MooseX::Types::Structured(':all');


=type Document
    
    as HashRef

What defines a document for Document::Transform is pretty simple. A document
needs at least a document_id key defined and make sure it doesn't have a
transform_id key (because then it is a transform).

=cut

subtype Document,
    as HashRef,
    where
    {
        exists($_->{document_id}) && not exists($_->{transform_id})
    };

=type Transform
    
    as HashRef

A transform is defined as a HashRef with a few keys: document_id, transform_id,
and operations. operations needs to be an ArrayRef of hashes with the keys path
and value defined. 

=cut

subtype Transform,
    as HashRef,
    where
    {
        exists($_->{document_id}) && exists($_->{transform_id}) &&
        exists($_->{operations}) &&
        (ArrayRef[Dict[path => Str, value => Defined]])->check($_->{operations});
    };

=type DocumentOrTransform

    as Document|Transform;

This type is simply a union of the L</Transform> and L</Document> types.

=cut

subtype DocumentOrTransform,
    as Document|Transform;

1;
__END__
