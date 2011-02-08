package Document::Transform::Types;
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

subtype Document,
    as HashRef,
    where
    {
        exists($_->{document_id}) && not exists($_->{transform_id})
            && exists($_->{_id}) && class_type('MongoDB::OID')->check($_->{ID})
    };

subtype Transform,
    as Dict
    [
        document_id => Str, 
        transform_id => Str,
        operations => ArrayRef[Dict[path => Str, value => Defined]],
        _id => class_type 'MongoDB::OID',
    ];

subtype DocumentOrTransform,
    as Document|Transform;

1;
__END__
