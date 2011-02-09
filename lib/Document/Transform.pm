package Document::Transform;

#ABSTRACT: Pull and transform documents from a NoSQL backend

use Moose;
use namespace::autoclean;

use Try::Tiny;
use Throwable::Error;
use MooseX::Params::Validate;
use MooseX::Types::Moose(':all');
use Document::Transform::Transformer;
use Document::Transform::Types(':all');
use Moose::Util::TypeConstraints('match_on_type');

=atribute_public backend

    is: ro, does: L<Document::Transform::Role::Backend>, required: 1

The backend attribute is required for instantiation of the Document::Transform
object. The backend object is what talks to whichever NoSQL resource to fetch
and store documents and transforms.

You are encouraged to implement your own backends. Simply consume the interface
role L<Document::Transform::Role::Backend> and implement the required methods.

=cut

has backend =>
(
    is => 'ro', 
    does => 'Document::Transform::Role::Backend',
    required => 1,
    handles => 'Document::Transform::Role::Backend',
);

=attribute_public transformer

    is: ro, does: L<Document::Transform::Role::Transformer>

The transformer is the object to which transformation responsibilities are
delegated. By default, the L<Document::Transform::Transformer> class is
instantiated when none is provided. Please see its documentation on the
expectations of document and transform formats. 

If you would like to implement your own transformer (to support your own
document and transform formats), simply consume the interface role
L<Document::Transform::Role::Transformer> and implement the transform method.

=cut

has transformer =>
(
    is => 'ro',
    does => 'Document::Transform::Role::Transformer',
    default => sub { Document::Transform::Transformer->new() },
    handles => 'Document::Transform::Role::Transformer',
);

=attribute_public post_fetch_callback

    is: ro, isa: CodeRef

post_fetch_callback simply provides a way to do additional processing after
the document has been fetched and transform executed. One good use for this is
if validation of the result needs to take place. This coderef is called naked
with a single argument, the final document. Throw an exception if execution
should stop.

=cut


has post_fetch_callback =>
(
    is => 'ro',
    isa => CodeRef,
    predicate => 'has_post_fetch_callback',
);

=method_public fetch

    (Str)

fetch performs a transform lookup using the provided key argument, then a
document lookup based information inside the transform. Once it has both pieces,
it passes them on to the transformer via the transform method. The result is
then passed to the callback L</post_fetch_callback> before finally being
returned.

If for whatever reason there isn't a transform with that key, but there is a
document with that key, the document will be fetched and not transformed. It is
still subject to the L</post_fetch_callback> though.

=cut

sub fetch
{
    my ($self, $key) = pos_validated_list
    (
        \@_,
        {isa => __PACKAGE__},
        {isa => Str}
    );
    
    my $ret;

    my $transform = $self->fetch_transform($key);
    unless(defined($transform))
    {
        my $document = $self->fetch_document($key);
        unless(defined($document))
        {
            Throwable::Error->throw
            ({
                message => 'Unable to fetch anything useful with: '.$key
            });
        }
        $ret = $document;
    }
    else
    {
        my $document = $self->fetch_document($transform->{document_id});
        unless(defined($document))
        {
            Throwable::Error->throw
            ({
                message => 'Unable to fetch a document referenced by this:' .
                    $transform->{document_id}
            });
        }
        my $final = $self->transform($document, $transform);

        if($self->has_post_fetch_callback)
        {
            $self->post_fetch_callback->($final);
        }

        $ret = $final;
    }

    return $ret;
}

=method_public store

    (DocumentOrTransform)

store takes a single item as an argument and depending on the
DocumentOrTransform it will execute the appropriate store method on the
backend.

=cut

sub store
{
    my ($self, $item) = pos_validated_list
    (
        \@_,
        {isa => __PACKAGE__},
        {isa => DocumentOrTransform}
    );

    match_on_type $item =>
    (
        Document => sub { $self->store_document($item) },
        Transform => sub { $self->store_transform($item) },
    );
}

=method_public check_fetch_document

    (Str)

A document fetch is attempted with the provided argument. If successful, it
returns true.

=cut

sub check_fetch_document
{
    my ($self, $key) = pos_validated_list
    (
        \@_,
        {isa => __PACKAGE__},
        {isa => Str}
    );

    return defined($self->fetch_document($key));
}

=method_public check_fetch_transform

    (Str)

A transform fetch is attempted with the provided argument. If successful, it
returns true.

=cut

sub check_fetch_transform
{
    my ($self, $key) = pos_validated_list
    (
        \@_,
        {isa => __PACKAGE__},
        {isa => Str}
    );

    return defined($self->fetch_transform($key));
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=head1 SYNOPSIS

    use Try::Tiny;
    use Document::Transform;
    use Document::Transform::Backend::MongoDB;

    my $backend = Document::Transform::Backend::MongoDB->new(
        host => $ENV{MONGOD} );

    my $transform = Document::Transform->new(backend => $backend);
    
    my $result;

    try
    {
        $result = $transform->fetch('SOME_DOCUMENT');
    }
    catch
    {
        warn 'Failed to fetch the document';
    }

=head1 DESCRIPTION

Ever need to fetch a document from some NoSQL source, and wanted a way to store
only the specific changes to that document in a separate document and magically
combine the two when you ask for the more specific document? Then this module
will help you get that pony you've always wanted.

Consider the following JSON document:

    {
        "document_id": "QWERTY1",
        "foo": "bar",
        "yarg":
        [
            "one",
            "two",
            "three"
        ],
        "blarg": "sock puppets rock"
    }

This is an awesome, typical document stored in something like MongoDB. Now, what
if we had hundreds of other documents that were all the same except the "blarg"
attribute was slightly different? It would be wasteful to store all of those
whole complete documents. And what if we wanted to update them all? That could
potentially be expensive. So what is the solution? Store a core document, and
store the set of changes to morph it into the more specific or different
document separately. Then when you update the core document, everything else
continues to work without manually touching all of the other documents.

So what does a transform look like? Like this:

    {
        "transform_id": "YTREWQ1",
        "document_id": "QWERTY1",
        "operations":
        [
            {
                "path": "/yarg/*[0]",
                "value": "ONE"
            },
            {
                "path": "/foo",
                "value": "BAR"
            },
            {
                "path": "/qwak/farg",
                "value": { "yarp": 1, "narp": 0 }
            }
        ]
    }

Jumpin' jehosaphat! What is all of that line noise? So, you can see how this
transform references the core document via the document_id attribute. The
transform_id is what we use to fetch this transform. The operations attribute
holds an array of tuples. Each tuple is merely a L<Data::DPath> path
specification and a value to be used at that location. What is a Data::DPath
path? Well, it is like XPath but for data structures. It is some good stuff.

So the first two operations look simple enough. We reference locations that
exist and replace those values with all caps versions, but what about the last
operation? The original document doesn't have anything that matches that path.
Well, you're in luck. If your path is simple enough, the transformer will
create that path for you and dump your value there for you. Now, let me stress
"simple enough." It needs to be straight hashes, no filters, no array access,
etc. So, '/this/path/rocks' will work just fine. '/this/*[4]/path/sucks' will
not work. If you would like it to work, you are more than welcome to implement
your own transformer. Simply consume the interface role
L<Document::Transform::Role::Transformer> and implement the transform method and
pass in an instance and you are set.

This module ships with one backend and one transformer implemented but you
aren't married to either if you don't like MongoDB or think the transformer
semantics are subpar. This module and its packages are all very L<Bread::Board>
friendly. 
