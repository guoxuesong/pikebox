#! /bin/env pike

#if 0
class ObjectClass{
	string table;
	string idkey;
	int id_auto_increment;
}

class Property{
		array tables;
		string exp;
		string where;
		mapping args(mixed ownerid);
}

class Action{
	void `()(mixed ... args);
}

class Event{
	inherit Action;
	string table;
	string idkey;
	int id_auto_increment;
	void `()(mapping data)
	{
		if(id_auto_increment&&~zero_type(data[idkey]))
			throw(({"Data should not include auto-incremented key.\n",backtrace()}));
		if(!id_auto_increment){
			db->query("delete from "+table+" where "+idkey+"=:"+idkey+";",data&(<idkey>));
		}
		db->query("insert into "+table" ("+indices(data)*","+") values ("+map(indices(data),Function.curry(`+)(":"))*","+");",data);
	}
}
#endif

class SqlTool(string sql_url,string sql_database,string sql_user,string sql_passwd){
	Sql.Sql _db;
	mapping db2txn_level=([]);
	object idler=Time.Idler(60);
	void use(string database)/*{{{*/
	{
		db->query("use "+database+";");
		sql_database=database;
	}/*}}}*/
	Sql.Sql `db()/*{{{*/
	{
		idler(lambda(){
				int err;
				if(db2txn_level[_db]){
					err=1;
				}
				m_delete(db2txn_level,_db);
				_db=Sql.Sql(sql_url,sql_database,sql_user,sql_passwd);
				if(err){
					throw(({"Connection timeout in transaction.\n",backtrace()}));
				}
		});
		return _db;
	}/*}}}*/
	void foreach_row(string|array table,string key,int|string|mapping val,array columns,function(mapping:int) f,array|void orderby)/*{{{*/
	{
		if(arrayp(table))
			table=table*",";
		string sql="select "+columns*","+" from "+table;
		if(key&&!mappingp(val))
			sql+=" where "+key+"=:val";
		else if(key&&mappingp(val))
			sql+=" where "+key;
		if(orderby){
			array a=({});
			foreach(orderby,string s){
				if(has_prefix(s,"-")){
					a+=({s[1..]+" desc"});
				}else{
					a+=({s+" asc"});
				}
			}
			sql+=" order by "+a*",";
		}
		if(!stringp(key)&&val==0){
			val=([]);
		}else if(!mappingp(val)){
			val=(["val":val]);
		}
		sql+=";";
		werror("sql=%O val=%O\n",sql,val);
		object res=db->big_query(sql,val);
		foreach(res;int i;array a){
			if(f(mkmapping(columns,a)))
					break;
		}
	}/*}}}*/
	void txn_begin()/*{{{*/
	{
		if(db2txn_level[db]==0)
			db->query("START TRANSACTION;");
		db2txn_level[db]++;
	}/*}}}*/
	void txn_commit()/*{{{*/
	{
		if(db2txn_level[db]>0){
			db2txn_level[db]--;
			if(db2txn_level[db]==0)
				db->query("COMMIT;");
		}else{
			throw(({"Commit null transaction.\n",backtrace()}));
		}
	}/*}}}*/
	void txn_abort(mixed e)/*{{{*/
	{
		if(db2txn_level[db]>0){
			db2txn_level[db]--;
			if(db2txn_level[db]==0){
				werror("txn_abort: ROLLBACK\n");
				master()->handle_error(e);
				db->query("ROLLBACK;");
			}else{
				werror("txn_abort: PASS THROUGH\n");
				if(e)
					throw(e);
				else
					throw(({"Nested transaction aborted.\n",backtrace()}));
			}
		}else{
			werror("txn_abort: PASS THROUGH\n");
			throw(({"Abort null transaction.\n",backtrace()}));
		}
	}/*}}}*/
	int txn_level()/*{{{*/
	{
		return db2txn_level[db];
	}/*}}}*/
}

#include <args.h>
int main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	if(Usage.usage(args,"",0)){
		return 0;
	}
	HANDLE_ARGUMENTS();
}

