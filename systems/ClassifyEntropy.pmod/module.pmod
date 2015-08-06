#include <class.h>
#define CLASS_HOST "ClassifyEntropy"
class DynClass{
#include <class_imp.h>
}

class Tool{
	float ln(float x)/*{{{*/
	{
		return (log(1.0*(x))/log(2.0));
	}/*}}}*/
	int intfy(float|string x){return (int)x;}
	float floatfy(float|string x){return (float)x;}
	string stringfy(int x){return (string)x;}
}

class UniqIDStatic{/*{{{*/
	class Static{
		int sn;
	};
}/*}}}*/
class UniqID{/*{{{*/
	int id=++(STATIC(UniqIDStatic)->sn);
}/*}}}*/

class Type(int minval,int maxval){/*{{{*/
	multiset(Property) m=(<>);
	void update()/*{{{*/
	{
		maxval=Int.NATIVE_MIN;
		minval=Int.NATIVE_MAX;
		foreach(m;object p;int one){
			maxval=max(maxval,p->value);
			minval=min(minval,p->value);
		}
	}/*}}}*/
}/*}}}*/
object integer=Type(Int.NATIVE_MIN,Int.NATIVE_MAX);
object type=Type(Int.NATIVE_MIN,Int.NATIVE_MAX);//need update
object data_type=Type(0,sizeof(data_type));
array data_types=({Property,Multi,AlterType,AlterValue});

class Property(object(Type) type,int value) /*{{{*/
{
	void create()
	{
		type->m[this]=1;
	}
}/*}}}*/

array alter_chain=({});

class Multi(program|void p,array|void a){
	inherit Tool;
	private int is_type_altered(int i)/*{{{*/
	{
		foreach(alter_chain,object alter){
			if(object_program(alter)==AlterType){
				int p=search(alter->pos,i);
				if(p>=0){
					return 1;
				}
			}
		}
	}/*}}}*/
	private int is_value_altered(int i)/*{{{*/
	{
		foreach(alter_chain,object alter){
			if(object_program(alter)==AlterValue){
				int p=search(alter->pos,i);
				if(p>=0){
					return 1;
				}
			}
		}
	}/*}}}*/
	object read(object data,int size,program _p)/*{{{*/
	{
		p=_p;
		a=({});
		if(p==Property){
			array t=({});
			for(int i=0;i<size;i++){
				int found;
				foreach(alter_chain,object alter){
					if(object_program(alter)==AlterType){
						int p=search(alter->pos,i);
						if(p>=0){
							t+=({data_types[alter->a[p]->value]});
							found=1;
							break;
						}
					}
					if(object_program(alter)==AlterValue){
						int p=search(alter->pos,i);
						if(p>=0){
							t+=({alter->a[p]->type});
							found=1;
							break;
						}
					}
				}else{
					t+=({data->data[data->pos+i]});
					data->pos++;
				}
			}
			for(int i=0;i<size;i++){
				int found;
				foreach(alter_chain,object alter){
					if(object_program(alter)==AlterValue){
						int p=search(alter->pos,i);
						if(p>=0){
							a+=({alter->a[p]->value});
							found=1;
							break;
						}
					}
				}else{
					a+=({p(t[i],data->data[data->pos+i])});
					data->pos++;
				}
			}
		}else if(p==Multi){
			array t1=({});
			array t2=({});
			array t3=({});
			array t4=({});
			for(int i=0;i<size;i++){
				t1+=({data->data[data->pos+i]});
			}
			data->pos+=size;
			for(int i=0;i<size;i++){
				t2+=({data->data[data->pos+i]});
			}
			data->pos+=size;
			for(int i=0;i<size;i++){
				t3+=({p(t1[i],data->data[data->pos+i])});
			}
			data->pos+=size;
			for(int i=0;i<size;i++){
				t4+=({p(t2[i],data->data[data->pos+i])});
			}
			data->pos+=size;

			for(int i=0;i<size;i++){
				a+=p(data,t3[i],data_types[t4[i]]);
			}
		}
		return this;
	}/*}}}*/
	object(Data) write()/*{{{*/
	{
		array meta=({Multi,Property(integer,sizeof(a)),p,0});
		array data=({});
		if(p==Property){
			foreach(a;int i;object d){
				int found;
				foreach(alter_chain,object alter){
					if(object_program(alter)){
						int p=search(alter->pos,i);
						if(p>=0){
							found=1;
						}
					}
				}
				if(!found)
					data+=({d->type});
			}
			foreach(a;int i;object d){
				int found;
				foreach(alter_chain,object alter){
					if(object_program(alter)==AlterValue){
						int p=search(alter->pos,i);
						if(p>=0){
							found=1;
						}
					}
				}
				if(!found)
					data+=({d});
			}
		}else if(p==Multi){
			foreach(a,object d){
				data+=({integer})
			}
			foreach(a,object d){
				data+=({integer})
			}
			foreach(a,object d){
				data+=({sizeof(d->a)})
			}
			foreach(a,object d){
				data+=({search(data_types,d->p)})
			}
		}

