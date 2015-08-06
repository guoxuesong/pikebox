multiset _tags=(<>);
void add_tags(multiset m)
{
	_tags|=m;
}

void delete_tags(multiset m)
{
	_tags-=m;
}
