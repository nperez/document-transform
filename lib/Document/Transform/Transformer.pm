package Document::Transform::Transformer;

#ABSTRACT: A document transformer. More than meets the eye. Or not.

use Moose;
use namespace::autoclean;

use Data::DPath('dpathr');
use Document::Transform::Types(':all');
use MooseX::Params::Validate;

=method_public transform

    (Document, Transform)

transform takes a Document and a Transform and performs the operations contained
with the transform against the document. Returns the transformed document.

=cut

sub transform
{
    my ($self, $document, $transform) = pos_validated_list
    (
        \@_,
        {isa => __PACKAGE__},
        {isa => Document},
        {isa => Transform},
    );
    
    foreach my $operation (@{$transform->{operations}})
    {
        my @refs = dpathr($operation->{path})->match($document);
        unless(scalar(@refs))
        {
            if($transform->{document_id} =~ m#\[|\]|\.|\*|\"|//#)
            {
                Throwable::Error->throw
                ({
                    message => 'transform path not found and the path is too '.
                        'complex for simple structure building'
                });
            }
            else
            {
                my @paths = split('/', $operation->{path});
                my $place = $document;
                for(0..$#paths)
                {
                    next if $paths[$_] eq '';
                    if($_ == $#paths)
                    {
                        $place->{$paths[$_]} = $operation->{value};
                    }
                    else
                    {
                        $place = \%{$place->{$paths[$_]} = {}};
                    }
                }
            }
        }
        else
        {
            map { $$_ = $operation->{value}; } @refs;
        }
    }

    return $document;
}

with 'Document::Transform::Role::Transformer';

__PACKAGE__->meta->make_immutable();
1;

__END__

=head1 SYNOPSIS

    use Document::Transform::Transformer;

    my $transformer = Document::Transform::Transformer->new();
    my $altered = $transformer->transform($document, $transform);

=head1 DESCRIPTION

Need a simple transformer that mashes up a transform and a document into
something awesome? This is your module then. 

This is the default for Document::Transformer to use. It expects data structures
that conform to the types defined in the L<Document::Transform::Types> module.
It implements the interface role L<Document::Transform::Role::Transformer>


