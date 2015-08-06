class gdbm{
	object db;
	void create(string file,string|void mode)/*{{{*/
	{
		if(mode)
			db=Gdbm.gdbm(file,mode);
		else
			db=Gdbm.gdbm(file);
	}/*}}}*/
	string `[](string key){return fetch(key);} 
	string `[]=(string key,string data){if(store(key,data)){return data;}} 
	void close() {db->close();}
	string firstkey(){
		string key=db->firstkey();
		if(sizeof(key)&&key[-1]=='0'){
			array m=low_fetch(key[..<1]);
			int i;
			for(i=0;m[i]==0;i++)
				;
			return sprintf("%s%d",key[..<1],i);
		}else{
			return key;
		}
	};
	string nextkey(string key) 
	{
		if(sizeof(key)&&key[-1]>='0'&&key[-1]<='9'){
			array m=low_fetch(key[..<1]);
			int p=key[-1]-'0';
			p++;
			while(m[p]==0&&p<sizeof(m))
				p++;
			
			if(p==sizeof(m)){
				key=db->nextkey(key[..<1]+"0");
				if(key&&sizeof(key)&&key[-1]>='0'&&key[-1]<='9'){
					array m=low_fetch(key[..<1]);
					int i;
					for(i=0;m[i]==0;i++)
						;
					return sprintf("%s%d",key[..<1],i);
				}else{
					return key;
				}
			}else{
				return sprintf("%s%d",key[..<1],p);
			}
		}
	}
	int reorganize() {return db->reorganize();}
	void sync() {db->sync();}

	private object cache=CacheLite.Cache(5000);
	private array low_fetch(string prefix)/*{{{*/
	{
		return cache(({prefix}),lambda(){
				string data=db->fetch(prefix+"0");
				if(data)
					return decode_value(data);
				else
					return allocate(10,0);
					}
				);
	}/*}}}*/
	private int low_store(string prefix,array m)/*{{{*/
	{
		return db->store(prefix+"0",encode_value(m));
	}/*}}}*/
	int(0..1) delete(string key){
		if(sizeof(key)&&key[-1]>='0'&&key[-1]<='9'){
			array m=low_fetch(key[..<1]);
			m[key[-1]-'0']=0;
			if(sizeof(filter(m,`!=,0))){
				return low_store(key[..<1],m);
			}else{
				return db->delete(key[..<1]);
			}
		}else{
			return db->delete(key);
		}
	}
	string fetch(string key){
		if(sizeof(key)&&key[-1]>='0'&&key[-1]<='9'){
			array m=low_fetch(key[..<1]);
			return m[key[-1]-'0'];
		}else{
			return db->fetch(key);
		}
	}
	int store(string key,string data){
		if(sizeof(key)&&key[-1]>='0'&&key[-1]<='9'){
			array m=low_fetch(key[..<1]);
			m[key[-1]-'0']=data;
			return low_store(key[..<1],m);

		}else{
			return db->store(key,data);
		}
	}
}

int main(int argc,array argv)
{
	object db=gdbm("test.db");
	for(int i=0;i<10000;i++){
		db[(string)i]=(string)i;
	}
	for(string key=db->firstkey();key;key=db->nextkey(key)){
		if(key!=db[key])
			write("%s %s\n",key,db[key]);
	}
}
