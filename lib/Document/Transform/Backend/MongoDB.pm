package Document::Transform::Backend::MongoDB;
use Moose;
use namespace::autoclean;

use MongoDB;
use Throwable::Error;
use MooseX::Params::Validate;
use MooseX::Types::Moose(':all');
use Document::Transform::Types(':all');

has host =>
(
    is => 'ro',
    isa => Str,
    predicate => 'has_host',
);

has connection =>
(
    is => 'ro', 
    isa => 'MongoDB::Connection',
    default => sub
    {
        my $self = shift;
        unless($self->has_host)
        {
            Throwable::Error->throw
            ({
                message => 'host must be provided to use the default ' .
                    'connection constructor'
            });
        }
        return MongoDB::Connection->new(host => $self->host)
    },
    lazy => 1,
);

has database_name =>
(
    is => 'ro',
    isa => Str,
    predicate => 'has_database_name',
);

has database =>
(
    is => 'ro',
    isa => 'MongoDB::Database',
    default => sub
    {
        my $self = shift;
        unless($self->has_database_name)
        {
            Throwable::Error->throw
            ({
                message => 'database must be provided to use the default ' .
                    'db constructor'
            });
        }
        return $self->connection->${\$self->database_name};
    },
    lazy => 1,
);

has document_collection =>
(
    is => 'ro',
    isa => Str,
    predicate => 'has_document_collection',
);

has documents =>
(
    is => 'ro',
    isa => 'MongoDB::Collection',
    default => sub
    {
        my $self = shift;
        unless($self->has_document_collection)
        {
            Throwable::Error->throw
            ({
                message => 'document_collection must be provided to use the ' .
                    'default docs constructor'
            });
        }

        return $self->database->${\$self->document_collection};
    },
    lazy => 1,
);

has transforms_collection =>
(
    is => 'ro',
    isa => Str,
    predicate => 'has_transforms_collection',
);

has transforms =>
(
    is => 'ro',
    isa => 'MongoDB::Collection',
    default => sub
    {
        my $self = shift;
        unless($self->has_transforms_collection)
        {
            Throwable::Error->throw
            ({
                message => 'transforms_collection must be provided to use the ' .
                    'default trans constructor'
            });
        }

        return $self->database->${\$self->transforms_collection};
    },
    lazy => 1,
);

sub fetch_document
{
    my ($self, $key) = pos_validated_list
    (
        \@_,
        {isa => __PACKAGE__},
        {isa => Str},
    );

    return $self->documents->find_one({document_id => $key});
}

sub fetch_transform
{
    my ($self, $key) = pos_validated_list
    (
        \@_,
        {isa => __PACKAGE__},
        {isa => Str},
    );

    return $self->transforms->find_one({transform_id => $key});
}

sub store_document
{
}

sub store_transform
{
}

with 'Document::Transform::Role::Backend';
__PACKAGE__->meta->make_immutable();
1;
__END__
