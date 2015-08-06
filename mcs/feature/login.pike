#define DEBUG/*{{{*/

#define ABORT() throw(({"ERROR\n",backtrace()}))
#define assert(EXP) ((EXP)||ABORT())

#ifdef DEBUG
#define ASSERT(EXP) assert(EXP)
#endif/*}}}*/
//string post_login_cmd;
//string post_logout_cmd;
MIXIN Session{
	extern program player_class;
	extern object load_player(string user);
	extern int save_player(string user,object ob);
	extern int delete_player(string user);
	extern object this_player();
	//extern object this_session();
	extern mapping players;
	extern int command(string cmd,array args);

	//private mapping players=PLAYERS;

	string curr_user=0;
	string passwd_public=0;
	/*
	void set_post_login_cmd(string cmd) 
	{
		post_login_cmd=cmd;
		werror("post_login_cmd=%O\n",post_login_cmd);
	}
	void set_post_logout_cmd(string cmd) 
	{
		post_logout_cmd=cmd;
		werror("post_logout_cmd=%O\n",post_logout_cmd);
	}
	*/
	//int flag_clean_cookies=0;
	private object find_user(string user)/*{{{*/
	{
		return players[user];
	}/*}}}*/
	private object add_user(string user)/*{{{*/
	{
		ASSERT(stringp(user));
		if(players[user]==0){
			players[user]=player_class();
			players[user]->name=user;
			return players[user];
		}
	}/*}}}*/
	private object load_user(string user)/*{{{*/
	{
		object ob=load_player(user);
		if(ob!=0){
			players[user]=ob;
			return ob;
		}
	}/*}}}*/
	private int save_user(string user)/*{{{*/
	{
		if(players[user]){
			save_player(user,players[user]);
			return 0;
		}else{
			return 1;
		}
	}/*}}}*/
	PUBLIC login(string user,string passwd)/*{{{*/
	{
		//string p=String.string2hex(Crypto.MD5()->update(user+md5key)->digest())[0..7];
		string p=LOGIND->md5passwd(user);
		if((curr_user==0||has_prefix(curr_user,"user-"))&&user&&passwd==p){
			if(find_user(user)){
			}else if(load_user(user)){
				find_user(user)->login_notify();
			}else if(curr_user&&has_prefix(curr_user,"user-")&&user&&!has_prefix(user,"user-")){
				object player=this_player();
				m_delete(players,player->name);
				delete_player(player->name);
				player->name=user;
				players[user]=player;
				player->rename_notify(user);
				player->login_notify();
			}else{
				object p=add_user(user);
				ASSERT(p);
				p->login_notify();
			}
			curr_user=user;
			passwd_public=p;
			werror("login: curr_user=%O this_player()=%O\n",curr_user,this_player());
			return 0;
		}
		return 1;
	}/*}}}*/
	PUBLIC logout() /*{{{*/
	{
		if(curr_user){
			this_player()->logout_notify();
			curr_user=0; 
			passwd_public=0;

			string user=gen_uniq_id("user-");
			//string p=String.string2hex(Crypto.MD5()->update(user+md5key)->digest())[0..7];
			string p=LOGIND->md5passwd(user);
			//THIS_SESSIOND->this_session()->globald=GLOBALD;
			login(user,p);
			ASSERT(curr_user);
			//flag_clean_cookies=1;
			/*if(post_logout_cmd){
				command(post_login_cmd,({}));
			}*/
			return 0;
		}else{
			return 1;
		}
	}/*}}}*/
}

MIXIN Player{
	extern string name;
	extern string save();
	extern void load(string);
	extern void rename_notify(string,string);
	extern object load_player(string user);
	extern int save_player(string user,object ob);
	extern int delete_player(string user);
	private string init_save;
	int login_time;
	void unset_dirty()
	{
		init_save=save();
	}
	void rollback()
	{
		load(init_save);
	}
	void login_notify()/*{{{*/
	{
		unset_dirty();
		login_time=time();
	}/*}}}*/
	void logout_notify()/*{{{*/
	{
		if(init_save&&init_save!=save()){
			save_player(name,this);
			init_save=save();
		}
	}/*}}}*/
#if 0
	private void setup(int flag) { }
#endif
}

MIXIN RequestHandler{
	REGISTER(prelogin_f_login);
	REGISTER(postcmd);

	extern string login_cmd;
	extern int autologin_timeout;
	extern int session_timeout;
	extern multiset set_coockies;
	extern mapping m;
	extern string sessionid;
	extern object session;
	//extern function gen_uniq_id;
	extern function expires_date;
	extern string SESSION_ID_COOKIE;
	extern string LOGIN_COOKIE;

	private void prelogin_f_login()/*{{{*/
	{
		login_cmd=m->cookies[LOGIN_COOKIE];
		if(login_cmd){
			werror("login_cmd=%s\n",login_cmd);
		}else{
			string user=gen_uniq_id("user-");
			string p=LOGIND->md5passwd(user);
			login_cmd=sprintf("login %s %s",user,p);
		}

	}/*}}}*/

	private void postcmd()/*{{{*/
	{
		string cookie_expires=expires_date(time()+session_timeout);
		set_coockies[sprintf("%s=%s; expires=%s",SESSION_ID_COOKIE,sessionid,cookie_expires)]=1;
		if(session->curr_user==0){
			//session->flag_clean_cookies=0;
			string cookie_expires=Protocols.HTTP.Server.http_date(time()-1);
			set_coockies[sprintf("%s=%s; expires=%s",LOGIN_COOKIE,"",cookie_expires)]=1;
		}else{
			string user=session->curr_user;
			//string p=String.string2hex(Crypto.MD5()->update(user+md5key)->digest())[0..7];
			string p=LOGIND->md5passwd(user);
			string login_cmd=sprintf("login %s %s",user,p);
			string cookie_expires=expires_date(time()+autologin_timeout);
			set_coockies[sprintf("%s=%s; expires=%s",LOGIN_COOKIE,login_cmd,cookie_expires)]=1;
		}
	}/*}}}*/
	
}
DAEMON:
string md5passwd(string user)
{
	string p=String.string2hex(Crypto.MD5()->update(user+this_app()->md5key)->digest());
	return p;
}
