class Matrix(mapping(string:array) dims){
	constant BEGIN=0;
	constant END=1;
	constant STEP=2;
	private array keys;
	mapping begin()/*{{{*/
	{
		keys=keys||sort(indices(dims));
		mapping m=([]);
		foreach(keys,string key){
			m[key]=dims[key][BEGIN];
		}
		return m;
	}/*}}}*/
	void advance(mapping m)/*{{{*/
	{
		keys=keys||sort(indices(dims));
		int i=0;
		while(i<sizeof(keys)){
			string key=keys[i];
			if(m[key]+dims[key][STEP]<=dims[key][END]){
				m[key]+=dims[key][STEP];
				break;
			}else{
				m[key]=dims[key][BEGIN];
				i++;
			}
		}
		if(i==sizeof(keys)){
			m["_eof_"]=1;
		}
	}/*}}}*/
	mixed _foreach(function f)/*{{{*/
	{
		mixed res=([]);
		for(mapping m=begin();!m->_eof_;advance(m)){
			mixed val=f(m);
			if(sizeof(keys)>1){
				mapping p=res;
				foreach(keys[..<1],string key){
					p[m[key]]=p[m[key]]||([]);
					p=p[m[key]];
				}
				p[m[keys[-1]]]=val;
			}else{
				res=val;
			}
		}
		return res;
	}/*}}}*/
	/*private void walk(mapping data,array a,int n,function feed)
	{
		if(n>1){
			foreach(data;mixed key,mixed val){
				if(mappingp(val)){
					walk(val,a+({key}),n-1,feed);
				}
			}
		}else{
			foreach(data;mixed key,mixed val){
				if(val){
					feed(a+({key}),val);
				}
			}
		}
	}
	array _sort(mixed index)
	{
		array keys=({});
		array vals=({});
		walk(res,({}),1+sizeof(keys),lambda(array key,array val){
				keys+=({({key,val})});
				vals+=({val[index]});
				});
		sort(vals,keys);
		return keys;
	}*/

#if 0
	array split(mapping data,array kk)/*{{{*/
	{
		mapping subdims=([]);
		array value_dims=({});
		foreach(kk,string k){
			if(dim[k]){
				subdims[k]=dim[k];
			}else{
				value_dims+=({k});
			}
		}
		object m=Matrix(subdims);
		m->_foreach(lambda(mapping mm){
				});
	}/*}}}*/
#endif

	mixed find_data(mapping data,mapping m)/*{{{*/
	{
		mixed e=catch{
			mixed p=data;
			foreach(keys,string key){
				p=p[m[key]];
			}
			return p;
		};
		if(e){
			werror("data=%O m=%O keys=%O\n",data,m,keys);
			throw(e);
		}
	}/*}}}*/

	array split(mapping data,array kk)/*{{{*/
	{
		werror("split %O %O\n",data,kk);
		mapping vkey2data=([]);
		_foreach(lambda(mapping m){
				array key=filter(kk,stringp);
				array val=({});
				mixed d=find_data(data,m);
				foreach(kk,string|array k){
					if(stringp(k)){
						val+=({m[k]});
					}else{
						mixed p=d;
						foreach(k,mixed idx){
							p=p[idx];
						}
						val+=({p});
					}
				}
				string vkey=encode_value_canonic(val);
				if(sizeof(keys-kk)>0){
					vkey2data[vkey]=vkey2data[vkey]||([]);
					mapping p=vkey2data[vkey];
					foreach((keys-kk)[..<1],string key){
						p[m[key]]=p[m[key]]||([]);
						p=p[m[key]];
					}
					p[m[(keys-kk)[-1]]]=d;
				}else{
					vkey2data[vkey]=d;
				}
				});
		array keys=map(indices(vkey2data),decode_value);
		array values=values(vkey2data);
		sort(keys,values);
		//return values;
		return ({map(keys,Function.curry(mkmapping)(kk)),values});
	}/*}}}*/

	string print_any(mapping info,mapping data,array format)/*{{{*/
	{
		if(data==0) return 0;
		string res;
		mapping m=begin();
		mixed ob=find_data(data,m);
		array args=({format[0]});
		for(int i=1;i<sizeof(format);i++){
			if(stringp(format[i])){
				args+=({m[format[i]]||info[format[i]]});
			}else if(arrayp(format[i])){
				mixed p=ob;
				foreach(format[i],mixed key){
					if(!functionp(key)){
						p=p[key];
					}else{
						p=key(p);
					}
				}
				args+=({p});
			}else if(functionp(format[i])){
				args+=({format[i](info)});
			}
		}
		res=sprintf(@args);
		return res;
	}/*}}}*/

	private string auto_space(string|void d,string space)/*{{{*/
	{
		if(d&&d!=""){
			return d+space;
		}
		return "";
	}/*}}}*/
	string print_view(object view,mapping info,mapping data)/*{{{*/
	{
		if(data==0) return 0;
		string res="";
		[array splited_info,array splited_data]=split(data,view->key);
		werror("splited_data=%O\n",splited_data);
		werror("new dims=%O\n",dims-view->key);
		object m=Matrix(dims-view->key);
		string space=" ";
		if(view->type=="COL")
			space="\n";
		res+=auto_space(print_any(info,data,view->print_title),space);
		if(view->type!="DATA"){
			foreach(splited_data;int i;mapping data1){
				mapping info1=splited_info[i];
				res+=auto_space(m->print_any(info+info1,data1,view->print_key),space);
				foreach(view->data_list,object subview){
					res+=auto_space(m->print_view(subview,info+info1,data1),space);
				}
			}
		}
		return res;
	}/*}}}*/

