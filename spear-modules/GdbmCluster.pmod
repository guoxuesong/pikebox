#pike __REAL_VERSION__

/*ABORT ASSERT FAIL{{{*/
#define DEBUG

#define ABORT() throw(({"ERROR\n",backtrace()}))
#define assert(EXP) ((EXP)||ABORT())

#ifdef DEBUG
#define ASSERT(EXP) assert(EXP)
#endif

#define FAIL() throw(({"FAIL\n",backtrace()}))/*}}}*/

//! There are two typical usage of GdbmCluster:
//!
//! One is simplely replace Gdbm.gdbm(path) as GdbmCluster.GdbmCluster(path,n), to extand the size limit of db from 2G to n*2G.
//! GdbmCluster use n*gdbm to store data, and has a compatible interface. Just use it as a Gdbm.gdbm.
//!
//! Another is use GdbmCluster.GdbmCluster(path,n,thread_pool_size) make GdbmCluster with a thead pool.
//! And use mydb["key"]=lambda(){...}
//! The lambda function can take a long time to run and must return a string to store data.
//! The lambda function will be hash to the thread pool.
//! Then sync() should be used to wait all the functions return.
//! Using Spear S{} block in lambda, with Cross.HOSTS set to map the functions to several machines

class GdbmCluster{
	class Unit{
		array a=({});
		int size;
	};
	array units=({});
	array thread_pool=({});
	//array thread_queues=({});
	Thread.Queue inq=Thread.Queue();
	//function(string,string:void) set_cb;
	//Thread.Queue outq=Thread.Queue();
	mapping keys_in_queue=([]);
	private void thread_func(Thread.Queue q)/*{{{*/
	{
		while(1){
			[string k,function f]=q.read();
			string res;
			mixed err=catch{
				res=f();
			};
			if(err){
				master()->handle_error(err);
			}
			object lock=mutex->lock();
			keys_in_queue[k]--;
			if(keys_in_queue[k]==0)
				m_delete(keys_in_queue,k);
			set(k,res);
			destruct(lock);
			//outq->write(({k,res}));
		}
	}/*}}}*/
	function key2thread;
	Thread.Mutex mutex=Thread.Mutex();
	constant DEFAULT_THREAD_POOL_SIZE=1;
	void create(string path,int _size,int|void thread_pool_size,function(string:int)|void _key2thread/*,function(string,string:void)|void _set_cb*/)
	{
		//set_cb=_set_cb;
		key2thread=_key2thread;
		for(int i=0;i<(thread_pool_size||DEFAULT_THREAD_POOL_SIZE);i++){
			//thread_queues+=({Thread.Queue()});
			thread_pool+=({Thread.Thread(thread_func,/*thread_queues[-1]*/ inq)});
		}
		add_storage(path,_size);
	}
	void add_storage(string path,int _size)
	{
		object lock=mutex->lock();
		object unit=Unit();
		units+=({unit});
		unit->size=_size;
		mkdir(path);
		array a=get_dir(path);
		if(sizeof(a)!=0)
			ASSERT(sizeof(a)==unit->size);
		for(int i=0;i<unit->size;i++){
			unit->a+=({Gdbm.gdbm(combine_path(path,sprintf("%d.db",i)))});
		}
		destruct(lock);
	}
	private string set(string key,string data)
	{
		if(data){
			object unit=units[-1];
			int k=hash(key)%unit->size;
			return unit->a[k][key]=data;
		}else{
			delete(key);
		}
	}
//	int in_check_outq;
//	private string check_outq()
//	{
//
//		if(!in_check_outq){
//			in_check_outq++;
//			[string k,string d]=outq->read();
//			ASSERT(keys_in_queue[k]>0);
//			keys_in_queue[k]--;
//			if(keys_in_queue[k]==0)
//				m_delete(keys_in_queue,k);
//			set(k,d);
//			/*if(set_cb){
//				mixed err=catch{
//					set_cb(k,d);
//				};
//				if(err){
//					master()->handle_error(err);
//					ABORT();
//				}
//			}*/
//			in_check_outq--;
//			return k;
//		}
//	}
	private void put_into_queue(string key,function f)
	{
		//ASSERT(init_thread==Thread.this_thread()->id_number);
		/*while(outq->size()&&!in_check_outq){
			check_outq();
		}*/
		inq->write(({key,f}));
		/*
		int n=-1;
		if(key2thread){
			catch{
			n=key2thread(key);
			};
		}
		if(n==-1){
			int min_size=thread_queues[0]->size();
			object min_q=thread_queues[0];
			foreach(thread_queues,object q){
				if(q->size()<min_size){
					min_size=q->size();
					min_q=q;
				}
			}
			min_q->write(({key,f}));
		}else{
			thread_queues[n%sizeof(thread_queues)]->write(({key,f}));
		}*/
	}
	string|function `[](string key) //only return string indeed, pike check the type, must be string|function
		//return the old data, we don't want locked ourself if there are two same rssitem found
	{
		/*while(keys_in_queue[key]){
			ASSERT(!in_check_outq);
			check_outq();
		}*/
		//ASSERT(!keys_in_queue[key]);
		object lock=mutex->lock();
		foreach(units,object unit){
			int k=hash(key)%unit->size;
			if(unit->a[k][key])
				return unit->a[k][key];
		}
	}
	string|function `[]=(string key,string|function data)
	{
		object lock=mutex->lock();
		ASSERT(data!=0);
		if(stringp(data))
			return set(key,data);
		keys_in_queue[key]++;
		put_into_queue(key,data);
		return data;
	}
	int(0..1) delete(string key)
	{
		object lock=mutex->lock();
		int res;
		foreach(units,object unit){
			int k=hash(key)%unit->size;
			res=unit->a[k]->delete(key);
			if(res)
				return res;
		}
	}
	int is_synced()
	{
		object lock=mutex->lock();
		return sizeof(keys_in_queue)==0;
	}
//	string wait()
//	{
//		object lock=mutex->lock();
//		//write("sync ...\n");
//		if(!is_synced()){
//			//werror("keys_in_queue=%d outq=%d\n",sizeof(keys_in_queue),outq->size());
//			/*foreach(thread_queues,object q){
//				werror("%d ",q->size());
//			}*/
//			//werror("\n");
//			if(sizeof(keys_in_queue)==0)
//				ASSERT(outq->size()==0);
//			ASSERT(!in_check_outq);
//			return check_outq();
//		}
//		//write("sync done\n");
//	}
	void sync()
	{
		while(!is_synced())
			sleep(0.1);
	}
	void close()
	{
		object lock=mutex->lock();
		sync();
		foreach(units,object unit){
			foreach(unit->a,object db){
				db->close();
			}
			unit->a=({});
		}
	}
	void destroy()/*{{{*/
	{
		close();
	}/*}}}*/
	string myfirstkey(int uid,int vid)/*{{{*/
	{
		for(int i=uid;i<sizeof(units);i++){
			object unit=units[i];
			for(int j=vid;j<sizeof(unit->a);j++){
				object db=unit->a[j];
				if(db->firstkey())
					return db->firstkey();
			}
		}
	}/*}}}*/
	string firstkey()/*{{{*/
	{
		object lock=mutex->lock();
		return myfirstkey(0,0);
	}/*}}}*/
	string nextkey(string key)/*{{{*/
	{
		object lock=mutex->lock();
		string res;
		foreach(units;int i;object unit){
			int k=hash(key)%unit->size;
			int uid=i;
			int kid=k;
			if(unit->a[k][key]){
				res=unit->a[k]->nextkey(key);
				if(res==0){
					if(k+1<sizeof(unit->a)){
						kid=k+1;
						res=myfirstkey(uid,kid);
						//res=unit->a[k+1]->firstkey();
						//write("same unit\n");
					}else{
						if(i+1<sizeof(units)){
							uid=i+1;
							kid=0;
							res=myfirstkey(uid,kid);
							//res=units[i+1]->a[0]->firstkey();
							//write("next unit\n");
						}else{
							//write("over\n");
						}
					}
				}else{
					//write("got\n");
				}
			}
			/*
				(k+1<sizeof(unit->a)?(unit->a[(kid=k+1)]->firstkey()):
				 i+1<sizeof(units)?units[(uid=i+1)]->a[(kid=0)]->firstkey():0); //XXX 如果为空，返回下一个的firstkey
				 */
			//write("%d[%d]/%d/%s\n",uid,sizeof(units),kid,key);
			if(res)
				return res;
		}
	}/*}}}*/
}

#if 0
array clusters_wait_multi(array clusters)/*{{{*/
{
	array res=({});
	int has_more;
	foreach(clusters,GdbmCluster c){
		if(!c->is_synced){
			has_more=1;
			if(sizeof(c->outq)){
				res+=({c});
			}
		}
	}
	if(has_more)
		return res;
}/*}}}*/

void cluster_chain(GdbmCluster first,function(string,string:function) f,GdbmCluster next,mixed ... more)/*{{{*/
{
	mapping m=([]);
	GdbmCluster p=first;
	do{
		m[p]=({f,next});
		p=next;
		f=more[0];
		next=more[1];
		more=more[2..];
	}while(sizeof(more));
	array a=clusters_wait_multi(indices(m));
	while(a){
		if(sizeof(a)){
			foreach(a,GdbmCluster db){
				string k=db->wait();
				m[db][1]=m[db][0](k,db[k]);
			}
		}else{
			sleep(1);
		}
	}
}/*}}}*/
#endif