		return Data(meta,data);
	}/*}}}*/
	void walk(function f)/*{{{*/
	{
		foreach(a,object ob){
			if(ob->p==Property){
				if(f(ob))
					break;
			}else{
				ob->walk();
			}
		}
	}/*}}}*/
	object simple_reduce()/*{{{*/
	{
		array types;
		array values;
		walk(lambda(object atom){
				if(types==0){
					types=allocate(sizeof(atom->a));
					values=allocate(sizeof(atom->a));
				}
				foreach(atom->a;int i;object p){
					types[i]=types[i]||(<>);
					types[i][p->type]=1;
					values[i]=values[i]||(<>);
					values[i][p]=1;
				}
				});
		object res=Multi(Property,({}));
		object alter_value=AlterValue(Property,({}),({}),0);
		object alter_type=AlterType(Property,({}),({}),0);
		foreach(types;int i;multiset m){
			if(sizeof(m)==1&&sizeof(values[i])!=1){
				foreach(m,object t){
					alter_type->pos+=({i});
					alter_type->a+=({Property(type,t)}));
				}
			}
		}
		if(sizeof(alter_type->pos)){
			alter_value->target=res;
			res=alter_value;
		}
		foreach(values;int i;multiset m){
			if(sizeof(m)==1){
				foreach(m,object p){
					alter_value->pos+=({i});
					alter_value->a+=({p}));
				}
			}
		}
		if(sizeof(alter_type->pos)){
			alter_type->target=res;
			res=alter_type;
		}
		return res;
	}/*}}}*/
	object multilayer_reduce()
	{
		walk(lambda(object atom){
				foreach(atom->a;int i;object p){
					if(!is_value_altered(i)){
						
					}
				}
				});
		
	}
}
class AlterBase(program|void p,array|void pos,array|void a,object|void target){
	inherit Tool;
	object read(object data,int size,program _p)/*{{{*/
	{
		p=_p;
		a=({});
		for(int i=0;i<size;i++){
			pos+=({p(data->data[data->pos+i*4+0],data->data[data->pos+i*4+1])});
			a+=({p(data->data[data->pos+i*4+2],data->data[data->pos+i*4+3])});
		}
		data->pos+=size*4;
		alter_chain+=({this});
		object ob=data->read_object();
		alter_chain=alter_chain[..<1];
		/*ob->walk(lambda(object multi){
				for(int i=0;i<sizeof(pos);i++){
					multi->a=multi->a[..pos[i]->value-1]+({a[i]})+multi->a[pos[i]->value..];
				}
				});*/
		return ob;
	}/*}}}*/
	object(Data) write()/*{{{*/
	{
		ASSERT(sizeof(pos)==sizeof(a));
		array meta=({Alter,Property(integer,sizeof(a)),p,0});
		array data=({});
		foreach(a;int i;object d){
			data+=({pos[i]->type,pos[i]});
			data+=({d->type,d});
		}
		alter_chain+=({this});
		object res=Data(meta,data)+target->write();
		alter_chain=alter_chain[..<1];
		return res;
	}/*}}}*/
}

class AlterType{ inherit AlterBase; }
class AlterValue{ inherit AlterBase; }

class Image(object image){/*{{{*/
	object(Data) output()
	{
		object root_type=Type(0,Int.NATIVE_MAX);
		object color_type=Type(0,255);
		object width_type=Type(0,image->xsize());
		object height_type=Type(0,image->ysize());
		array a=({});
		for(int i=0;i<image->xsize();i++){
			for(int j=0;j<image->ysize();j++){
				[int r,int g,int b]=image->getpixel(i,j);
				a+=({Multi(Property,({
							Property(color_type,r),
							Property(color_type,g),
							Property(color_type,b),
							Property(width_type,i),
							Property(height_type,j),
							}))});
			}
		}
		return Multi(root_type,([]),a)->output();
	}
}/*}}}*/

class Data(array meta,array data){
	inherit Tool;
	int pos;
	int mpos;
	void reset()/*{{{*/
	{
		pos=mpos=0;
	}/*}}}*/
	object `+(object rhd)/*{{{*/
	{
		return Data(meta+rhd->meta,data+rhd->data);
	}/*}}}*/
	private float entropy_of(object d)/*{{{*/
	{
		if(object_program(d)==Type){
			return ln(Int.NATIVE_MAX*1.0);
		}else{
			return ln(d->type->maxval-d->type->minval+1.0);
		}
	}/*}}}*/
	float query_entropy()/*{{{*/
	{
		type->update();
		array a=map(data,entropy_of);
		return predef::`+(ln(sizeof(Array.uniq(meta))*1.0),@a);
	}/*}}}*/
	object read_object()/*{{{*/
	{
		array code;
		int p=search(meta,0,mpos);
		if(p>=0){
			code=meta[mpos..p-1];
			mpos=p+1;
		}
		return code[0](this,@code[1..]);
	}/*}}}*/
}

class ClassifyEntropyMode{
	class Interface{
	}
	class Default{
	}
}

class ClassifyEntropy{
	inherit ClassifyEntropyMode.Interface;
}

object default_program=CLASS(ClassifyEntropy,ClassifyEntropyMode.Default);

#include <args.h>
int main(int argc,array argv)
{
	if(Usage.usage(argv,"",0)){
		werror(
#" -h,	--help		Show this help.
");
		return 0;

	}
	mapping args=Arg.parse(argv);
	array rest=args[Arg.REST];
}

