MIXIN Session{

object load_player(string user) { }
int save_player(string user,object ob) { }
int delete_player(string user) { }

}

MIXIN Player{

object load_player(string user) { }
int save_player(string user,object ob) { }
int delete_player(string user) { }

}

