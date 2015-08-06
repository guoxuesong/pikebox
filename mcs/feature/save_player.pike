MIXIN Session{
private object users_db=LOAD_GDBMD->load_gdbm("var/users.db");
extern program player_class;

object load_player(string user)/*{{{*/
{
	string data=users_db[user];
	if(data&&sizeof(data)){
		object res=player_class(data);
		res->name=user;
		return res;
	}
}/*}}}*/
int save_player(string user,object ob)/*{{{*/
{
	string data=ob->save();
	users_db[user]=data;
}/*}}}*/
int delete_player(string user)/*{{{*/
{
	users_db->delete(user);
}/*}}}*/

}
MIXIN Player{
private object users_db=LOAD_GDBMD->load_gdbm("var/users.db");

object load_player(string user)/*{{{*/
{
	return THIS_SESSIOND->this_session()->load_player(user);
}/*}}}*/
int save_player(string user,object ob)/*{{{*/
{
	return THIS_SESSIOND->this_session()->save_player(user,ob);
}/*}}}*/
int delete_player(string user)/*{{{*/
{
	return THIS_SESSIOND->this_session()->delete_player(user);
}/*}}}*/

}
