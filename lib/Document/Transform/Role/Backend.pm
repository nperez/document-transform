package Document::Transform::Role::Backend;
use Moose::Role;
use namespace::autoclean;

requires qw/fetch_transform fetch_document store_transform store_document/;

1;
__END__
