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
            && exists($_->{_id}) && class_type('MongoDB::OID')->check($_->{ID})
    };

=type Transform
    
    as HashRef

A transform is defined as a HashRef with a few keys: document_id, transform_id,
and operations. operations needs to be an ArrayRef of hashes with the keys path
and value defined. 

=cut

subtype Transform,
    as Dict
    [
        document_id => Str, 
        transform_id => Str,
        operations => ArrayRef[Dict[path => Str, value => Defined]],
        _id => class_type 'MongoDB::OID',
    ];

=type DocumentOrTransform

    as Document|Transform;

This type is simply a union of the L</Transform> and L</Document> types.

=cut

subtype DocumentOrTransform,
    as Document|Transform;

1;
__END__
