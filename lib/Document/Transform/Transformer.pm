package Document::Transform::Transformer;
use Moose;
use namespace::autoclean;

use Data::DPath('dpathr');
use Document::Transform::Types(':all');
use MooseX::Params::Validate;

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

__END__;
