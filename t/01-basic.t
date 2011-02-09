use Test::More;
use warnings;
use strict;

use JSON;
use MongoDB;
use IO::All;
use Try::Tiny;
use Document::Transform;
use Document::Transform::Types(':all');
use Document::Transform::Backend::MongoDB;
use FindBin('$Bin');

my $HOST = $ENV{MONGOD} || "localhost";
try
{
    my $con = MongoDB::Connection->new( host => $HOST );
    my $json = JSON->new->utf8(1);
    my $transforms = $json->decode
    (
        scalar(io("$Bin/data/transforms.js")->slurp)
    );

    my $documents = $json->decode
    (
        scalar(io("$Bin/data/documents.js")->slurp)
    );
    
    my $db = $con->DocumentTransformTest;
    my $trans = $db->transforms;
    my $docs = $db->documents;
    $db->drop();
    $trans->batch_insert($transforms, {safe => 1});
    $docs->batch_insert($documents, {safe => 1});

} 
catch
{
    plan skip_all => $_ if $_;
};

my $backend = Document::Transform::Backend::MongoDB->new
(
    host => $HOST,
    database_name => 'DocumentTransformTest',
    document_collection => 'documents',
    transform_collection => 'transforms'
);

isa_ok($backend, 'Document::Transform::Backend::MongoDB', 'Backend is the right class');
ok($backend->does('Document::Transform::Role::Backend'), 'Implements the backend interface');
can_ok($backend, qw/fetch_transform fetch_document store_transform store_document/);

my $transform = $backend->fetch_transform('YTREWQ1');
use Data::Dumper;
ok(is_Transform($transform), 'We got back an actual transform');
my $document = $backend->fetch_document('QWERTY1');
ok(is_Document($document), 'We got back an actual document');

$transform->{operations}[0]{value} = 'ONE1';

try
{
    $backend->store_transform($transform, 1); #synchronous store
}
catch
{
    fail('Storing a transformation failed: ' . $_);
};

$document->{foo} = 'bar1';

try
{
    $backend->store_document($document, 1); #synchronous store
}
catch
{
    fail('Storing a transformation failed: ' . $_);
};

my $source = Document::Transform->new(backend => $backend);
my $altered = $source->fetch('YTREWQ1');

my $altered_check =
{
    _id => $altered->{_id},
    document_id => 'QWERTY1',
    foo => 'BAR',
    yarg => [ 'ONE1', 'two', 'three'],
    blarg => 'sock puppets rock',
    qwak => { farg => { yarp => 1, narp => 0 } }    
};

is_deeply($altered, $altered_check, 'The altered document is complete and correct');

done_testing();