	mapping group(mapping res,mapping data,array keys,int valuecol,mixed defaultvalue){/*{{{*/
		_foreach(lambda(mapping m){
				array a=find_data(data,m);
				array values=map(keys,lambda(string|int key){
					if(stringp(key)){
						return m[key];
					}else{
						return a[key];
					}
					});
				object key=CompareArray.CompareArray(values);
				int newitem_flag;

				if(res[key]==0){
					newitem_flag=1;
				}
				res[key]=res[key]||([]);
				res[key]->sum=res[key]->sum||defaultvalue;
				res[key]->sum+=a[valuecol];
				if(intp(defaultvalue)||floatp(defaultvalue)){
					if(newitem_flag){
						res[key]->minval=a[valuecol];
						res[key]->maxval=a[valuecol];
					}else{
						res[key]->minval=min(res[key]->minval,a[valuecol]);
						res[key]->maxval=max(res[key]->maxval,a[valuecol]);
					}
				}
				res[key]->count++;
				});
		return res;
	}/*}}}*/
}

//tex:将View的用法说明如下

//tex:\begin{verbatim}
//tex:void View::create(string type,array print_title,array|void key,array|void print_key,mixed|void ... args);
//tex:\end{verbatim}

//tex:View的定义是递归的，View::create的前四个参数定义了这个View，后续的参数定义子View。

//tex:\begin{enumerate}
//tex:	\item type : COL 或者 ROW 或者 DATA
//tex:	\item print\_title : 经过 格式数组的处理规则 处理以后传给 sprintf : sprintf(@print\_titile) 下详
//tex:	\item key : 这一层 View 处理的维度名称列表，是所有维度的一个子集
//tex:	\item print\_key : 类似 print\_title
//tex:\end{enumerate}

//tex:典型用法是：

//tex:\begin{verbatim}
//tex:string out=matrix->print_view(
//tex:	View("COL",({"list of a"}),({"a"}),({"a=%d","a"}),
//tex:		({"ROW",({"data: "}),
//tex:		 ({"b"}),({"b=%d","b"}),
//tex:		 ({"DATA", ({"%s",({0})})
//tex:		  })})
//tex:		),info,data);
//tex:\end{verbatim}

//tex:其中 matrix 是一个 Matrix.Matrix ， data 是从 matrix->\_foreach 返回的数据。这个例子中假设 matrix 有两个维度 a,b 。

//tex:这个 View 表示：在最外层要按列显示按 a 的取值分类的数据；对于每一个 a 的取值，按行显示按 b 的取值分类的数据；因为 a,b 是所有的维度，按照 a,b 取值两次分类以后得到最终的数据，这个数据就是传给 Matrix.Matrix::\_foreach 的回调函数每次调用返回的值，这个值是一个 array 。格式数组的处理规则允许我们访问这个 array 的任意项。

//tex:格式数组的处理规则

//tex:假设格式数组为 format

//tex:\begin{enumerate}
//tex:	\item format[0] 总是原样传给 sprintf
//tex:	\item 对于 k=format[n],n>0
//tex:	\item 如果 k 是字符串，将 data[k]||info[k] 传给 sprintf
//tex:	\item 如果 k 是函数，将 k(info) 的返回值传给 sprintf
//tex:	\item 如果 k 是数组，用 k 的每一项来检索 data ，即取 data[k[0]][k[1][...] 传给 sprintf
//tex:	\item 特别的，如果 k 是数组， k 的某一项是一个函数f，假设k[1]==f，把f(data[k[0]])视作检索结果，即把k[1](k[0][data][k[2]][...] 传给 sprintf
//tex:\end{enumerate}

//tex:在上述例子中，最终数据的格式数组为 ({"\%s",({0})}) ，对应于 sprintf(``\%s'',data[0]) 。

//tex:备注：在现有的例子中看来，所有的 info 都取的是 ([]) ，貌似对 info 的支持并无必要。

class View(string type,array print_title){
	array key;
	array print_key;
	array data_list=({});
	void create(array|void _key,array|void _print_key,mixed|void ... args)
	{
		key=_key||({});
		print_key=_print_key||({""});
		if(args){
			foreach(args,array line){
				data_list+=({View(@line)});
			}
		}
	}
}

void main()
{
	object m=Matrix(([
				"a":({0,10,1}),
				"b":({2,8,2}),
				]));
	mapping data=m->_foreach(lambda(mapping m){ return ({m->a+":"+m->b,(["c":"c","d":"d"])}); });

	//werror("data=%O\n",data);

	string out=m->print_view(View("COL",({""}),
					({"a"}),({"a=%d","a"}),
					({"ROW",({""}),
					 ({"b"}),({"b=%d","b"}),
					 ({"DATA", ({"%s",({0})})
					  })})
					
					),([]),data);
	werror("%s\n",out);
}
