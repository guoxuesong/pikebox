MIXIN TypeItem{
	/*
	REGISTER(handle_change);
	private void handle_change(string k)
	{
		all_constants()["COMMON_DATAD"]->update_common_item(this,k);
	}
	*/
	REGISTER(handle_remove);
	private void handle_remove()
	{
		werror("handle_remove\n");
		if(all_constants()["COMMON_DATAD"])
			all_constants()["COMMON_DATAD"]->delete_common_item(this);
	}
}
