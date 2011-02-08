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

has backend =>
(
    is => 'ro', 
    does => 'Document::Transform::Role::Backend',
    required => 1,
    handles => 'Document::Transform::Role::Backend',
);

has transformer =>
(
    is => 'ro',
    does => 'Document::Transform::Role::Transformer',
    default => sub { Document::Transform::Transformer->new() },
    handles => 'Document::Transform::Role::Transformer',
);

has post_fetch_callback =>
(
    is => 'ro',
    isa => CodeRef,
    predicate => 'has_post_fetch_callback',
);

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
