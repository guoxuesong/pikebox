#define DEBUG
#include <class.h>
#define CLASS_HOST "EntropyReduceOld1"
class DynClass{
#include <class_imp.h>
}

#include <assert.h>

//#define PROFILING
#include <profiling.h>

#define DUMP_ID
#define DUMP_PIXEL
//#define DUMP_PLANE

#define CACHESIZE 50000

#define OLDMERGE
//#define COMPAREARRAY_ENTROPY
//#define USING_COPY_OFFSET
#define DXDY_PRECISION_USING_PIXELNODE

class Tool{/*{{{*/
	array cellgroup_mask(object pixel_relations,multiset ids)/*{{{*/
	{
		array mask;
		foreach(ids;int id;int one)
		{
			array a=pixel_relations->query_mask(id);
			if(mask==0){
				mask=a;
			}else{
				for(int i=0;i<max(sizeof(mask),sizeof(a));i++){
					mask[i]=mask[i]|a[i];
				}
			}
		}
		return mask;
	}/*}}}*/
array cellgroup_count(object pixel_relations,multiset ids)/*{{{*/
{
	array mask=cellgroup_mask(pixel_relations,ids);
	return map(mask,.ImageInteger.mask_count);
}/*}}}*/
#if 0
					float boson_noempty_classify_entropy(int inst_count,int class_count)/*{{{*/
					{
						return Choose.ln_c(inst_count-1,class_count-1);
					};/*}}}*/
					float boson_classify_entropy(int inst_count,int class_count)/*{{{*/
					{
						return Math.log2(Choose.boson_classify(inst_count,class_count)*1.0);
						//return min(Math.log2(class_count*1.0)*inst_count,Math.log2(inst_count*1.0)*class_count);
					};/*}}}*/
					float fermion_classify_entropy(int inst_count,int class_count)/*{{{*/
					{
						return Math.log2(Choose.fermion_classify(inst_count,class_count)*1.0);
					};/*}}}*/
#endif
}/*}}}*/

/* 抽象类型定义 开始 */
class DynamicRange(array minval,array maxval,array avgval) 
{ 
	inherit Save.Save; 
	float atom_entropy()/*{{{*/
	{
		array t=maxval[*]-minval[*];
		t=map(t,max,0.0);
		t=map(t,`+,1.0);
		t=map(t,Math.log2);
		return `+(0.0,@t);
	}/*}}}*/
}
class PropertyData{/*{{{*/
	string key;
	int weight=1;
	object set_weight(int n){weight=n;return this;}
	float cost(){return 0.0;}
	object set_key(string k){key=k;return this;}
	DynamicRange dynamic_range(RelationMap r,multiset ids);
}/*}}}*/
class DynamicRangeEntropyInfo(int count, array minval,array maxval,array avgval,float cost,float weight)
{ 
	array dxval,dyval;
	int multer=1;
	inherit Tool;
	inherit Save.Save;
	object add(DynamicRangeEntropyInfo rhd)/*{{{*/
	{
		if(cost!=rhd->cost)
			throw(({"cost not match.\n",backtrace()}));
		array res_minval=min(minval[*],rhd->minval[*]);
		array res_maxval=max(maxval[*],rhd->maxval[*]);
		return DynamicRangeEntropyInfo(//`+(@map(map(res_maxval[*]-res_minval[*],`+,1.0),Math.log2)),
				count+rhd->count,
				res_minval,
				res_maxval,
				map(map(avgval,`*,count)[*]+map(rhd->avgval,`*,rhd->count)[*],`/,count+rhd->count),
				cost,
				weight,
				);
	}/*}}}*/
	array valscount()/*{{{*/
	{
		return map(maxval[*]-minval[*],`+,1);
	}/*}}}*/
	int valcount()/*{{{*/
	{
		return `*(1,@map(maxval[*]-minval[*],`+,1));
	}/*}}}*/
	int valncount(int n)/*{{{*/
	{
		return maxval[n]-minval[n]+1;
	}/*}}}*/
	float explan_power()/*{{{*/
	{
		if(multer==1){
			//return -(z*count+cost);
			int vc=valcount();
			if(vc==0||count==0)
				return -cost;
			//return -(min(vc*Math.log2(count*1.0),Math.log2(vc*1.0)*count)*weight+cost);
			return -(Math.log2(vc*1.0)*count*weight+cost);//需要还原x,y，无法使用分类熵
		}else{
			float res=0.0;
			if(count==0)
				return -cost;
			for(int i=0;i<sizeof(maxval);i++){
				int vc=valncount(i);
				if(vc){
					res+=Math.log2((vc-1)*1.0/multer+1);
				}
			}
			return -(res*count*weight+cost);
		}

	}/*}}}*/
}
#if 0
class ClassifyEntropyInfo(array(mapping) a)
{
	private mapping classify(array a,array b,array r)/*{{{*/
	{
		ASSERT(sizeof(a)==sizeof(b));
		ASSERT(sizeof(a)==sizeof(r));
		if(sizeof(a)){
			mapping m=a[0];
			array vals=values(m);
			array m_splited=map(vals,Function.curry(filter)(m,`==));
			array res=({});
			foreach(m_splited,mapping mm){
				array aa=map(a,`&,mm);
				res+=({classify(aa,b,r)});
			}
			int mincount;
			int maxcount;
			float htail;

			foreach(res,mapping info){
				maxcount=max(maxcount,info->count);
				mincount=min(mincount,info->count);
				htail=max(htail,info->h);
			}

			int count;
			if(sizeof(a)>1)
				count=sizeof(vals)*sizeof(values(a[1]));
			else
				count=sizeof(m);

			int valcount=max(@vals)-min(@vals)+1;

			float h1=Math.log2(0.0+count)+count*Math.log2(0.0+valcount);
			float h2=Math.log2(0.0+valcount)+valcount*Math.log2(0.0+count);
			float h3=Math.log2(0.0+valcount)+Math.log2(0.0+count)+valcount*Math.log2(0.0+maxcount+1);
			float h4=Math.log2(0.0+valcount)+Math.log2(0.0+count)+Math.log2(0.0+count-mincount+1)+valcount*Math.log2(0.0+maxcount-mincount+1);

			float h=Math.log2(4.0)+min(h1,h2,h3,h4)+htail;

			return (["h":h,"count":valcount]);
		}
	}/*}}}*/
	float explan_power()/*{{{*/
	{
		float res=Math.inf;
		Foreach.foreach_p(a,sizeof(a),lambda(mixed ... a){
				mapping info=classify(a);
				res=min(res,info->h);
				});
		return -res;
	}/*}}}*/
}
#endif
class Node{/*{{{*/
	DynamicRangeEntropyInfo info;
	Node add(Node rhd);
}/*}}}*/
class RelationMap{/*{{{*/
	int size();
	int table_size();
	int add(object item);
	int find(object item);
	void remove(int pos);
	multiset query_nearby(int pos);
}/*}}}*/
/* 抽象类型定义 结束 */


/* 公用实现 开始 */
class LineSegNodeSN/*{{{*/
{
	class Static{
		int sn;
	}
}/*}}}*/
class LineSegNode(int beginpos,int endpos){/*{{{*/
	inherit Node;

	int id;

	void create()
	{
		//werror("%O",indices(STATIC(LineSegNodeSN)));
		id=++(STATIC(LineSegNodeSN)->sn);
	}

	int size()
	{
		return endpos-beginpos;
	}
	LineSegNode add(LineSegNode rhd)
	{
		if(beginpos==rhd->endpos){
			return LineSegNode(rhd->beginpos,endpos);
		}else if(endpos==rhd->beginpos){
			return LineSegNode(beginpos,rhd->endpos);
		}
	}
}/*}}}*/

class RelationListener{/*{{{*/
	void on_add(object r,int pos,object node);
	void on_remove(object r,int pos,object node);
}/*}}}*/
class ArrayRelationMap{
	inherit RelationMap;
	array a=({});
	array listeners=({});
	int size()/*{{{*/
	{
		return sizeof(filter(a,`!=,0));
	}/*}}}*/
	int find(mixed node)/*{{{*/
	{
		int res=search(a,node);
		if(res<0)
			throw(({"not found.\n",backtrace()}));
		return res;
	}/*}}}*/
	int _add(mixed node)/*{{{*/
	{
		int pos=-1;
		foreach(a;int i;object val){
			if(val==0){
				a[i]=node;
				pos=i;
				break;
			}
		}
		if(pos==-1){
			pos=sizeof(a);
			a+=({node});
		}
		return pos;
	}/*}}}*/
	void _remove(int pos)/*{{{*/
	{
		a[pos]=0;
	}/*}}}*/
	void _finish_add(int pos,mixed node)/*{{{*/
	{
		foreach(listeners,object ob){
			ob->on_add(this,pos,node);
		}
	}/*}}}*/
	void _finish_remove(int pos,mixed node)/*{{{*/
	{
		foreach(listeners,object ob){
			ob->on_remove(this,pos,node);
		}
	}/*}}}*/
	int add(mixed node)/*{{{*/
	{
		int pos=_add(node);
		_finish_add(pos,node);
		return pos;
	}/*}}}*/
	void remove(int pos)/*{{{*/
	{
		mixed node=a[pos];
		_remove(pos);
		_finish_remove(pos,node);
	}/*}}}*/
}
/* 公用实现 结束 */

class IdImageTool{
	array id2color(int id)/*{{{*/
	{
		id++;
		int r=id%255;id/=255;
		int g=id%255;id/=255;
		int b=id%255;id/=255;
		if(id!=0)
			throw(({"too large\n",backtrace()}));
		return ({r,g,b});
	}/*}}}*/
	int color2id(array color)/*{{{*/
	{
		[int r,int g,int b]=color;
		return (((b*255)+g)*255)+r-1;
	}/*}}}*/
#ifdef USING_LEVELLIMIT
	private array rangeof(int k,int i,int j,int w1,int h1)/*{{{*/
	{
		int ww=(int)(w1/pow(2.0,k));
		int hh=(int)(h1/pow(2.0,k));
		return ({ww*i,hh*j,ww*(i+1)-1,hh*(j+1)-1});
	}/*}}}*/
	void draw(object image,object cell,array color)/*{{{*/
	{
		//color=color||id2color(pos);
		//object cell=a[pos];
		foreach(cell->query_selected(),[int k,int i,int j]){
			image->box(@rangeof(k,i,j,cell->xsize(cell->levellimit),cell->ysize(cell->levellimit)),@color);
		}
	}/*}}}*/
	void drawlayer(object image,int layer,object cell,array color)/*{{{*/
	{
		foreach(cell->query_selected(),[int k,int i,int j]){
			if(k==layer){
				image->box(@rangeof(cell->levellimit,i,j,cell->xsize(cell->levellimit),cell->ysize(cell->levellimit)),@color);
			}
		}
	}/*}}}*/
#else
	void draw(object image,object cell,array color)/*{{{*/
	{
		//color=color||id2color(pos);
		//object cell=a[pos];
		foreach(cell->query_selected(),[int k,int i,int j]){
			image->setpixel(i,j,@color);
		}
	}/*}}}*/
	void drawlayer(object image,int layer,object cell,array color)/*{{{*/
	{
		foreach(cell->query_selected(),[int k,int i,int j]){
			if(k==layer){
				image->setpixel(i,j,@color);
			}
		}
	}/*}}}*/
#endif
	private void image_query_nearby_tool(object image1,object image2,int id,array|void mask,function handle_nearby,int|void keep_self)/*{{{*/
	{
		array color=id2color(id);
		object t=image1->change_color(@color,255,255,255);
		t=t*({1,1,1});
		if(mask)
			t=t->outline(mask,255,255,255,0,0,0);
		else
			t=t->outline(/*mask,*/255,255,255,0,0,0);
		[t,object t2]=.ImageInteger.mask_autocrop(t,image2);
		//array range=t->find_autocrop();
		//t=image->copy(@range)&(t->copy(@range)->change_color(1,1,1,0,0,0));
		if(!keep_self)
			t=t2&t->change_color(1,1,1,0,0,0);
		else
			t=t2&t->change_color(1,1,1,255,255,255);

		//t=t->change_color(1,1,1,0,0,0);
		//t=image2&t;
		//t=t->autocrop();
		for(int i=0;i<t->xsize();i++){
			for(int j=0;j<t->ysize();j++){
				handle_nearby(t,i,j);
				//array color=t->getpixel(i,j);
				//res[color2id(color)]=1;
			}
		}
	}/*}}}*/
	multiset image_query_nearby_pixel(object image1,object image2,int id,array|void mask)/*{{{*/
	{
		multiset res=(<>);
		image_query_nearby_tool(image1,image2,id,mask,lambda(object t,int i,int j){

				res[({i,j})]=1;
				});
		return res;
	}/*}}}*/
	multiset image_query_nearby(object image1,object image2,int id,array|void mask,int|void keep_self)/*{{{*/
	{
		multiset res=(<>);
		image_query_nearby_tool(image1,image2,id,mask,lambda(object t,int i,int j){
				array color=t->getpixel(i,j);
				res[color2id(color)]=1;
				},keep_self);
		res[-1]=0;
		return res;
	}/*}}}*/
	object id_create_mask(object image,int id)/*{{{*/
	{
		array color=id2color(id);
		object t=image->change_color(@color,255,255,255);
		t=t*({1,1,1});
		t=t*255.0;
		return t;
	}/*}}}*/
}

class IdsImageTool{
	extern array id2color(int id);
	extern int color2id(array color);
	extern object id_create_mask(object image,int id);
	array ids2color(multiset ids)/*{{{*/
	{
		array a=sort((array)ids);
		int r,g,b;
		foreach(a,int id){
			array rgb=id2color(id);
			r=(r*255)+rgb[0];
			g=(g*255)+rgb[1];
			b=(b*255)+rgb[2];
		}
		return ({r,g,b});
	}/*}}}*/
	multiset color2ids(array color)/*{{{*/
	{
		multiset res=(<>);
		[int r,int g,int b]=color;
		while(r>=0&&g>=0&&b>=0&&r+g+b!=0){
			res[color2id(({r%255,g%255,b%255}))]=1;
			r/=255;
			g/=255;
			b/=255;
		}
		res[-1]=0;
		return res;
	}/*}}}*/
	object ids_create_mask(object image_integer,int id)/*{{{*/
	{
		object res;
		foreach(image_integer->a,object image){
			if(!objectp(res))
				res=id_create_mask(image,id);
			else
				res=res|id_create_mask(image,id);
		}
		return res;
	}/*}}}*/
	multiset ids_query_covered(object image_integer,int id,object cell)/*{{{*/
	{
		multiset res=(<>);

		foreach(cell->query_selected(),[int k,int i,int j]){
			array val=image_integer->getpixel(i,j);
			multiset m=color2ids(val);
			res=res|m;
		}
		res[id]=0;

		/*
		object mask=ids_create_mask(image_integer,id);
		//object t=image_integer;//&mask;
		//werror("call max\n");
		array val=image_integer->max(mask);
		//werror("call max done val=%O\n",val);
		multiset ids=color2ids(val);
		//werror("call color2ids done\n");
		ids[id]=0;
		while(sizeof(ids)){
			foreach(ids;int id1;int one){
				werror("found %d\n",id1);
				res[id1]=1;
				object mask1=ids_create_mask(image_integer,id1);
				mask=mask&(mask1->invert());
				//t=t&(mask1->invert());
			}
			val=image_integer->max(mask);
			ids=color2ids(val);
			ids[id]=0;
		}*/
		//werror("ids_query_covered: %d\n",sizeof(res));
		return res;
	}/*}}}*/
	void draw_inc(object image,object cell,int id)/*{{{*/
	{
		//color=color||id2color(pos);
		//object cell=a[pos];
		foreach(cell->query_selected(),[int k,int i,int j]){
			[int r,int g,int b]=image->getpixel(i,j);
			if(r||g||b){
				multiset m=color2ids(({r,g,b}));
				m[id]=1;
				image->setpixel(i,j,@ids2color(m));
			}else{
				image->setpixel(i,j,@ids2color((<id>)));
			}
		}
	}/*}}}*/
	void draw_dec(object image,object cell,int id)/*{{{*/
	{
		//color=color||id2color(pos);
		//object cell=a[pos];
		foreach(cell->query_selected(),[int k,int i,int j]){
			[int r,int g,int b]=image->getpixel(i,j);
			if(r||g||b){
				multiset m=color2ids(({r,g,b}));
				m[id]=0;
				image->setpixel(i,j,@ids2color(m));
			}
		}
	}/*}}}*/
}

class ThreeDim{/*{{{*/
	mapping m=([]);
	int maxk;
	array parse_key(int key)
	{
		int y=key&0xffff; key>>=16;
		int x=key&0xffff; key>>=16;
		int k=key;
		return ({k,x,y});
	}
	mixed query(int k,int x,int y)
	{
		return m[(k<<32)|(x<<16)|y];
	}
	mixed set(int k,int x,int y,mixed val)
	{
		if(val){
			maxk=max(maxk,k);
			return m[(k<<32)|(x<<16)|y]=val;
		}else{
			m_delete(m,(k<<32)|(x<<16)|y);
			maxk=max(@map(indices(m),`>>,32));
		}
	}
	object clone()
	{
		object res=ThreeDim();
		res->m=copy_value(m);
		res->maxk=maxk;
		return res;
	}
	int _sizeof()
	{
		return maxk+1;
	}
}/*}}}*/

class PixelNodeSN
{
	class Static{
		int sn;
	}
}

class PixelNode
{
	inherit Node;
	int id=++(STATIC(PixelNodeSN)->sn);
	object a=ThreeDim();
	int levellimit;
	int d,w,h;
	int x_min=Int.NATIVE_MAX,x_max=0,y_min=Int.NATIVE_MAX,y_max=0,z_min=Int.NATIVE_MAX,z_max=0;
	void update_minmax()/*{{{*/
	{
		array a=query_selected();
		x_min=min(Int.NATIVE_MAX,@column(a,1));
		y_min=min(Int.NATIVE_MAX,@column(a,2));
		z_min=min(Int.NATIVE_MAX,@column(a,0));
		x_max=max(0,@column(a,1));
		y_max=max(0,@column(a,2));
		z_max=max(0,@column(a,0));
	}/*}}}*/
	void create(int limit,int _d,int _w,int _h)/*{{{*/
	{
		d=_d;w=_w;h=_h;
		levellimit=limit;
	}/*}}}*/
	int xsize(int level)/*{{{*/
	{
		return (int)pow(2.0,level);
	}/*}}}*/
	int ysize(int level)/*{{{*/
	{
		return (int)pow(2.0,level);
	}/*}}}*/
	private string _key;
	string key()/*{{{*/
	{
		if(_key==0){
			string res=encode_value_canonic(a->m);
			return res;
			_key=res;
		}
		return _key;
	}/*}}}*/
	object clone()/*{{{*/
	{
		object res=PixelNode(levellimit,d,w,h);
		res->a=a->clone();
		res->x_min=x_min;
		res->x_max=x_max;
		res->y_min=y_min;
		res->y_max=y_max;
		res->z_min=z_min;
		res->z_max=z_max;
		return res;
	}/*}}}*/
	object select(int k,int i,int j)/*{{{*/
	{
		x_min=min(x_min,i);
		x_max=max(x_max,i);
		y_min=min(y_min,j);
		y_max=max(y_max,j);
		z_min=min(z_min,k);
		z_max=max(z_max,k);
		a->set(k,i,j,1);
		return this;
	}/*}}}*/
	void unselect(int k,int i,int j)/*{{{*/
	{
		a->set(k,i,j,0);
		update_minmax();
	}/*}}}*/
	int is_selected(int k,int i,int j)/*{{{*/
	{
		return a->query(k,i,j);
	}/*}}}*/
	array query_selected()/*{{{*/
	{
		return map(indices(a->m),a->parse_key);
	}/*}}}*/
	int is_empty()/*{{{*/
	{
		return sizeof(a)==0;
	}/*}}}*/
	void dump()/*{{{*/
	{
		for(int k=0;k<sizeof(a);k++){
			for(int j=0;j<ysize(k);j++){
				for(int i=0;i<xsize(k);i++){
					write("%d ",a->query(k,i,j));
				}
				write("\n");
			}
			write("\n");
		}
		write("\n");
	}/*}}}*/
	PixelNode add(PixelNode rhd)/*{{{*/
	{
		object res=clone();
		foreach(rhd->query_selected(),[int k,int i,int j]){
			res->select(k,i,j);
		}
		return res;
	}/*}}}*/

}

class PixelRelationMapInterface{
	int xsize();
	int ysize();
	int zsize();

	void create(int w,int h);
	object clone();
	int count(multiset ids);
	array query_mask(int pos);

	object load(mapping result_o);
	multiset find_nodes(array atom);
}

class PixelEdgeRelationMap{
	inherit ArrayRelationMap;
	inherit IdImageTool;
	inherit IdsImageTool;
	inherit Tool;
	inherit PixelRelationMapInterface;
	object image;

	/* 以下是实现 RelationMap */

	int table_size(){return xsize()*ysize()*zsize();}
	int add(object cell)/*{{{*/
	{
		int pos=_add(cell);
		draw_inc(image,cell,pos);
		_finish_add(pos,cell);
		return pos;
	}/*}}}*/
	void remove(int pos)/*{{{*/
	{
		object cell=a[pos];
		draw_dec(image,cell,pos);
		_remove(pos);
		_finish_remove(pos,cell);
		//werror("after remove: %d [%d]=%O\n",count(),pos,a[pos]);
	}/*}}}*/
	multiset query_nearby(int pos)/*{{{*/
	{
		return ids_query_covered(image,pos,a[pos]);
	}/*}}}*/

	/* 以下是实现 PixelRelationMapInterface */
	int xsize(){return image->xsize();}
	int ysize(){return image->ysize();}
	int zsize(){return 1;}
	int count(multiset ids)/*{{{*/
	{
		return `+(0,@cellgroup_count(this,ids));
	}/*}}}*/
	array query_mask(int pos)/*{{{*/
	{
		return ({ids_create_mask(image,pos)});
	}/*}}}*/
	object load(mapping result_o/*,int levellimit*/)/*{{{*/
	{
		foreach(result_o;int id0;mapping m){
			array aa=m->cell;
			object cell=PixelNode(/*levellimit*/1,1,image->xsize(),image->ysize());
			if(sizeof(aa)==0)
				throw(({"empty cell in result.o\n",backtrace()}));
			foreach(aa,[int k,int i,int j]){
				cell->select(k,i,j);
			}
			while(id0>=sizeof(a))
				a+=({0});
			a[id0]=cell;
			draw_inc(image,cell,id0);
		}
		return this;
	}/*}}}*/
	void create(int w,int h)/*{{{*/
	{
		image=.ImageInteger.ImageInteger(w,h);
	}/*}}}*/
	object clone()/*{{{*/
	{
		object res=PixelEdgeRelationMap(image->xsize(),image->ysize());
		res->image=image->clone();
		//test_compare_image(res->image,image);
		res->a=copy_value(a);
		res->listeners=copy_value(listeners);
		return res;
	}/*}}}*/
	multiset find_nodes(array atom)/*{{{*/
	{
		return color2ids(image->getpixel(@atom));
	}/*}}}*/

	/* 以下是当前类特有 */

}

class PixelRelationMap{
	inherit ArrayRelationMap;
	inherit IdImageTool;
	inherit Tool;
	inherit PixelRelationMapInterface;
	object image;

	/* 以下是实现 RelationMap */

	int table_size(){return xsize()*ysize()*zsize();}
	int add(object cell)/*{{{*/
	{
		int pos=_add(cell);
		draw(image,cell,id2color(pos));
		_finish_add(pos,cell);
		return pos;
	}/*}}}*/
	void remove(int pos)/*{{{*/
	{
		object cell=a[pos];
		array color=({0,0,0});
		draw(image,cell,color);
		/*foreach(cell->query_selected(),[int k,int i,int j]){
			image->box(@cell->rangeof(k,i,j,cell->xsize(cell->levellimit),cell->ysize(cell->levellimit)),@color);
		}*/
		//werror("remove: %d [%d]=%O\n",count(),pos,a[pos]);
		_remove(pos);
		_finish_remove(pos,cell);
		//werror("after remove: %d [%d]=%O\n",count(),pos,a[pos]);
	}/*}}}*/
	multiset query_nearby(int pos)/*{{{*/
	{
		array mask;//=allocate(3,allocate(3,1));
		return image_query_nearby(image,image,pos,mask);
	}/*}}}*/

	/* 以下是实现 PixelRelationMapInterface */
	int xsize(){return image->xsize();}
	int ysize(){return image->ysize();}
	int zsize(){return 1;}
	int count(multiset ids)/*{{{*/
	{
		return `+(0,@cellgroup_count(this,ids));
	}/*}}}*/
	array query_mask(int pos)/*{{{*/
	{
		return ({id_create_mask(image,pos)});
	}/*}}}*/
	object load(mapping result_o/*,int levellimit*/)/*{{{*/
	{
		foreach(result_o;int id0;mapping m){
			array aa=m->cell;
			object cell=PixelNode(/*levellimit*/1,1,image->xsize(),image->ysize());
			if(sizeof(aa)==0)
				throw(({"empty cell in result.o\n",backtrace()}));
			foreach(aa,[int k,int i,int j]){
				cell->select(k,i,j);
			}
			while(id0>=sizeof(a))
				a+=({0});
			a[id0]=cell;
			draw(image,cell,id2color(id0));
		}
		return this;
	}/*}}}*/
	void create(int w,int h)/*{{{*/
	{
		image=Image.Image(w,h,0,0,0);
		//image=ImageInteger.ImageInteger(w,h)
	}/*}}}*/
	object clone()/*{{{*/
	{
		object res=PixelRelationMap(image->xsize(),image->ysize());
		res->image=image->clone();
		//test_compare_image(res->image,image);
		res->a=copy_value(a);
		res->listeners=copy_value(listeners);
		return res;
	}/*}}}*/
	multiset find_nodes(array atom)/*{{{*/
	{
		return (<color2id(image->getpixel(@atom))>);
	}/*}}}*/

	/* 以下是当前类特有 */

	int find_node(array atom)/*{{{*/
	{
		return color2id(image->getpixel(@atom));
	}/*}}}*/
#if 0
	multiset query_nearby_atom(int pos)/*{{{*/
	{
		array mask=allocate(3,allocate(3,1));
		return image_query_nearby_pixel(image,image,pos,mask);
	}/*}}}*/
	array query_corners(int pos)/*{{{*/
	{
		array res=({});
		array color=id2color(pos);
		object t=image->change_color(@color,255,255,255);
		t=t*({1,1,1});
		[int x1,int y1,int x2,int y2]=t->find_autocrop();
		int w=x2-x1; int h=y2-y1;
		foreach(({
					({x1,y1,x2+1,y1,1,0,0,1}),
					({x2,y1,x2,y2+1,0,1,-1,0}),
					({x2,y2,x1-1,y2,-1,0,0,-1}),
					({x1,y2,x1,y1-1,0,-1,1,0}),
					}),[int xb,int yb,int xe,int ye,int dx,int dy,int ix,int iy]){
			int i,j;
			int leftclose;
			array left=({}),right=({});
			for(i=xb,j=yb;i!=xe&&j!=ye;i+=dx,j+=dy){
				if(color2id(image->getpixel(i,j))!=pos){
					int ii,jj;
					int count;
					for(ii=i,jj=j;color2id(image->getpixel(ii,jj))!=pos;ii+=ix,jj+=iy){
						count++;
					}
					if(!leftclose)
						left+=({count});
					right+=({count});
				}else{
					right=({});
					leftclose=1;
				}
			}
			res+=({left,right});
		}
		return (res[<1..]+res[0..<1])/2;
	}/*}}}*/
#endif

}

class ThreeDimRelationMap{
	inherit ArrayRelationMap;
	inherit IdImageTool;
	inherit Tool;
	array(object) images;

	/* 以下是实现 RelationMap */

	int table_size(){return xsize()*ysize()*zsize();}
	int add(object cell)/*{{{*/
	{
		int pos=_add(cell);
		for(int i;i<sizeof(images);i++)
			drawlayer(images[i],i,cell,id2color(pos));
		_finish_add(pos,cell);
		return pos;
	}/*}}}*/
	void remove(int pos)/*{{{*/
	{
		object cell=a[pos];
		array color=({0,0,0});
		for(int i;i<sizeof(images);i++)
			drawlayer(images[i],i,cell,color);
		_remove(pos);
		_finish_remove(pos,cell);
	}/*}}}*/
	multiset query_nearby(int pos)/*{{{*/
	{
		array masks=query_mask(pos);

		array a=copy_value(masks);
		for(int i=0;i<sizeof(masks);i++){
			object t=masks[i];
			if(i>0)
				t=t|masks[i-1];
			if(i<sizeof(masks)-1)
				t=t|masks[i+1];
			a[i]=t;
		}
		array b=map(masks,"outline",255,255,255,0,0,0);

		array c=allocate(sizeof(masks));
		for(int i=0;i<sizeof(masks);i++){
			c[i]=(a[i]|b[i])&(masks[i]->invert());
		}

		multiset res=(<>);
		
		foreach(c;int k;object mask){
			if(mask!=0){
				[mask,object image]=.ImageInteger.mask_autocrop(mask,images[k]);
				for(int i=0;i<image->xsize();i++){
					for(int j=0;j<image->ysize();j++){
						if(mask->getpixel(i,j)[0]){
							array color=image->getpixel(i,j);
							int id=color2id(color);
							res[id]=1;
						}
					}
				}
			}
		}
		if(res[pos]){
			throw(({"bad query_nearby.\n",backtrace()}));
		}
		return res;

	}/*}}}*/

	/* 以下是实现 PixelRelationMapInterface */

	int xsize(){return images[0]->xsize();}
	int ysize(){return images[0]->ysize();}
	int zsize(){return sizeof(images);}
	int count(multiset ids)/*{{{*/
	{
		return `+(0,@cellgroup_count(this,ids));
	}/*}}}*/
	array query_mask(int pos)/*{{{*/
	{
		return map(images,id_create_mask,pos);
	}/*}}}*/
	object load(mapping result_o/*,int levellimit*/)/*{{{*/
	{
		foreach(result_o;int id0;mapping m){
			array aa=m->cell;
			object cell=PixelNode(/*levellimit*/sizeof(images),1,images[0]->xsize(),images[0]->ysize());
			if(sizeof(aa)==0)
				throw(({"empty cell in result.o\n",backtrace()}));
			foreach(aa,[int k,int i,int j]){
				cell->select(k,i,j);
			}
			while(id0>=sizeof(a))
				a+=({0});
			a[id0]=cell;
			//draw(image,cell,id2color(id0));
			for(int i;i<sizeof(images);i++)
				drawlayer(images[i],i,cell,id2color(id0));
		}
		return this;
	}/*}}}*/
	void create(int d,int w,int h)/*{{{*/
	{
		images=allocate(d,0);
		for(int i=0;i<d;i++){
			images[i]=Image.Image(w,h,0,0,0);
		}
	}/*}}}*/
	object clone()/*{{{*/
	{
		object res=PixelRelationMap(images[0]->xsize(),images[0]->ysize());
		res->images=map(images,"clone");
		res->a=copy_value(a);
		res->listeners=copy_value(listeners);
		return res;
	}/*}}}*/
	multiset find_nodes(array atom)/*{{{*/
	{
		return (<color2id(images[atom[0]]->getpixel(@atom[1..]))>);
	}/*}}}*/

	/* 以下是当前类特有 */

	int find_node(array atom)/*{{{*/
	{
		return color2id(images[atom[0]]->getpixel(@atom[1..]));
	}/*}}}*/
	array layers_count(multiset ids)/*{{{*/
	{
		return cellgroup_count(this,ids);
	}/*}}}*/

}


class PixelData(object/*(ImageInteger)*/ data){
	inherit PropertyData;
	inherit Tool;
	float costval;
	int layer;
	object set_layer(int n){layer=n;return this;}
	float cost() { return costval; }
	object set_cost(int|float val){costval=(float)val;return this;}
	DynamicRange dynamic_range(PixelRelationMap r,multiset ids,function|void maskfilter)/*{{{*/
	{
		array a=cellgroup_mask(r,ids);
		object mask0=a[layer];

		if(maskfilter)
			mask0=maskfilter(mask0);

#ifndef USING_COPY_OFFSET
		if(mask0->xsize()==data->xsize()&&mask0->ysize()==data->ysize())
			;
		else
			throw(({"size not match.\n",backtrace()}));
#endif


		
		[object mask,object dd0]=.ImageInteger.mask_autocrop(mask0,data);
		//[object mask,object dd0]=({mask0,data});

		/*if(mask==0){
			if(mask0==0)
				throw(({"zero mask0.\n",backtrace()}));
			throw(({"zero mask.\n",backtrace()}));
		}*/

		array maxval=dd0->max(mask);
		array minval=dd0->min(mask);
		array avgval=dd0->average(mask);
		//werror("minval=%O maxval=%O",minval,maxval);
		return DynamicRange(minval,maxval,avgval);
	}/*}}}*/
	object global_range()
	{
		return DynamicRange(data->min(),data->max(),data->average());
	}
	void update_cost()
	{
		object gr=global_range();
		costval=gr->atom_entropy()*2;
	}
}

class EntropyReduceSplitMode{
	class Interface{
		int split(object node,object r,mapping node2entropy);
	}
	class NoSplit{
		int split(object node,object r,mapping node2entropy) { }
	}
	class DataSideSplit{
		
		extern DynamicRangeEntropyInfo entropy_of(array data_list,object r,multiset ids);
		array query_data_list();
		int split(object node,object r,mapping node2entropy)/*{{{*/
		{
			if(r->split){
				//werror("split ok \n");
				int curr_pos=r->find(node);

				//werror("curr_pos=%d\n",curr_pos);

				array delta_list=({});array result_list=({});

				array pairs=r->split(curr_pos);
				//werror("pairs=%d\n",sizeof(pairs));
				foreach(pairs,[object older,object rest]){
					object rr=r->clone();
					rr->remove(curr_pos);
					int pos1=rr->add(older);
					int pos2=rr->add(rest);
					object info1=entropy_of(query_data_list(),rr,(<pos1>));
					object info2=entropy_of(query_data_list(),rr,(<pos2>));
					object info0=entropy_of(query_data_list(),r,(<curr_pos>));
					if(info1->explan_power()+info2->explan_power()>info0->explan_power()){
						delta_list+=({info1->explan_power()+info2->explan_power()-info0->explan_power()});
						result_list+=({({older,rest,info1,info2})});
					}
				}
				sort(delta_list,result_list);
				if(sizeof(result_list)){
					//werror("result_list ok\n");
					[object older,object rest,object info1,object info2]=result_list[-1];

					m_delete(node2entropy,r->a[curr_pos]);
					r->remove(curr_pos);

					r->add(older);
#ifdef COMPAREARRAY_ENTROPY
					node2entropy[older]=CompareArray.CompareArray((({info1->explan_power(),0.0})));
#else
					node2entropy[older]=info1->explan_power();
#endif
					older->info=info1;
					r->add(rest);
#ifdef COMPAREARRAY_ENTROPY
					node2entropy[rest]=CompareArray.CompareArray(({info2->explan_power(),0.0}));
#else
					node2entropy[rest]=info2->explan_power();
#endif
					rest->info=info2;

					return 1;
				}
			}
		}/*}}}*/
	}
	class OneDimSplit{
		object spliter;
		int split(object node,object r,mapping node2entropy)
		{
			if(spliter==0)
				return 0;
			int curr_pos=r->find(node);
			[object older,object rest,object info1,object info2]=spliter->split(this,r,node);
			if(older&&rest){
				m_delete(node2entropy,r->a[curr_pos]);
				r->remove(curr_pos);

				r->add(older);
#ifdef COMPAREARRAY_ENTROPY
				node2entropy[older]=CompareArray.CompareArray((({info1->explan_power(),0.0})));
#else
				node2entropy[older]=info1->explan_power();
#endif
				older->info=info1;
				r->add(rest);
#ifdef COMPAREARRAY_ENTROPY
				node2entropy[rest]=CompareArray.CompareArray(({info2->explan_power(),0.0}));
#else
				node2entropy[rest]=info2->explan_power();
#endif
				rest->info=info2;

				return 1;
			}
		}
	}
}

class EntropyReduceMode{
	class Interface{
		extern object r;
		array query_data_list();
		array entropy_if_merge(object r,int id1,int id2,mapping cache);
		extern DynamicRangeEntropyInfo entropy_of(array data_list,object r,multiset ids);
		extern DynamicRangeEntropyInfo entropy_single(object data,object r,multiset ids);
		extern DynamicRangeEntropyInfo entropy_div(object data,object r,multiset ids,int multer);
	}
	class UsingDataList{
		inherit Interface;
		array data_list;
		array query_data_list()
		{
			return data_list;
		}
		array entropy_if_merge(object r,int id1,int id2,mapping cache)
		{
			[int id11,int id22]=sort(({id1,id2}));
			int key=(id11<<64)|id22;
			if(cache[key]==0){
				object node1=r->a[id1];
				object node2=r->a[id2];
				PROFILING_BEGIN("entropy_if_merge")
				object node=node1->add(node2);

				object info=entropy_of(data_list,r,(<id1,id2>));
				node->info=info;
				cache[key]=({node,info->explan_power(),info->count,info});
#ifdef COMPAREARRAY_ENTROPY
				cache[key][1]=CompareArray.CompareArray(({cache[key][1],0.0}));
#endif

				PROFILING_END
			}
			return cache[key];
		}
		array entropy_if_alter(object r0,int from_id,int to_id,array kij_list)/*{{{*/
		{
			object r=r0->clone();
			object from_node0=r->a[from_id];
			object to_node0=r->a[to_id];
			object from_node=from_node0->clone();
			object to_node=to_node0->clone();
			foreach(kij_list,[int k,int i,int j]){
				from_node->unselect(k,i,j);
				to_node->select(k,i,j);
			}
			r->remove(from_id);
			r->remove(to_id);
			int id1=r->add(from_node);
			int id2=r->add(to_node);

			array res=({
					r,
#ifdef COMPAREARRAY_ENTROPY
					({from_node0,CompareArray.CompareArray(({from_node0->info->explan_power(),0.0})),from_node0->info->count,from_node0->info}),
					({to_node0,CompareArray.CompareArray(({to_node0->info->explan_power(),0.0})),to_node0->info->count,to_node0->info}),
#else
					({from_node0,from_node0->info->explan_power(),from_node0->info->count,from_node0->info}),
					({to_node0,to_node0->info->explan_power(),to_node0->info->count,to_node0->info}),
#endif
					});
			object info;

			multiset changed=(<>);

			info=entropy_of(data_list,r,(<id1>));
			from_node->info=info;
			if(info->count==0){
				r->remove(id1);
			}else{
				changed[id1]=1;
			}
			res+=({
#ifdef COMPAREARRAY_ENTROPY
					({from_node,CompareArray.CompareArray(({info->explan_power(),0.0})),info->count,info})
#else
					({from_node,info->explan_power(),info->count,info})
#endif
					});
			info=entropy_of(data_list,r,(<id2>));
			to_node->info=info;
			if(info->count==0){
				r->remove(id2);
			}else{
				changed[id2]=1;
			}
			res+=({
#ifdef COMPAREARRAY_ENTROPY
					({to_node,CompareArray.CompareArray(({info->explan_power(),0.0})),info->count,info})
#else
					({to_node,info->explan_power(),info->count,info})
#endif
					});
			res+=({changed});

			return res;
		}/*}}}*/
	}
	class UsingInfoAdd{
		inherit UsingDataList;
		/*array data_list;
		array query_data_list()
		{
			return data_list;
		}*/
		array entropy_if_merge(object r,int id1,int id2,mapping cache)
		{
			[int id11,int id22]=sort(({id1,id2}));
			int key=(id11<<64)|id22;
			if(cache[key]==0){
				object node1=r->a[id1];
				object node2=r->a[id2];
				PROFILING_BEGIN("entropy_if_merge")
				object node=node1->add(node2);

				node->info=node1->info->add(node2->info);
#ifdef COMPAREARRAY_ENTROPY
				cache[key]=({node,CompareArray.CompareArray(({node->info->explan_power(),0.0})),node->info->count,node->info});
#else
				cache[key]=({node,node->info->explan_power(),node->info->count,node->info});
#endif

				PROFILING_END
			}
			return cache[key];
		}
	}
#ifdef MULTI_MODELS
	class UsingModels{
#else
	class UsingPlane{
#endif
		inherit Interface;
		inherit Tool;
		program PixelData;
#ifdef MULTI_MODELS
		array models;
		object init_data;
		array query_data_list() { return ({init_data}); }
#else
		object target;
		object dx_left,dy_up;
		array query_data_list() { return ({target}); }
#endif
		array arouse_data_list;

		protected object mask2dx_internal(object mask)/*{{{*/
		{
			return mask->outline(({
					({0,0,0}),
					({0,1,1}),
					({0,0,0})
					}),0,0,0,255,255,255);
		};/*}}}*/
		protected object mask2dx_left(object mask)/*{{{*/
		{
			return mask;
		};/*}}}*/
		protected object mask2dx_both(object mask)/*{{{*/
		{
			return mask->outline(({
					({0,0,0}),
					({0,1,1}),
					({0,0,0})
					}),255,255,255,0,0,0);
		};/*}}}*/
		protected object mask2dx_right(object mask)/*{{{*/
		{
			return mask->outline(({
					({0,0,0}),
					({0,1,1}),
					({0,0,0})
					}),255,255,255,0,0,0)
			->outline(({
					({0,0,0}),
					({0,1,1}),
					({0,0,0})
					}),0,0,0,255,255,255)
			;
		};/*}}}*/
		protected object mask2dy_internal(object mask)/*{{{*/
		{
			return mask->outline(({
					({0,0,0}),
					({0,1,0}),
					({0,1,0})
					}),0,0,0,255,255,255);
		};/*}}}*/
		protected object mask2dy_up(object mask)/*{{{*/
		{
			return mask;
		};/*}}}*/
		protected object mask2dy_both(object mask)/*{{{*/
		{
			return mask->outline(({
					({0,0,0}),
					({0,1,0}),
					({0,1,0})
					}),255,255,255,0,0,0);
		};/*}}}*/
		protected object mask2dy_down(object mask)/*{{{*/
		{
			return mask->outline(({
					({0,0,0}),
					({0,1,0}),
					({0,1,0})
					}),255,255,255,0,0,0)
			->outline(({
					({0,0,0}),
					({0,1,0}),
					({0,1,0})
					}),0,0,0,255,255,255)
			;
		};/*}}}*/

		protected array normal_dxavg_internal(multiset ids,object mask)/*{{{*/
		{
				object dr;
				dr=dx_left(r,ids,mask2dx_internal(mask));
				array dxval=dr->avgval;
				dxval=map(dxval,Function.curry(`-)(0));
				return dxval;
		}/*}}}*/
		protected array normal_dyavg_internal(multiset ids,object mask)/*{{{*/
		{
				object dr;
				dr=dy_up(r,ids,mask2dy_internal(mask));
				array dyval=dr->avgval;
				dyval=map(dyval,Function.curry(`-)(0));
				return dyval;
		}/*}}}*/

		object create_plane(int w,int h,object image,array dx,array dy,array range,int multer)/*{{{*/
		{
			[int x1,int y1,int x2,int y2]=range;
#ifndef USING_COPY_OFFSET
			object res=.ImageInteger.ImageInteger(w,h)+image;
			for(int i=x1;i<=x2;i++){
				for(int j=y1;j<=y2;j++){
					array a=image->getpixel(i,j);
					res->setpixel(i,j,
							(int)floor((a[0]+i*dx[0]+j*dy[0])*multer),
							(int)floor((a[1]+i*dx[1]+j*dy[1])*multer),
							(int)floor((a[2]+i*dx[2]+j*dy[2])*multer),
							);
				}
			}
#else
			object res=.ImageInteger.ImageInteger(x2-x1+1,y2-y1+1)->set_copy_offset(x1,y1)+image->copy(x1,y1,x2,y2);
			for(int i=x1;i<=x2;i++){
				for(int j=y1;j<=y2;j++){
					array a=image->getpixel(i-x1,j-y1);
					res->setpixel(i-x1,j-y1,
							(int)floor((a[0]+i*dx[0]+j*dy[0])*multer),
							(int)floor((a[1]+i*dx[1]+j*dy[1])*multer),
							(int)floor((a[2]+i*dx[2]+j*dy[2])*multer),
							);
				}
			}
#endif
			return res;
		}/*}}}*/
	array ids_create_planes(object r,multiset ids,object target,function dx_left,function dy_up/*,function g*/,int multer)/*{{{*/
	{
		function dx=dx_left;
		function dy=dy_up;
		[object mask]=cellgroup_mask(r,ids);
		[int x1,int y1,int x2,int y2]=.ImageInteger.mask_find_autocrop(mask);
		array dxval;array dyval;array cval;
		mixed e;
		/*if(dx&&dy&&g){
			dxval=dx(r,ids)->avgval;
			dyval=dy(r,ids)->avgval;
			return ({({g(dxval,dyval),dxval,dyval,({0,0,target->data->xsize()-1,target->data->ysize()-1})})});
		}else */if(dx&&dy){

			if(r->count(ids)<=1){
				return ({({target->data,({0,0,0}),({0,0,0}),({x1,y1,x2,y2})})});
			}

			array res=({});
			int add_empty_flag;
			foreach(({mask2dx_internal/*,mask2dx_left,mask2dx_right,mask2dx_both*/}),function dxfilter){
				object dr;
				dr=dx(r,ids,dxfilter);
				dxval=dr->avgval;
				foreach(({mask2dy_internal/*,mask2dy_up,mask2dy_down,mask2dy_both*/}),function dyfilter){
					object dr;
					dr=dy(r,ids,dyfilter);
					dyval=dr->avgval;
					if(!equal(dxval,({0.0,0.0,0.0}))||!equal(dyval,({0.0,0.0,0.0}))){
						object plane=create_plane(target->data->xsize(),target->data->ysize(),target->data,dxval,dyval,({x1,y1,x2,y2}),multer);
						//注意：dxval,dyval比正常的数学值多了一个负号。因为我们要建立一个对冲斜面，所以就是要有这个负号才是正确的斜面。
						res+=({({plane,dxval,dyval,({x1,y1,x2,y2})})});
					}else{
						add_empty_flag=1;
					}
				}
			}
			if(add_empty_flag){
				res+=({({target->data,({0.0,0.0,0.0}),({0.0,0.0,0.0}),({x1,y1,x2,y2})})});
			}
			return res;
		}else{
			e=catch{
				[dxval,dyval,cval]=target->data->linear_fit(cellgroup_mask(r,ids)[0]);
				//werror("linear_fit return %O %O\n",dxval,dyval);
				dxval=map(dxval,Function.curry(`-)(0));
				dyval=map(dyval,Function.curry(`-)(0));
			};
			if(e){
				master()->handle_error(e);
			}
			if(e==0){
				object plane=create_plane(target->data->xsize(),target->data->ysize(),target->data,dxval,dyval,({x1,y1,x2,y2}),multer);
				return ({({plane,dxval,dyval,({x1,y1,x2,y2})})});
			}else{
				return ({({target->data,({0,0,0}),({0,0,0}),({x1,y1,x2,y2})})});
			}
		}
	}/*}}}*/
		array explan_ids(multiset ids,mapping|void id2a,mapping|void id2b,mapping|void id2c)/*{{{*/
		{
			id2a=id2a||([]);
			id2b=id2b||([]);
			id2c=id2c||([]);
			int entropy_count;
			float entropy=-Math.inf;
			object entropy_info;
#ifdef MULTI_MODELS
			foreach(models,[object target,function dx_left,function dy_up/*,function g,float cost*/]){
				array allplanes=ids_create_planes(r,ids,target,dx_left,dy_up/*,g*/,100);
#else
				array allplanes=ids_create_planes(r,ids,target,dx_left->dynamic_range,dy_up->dynamic_range,100);
#endif
				foreach(allplanes,[object plane,array dxval,array dyval,array range]){
					//object dr=PixelData(plane)->dynamic_range(r,(<pos>));
					int count=r->count(ids);
					object info=entropy_div(PixelData(plane)->set_weight(target->weight)->set_cost(target->cost()),r,ids,100);
					info->dxval=dxval;
					info->dyval=dyval;
					//float z=info->z;
					/*if(r->size()==1){
						werror("dxval=%O dyval=%O\n",dxval,dyval);
						for(int k=0;k<sizeof(plane->a);k++){
							Stdio.write_file(sprintf("output/debug-%d.png",k),Image.PNG.encode(plane->a[k]));
						}
						object image=Image.Image(plane->xsize(),plane->ysize(),0,0,0);
						for(int i=0;i<plane->xsize();i++){
							for(int j=0;j<plane->ysize();j++){
								array color=plane->getpixel(i,j);
								if(!equal(color,({0.0,0.0,0.0}))){
									//werror("%d %d %d %d %d\n",i,j,color[0],color[1],color[2]);
									image->setpixel(i,j,color[0]*70,color[1]*70,color[2]*70);

								}
							}
						}
						Stdio.write_file("output/debug.png",Image.PNG.encode(image));
					}*/
					/*if(pos==1){
						werror("z of 1 is %f\n",z);
						werror("info of 1 is %O\n",info);
					}*/
		/*werror("%d %s %s %s\n",pos,dx?dx->key:"-",dy?dy->key:"-",
		map(({dxmin,dxmax,dxval,dymin,dymax,dyval,info->minval,info->maxval,info->avgval,}),lambda(array a){ return map(a,Cast.stringfy)*" "; })*":");*/
					//werror("z=%f count=%d cost=%f\n",z,count,cost);
					//float val=-info->z*count-cost;
					float val=info->explan_power();
					if(val>entropy){
						foreach(ids;int pos;int one){
							id2a[pos]=dxval;
							id2b[pos]=dyval;
							id2c[pos]=info->avgval;
						}
						entropy=val;
						entropy_count=count;
						//info->dxval=dxval;
						//info->dyval=dyval;
						entropy_info=info;
					}
				}
#ifdef MULTI_MODELS
			}
#endif
			//werror("explan_ids return entropy %f\n",entropy);
			return ({entropy,entropy_count,entropy_info});
		}/*}}}*/
		float explan(mapping id2a,mapping id2b,mapping id2c)/*{{{*/
		{
			float sum=0.0;
			foreach(r->a;int pos;object node){
				if(node){
					[float entropy,int count,mapping info]=explan_ids((<pos>),id2a,id2b,id2c);
					sum+=entropy;
				}
			}
			return sum;
		}/*}}}*/
		array entropy_if_merge(object r,int id1,int id2,mapping cache)/*{{{*/
		{
			[int id11,int id22]=sort(({id1,id2}));
			int key=(id11<<64)|id22;
			if(cache[key]==0){
				object node1=r->a[id1];
				object node2=r->a[id2];
				PROFILING_BEGIN("entropy_if_merge")
				object node=node1->add(node2);

				[float entropy1,int count1,mapping info1]=explan_ids((<id1,id2>));
#ifdef COMPAREARRAY_ENTROPY
				float entropy2;int count2;object info2;
				if(sizeof(arouse_data_list)){
					info2=entropy_of(arouse_data_list,r,(<id1,id2>));
					entropy2=info2->explan_power();
					count2=info2->count;
				}else{
					entropy2=0.0;
					count2=count1;
				}
#endif
				node->info=info1;
#ifdef COMPAREARRAY_ENTROPY
				cache[key]=({node,CompareArray.CompareArray(({entropy1,entropy2})),count1,info1});
#else
				cache[key]=({node,entropy1,count1,info1});
#endif

				PROFILING_END
			}
			return cache[key];
		}/*}}}*/
		float edge_entropy(multiset ids1,multiset ids2,object node1,object node2,object mask1,object mask2)
		{
			array dx1=normal_dxavg_internal(ids1,mask1);//和数学值一致，不带负号
			array dy1=normal_dyavg_internal(ids1,mask1);
			array dx2=normal_dxavg_internal(ids2,mask2);
			array dy2=normal_dyavg_internal(ids2,mask2);
			array c1=node1->info->avgval;
			array c2=node2->info->avgval;

			array dx=dx1[*]-dx2[*];
			array dy=dy1[*]-dy2[*];
			array c=c1[*]-c2[*];

			//边界方程： dx * x + dy * y + c = 0;

			[int x1,int y1,int x2,int y2]=.ImageInteger.mask_find_autocrop(mask1&mask2);
			float e1=0.0;
			for(int i=x1;i<=x2;i++){
				for(int j=y1;j<=y2;j++){
				}
			}
			float e2=0.0;
			for(int j=y1;j<=y2;j++){
				for(int i=x1;i<=x2;i++){
				}
			}
			return 1.0+min(e1,e2);
		}
	}
}

class EntropyReduce{
	inherit EntropyReduceMode.Interface;
	inherit EntropyReduceSplitMode.Interface;
	inherit Tool;
	object r;
	mapping node2entropy=([]);
	int using_dynamic_colorrange_cost;
	int using_dynamic_dxdy_precision_cost;
	int using_edge_entropy;

	PixelData coord;

	int monitor_pixel_flag;
	array monitor_pixel_xy;
	DynamicRangeEntropyInfo entropy_from_dynamic_range(object dr,int weight,int count,float cost){/*{{{*/
		object res=dr;
		return DynamicRangeEntropyInfo(/*res->atom_entropy()*weight,*/count,res->minval,res->maxval,res->avgval,cost,weight*1.0);
	}/*}}}*/
	DynamicRangeEntropyInfo entropy_single(object data,object r,multiset ids)//类似v1，改用PixelRelationMap来获取数据/*{{{*/
	{
		return entropy_from_dynamic_range(data->dynamic_range(r,ids),data->weight,r->count(ids),data->cost());
#if 0
		object res=data->dynamic_range(r,ids);
		//if(r->size()==1) werror("dynamic_range=%O %O %O\n",res->minval,res->maxval,res->average);
		array t=res->maxval[*]-res->minval[*];
		t=map(t,max,0.0);
		t=map(t,`+,1.0);
		t=map(t,Math.log2);
		return DynamicRangeEntropyInfo(/*`+(0.0,@t)*data->weight,*/r->count(ids),res->minval,res->maxval,res->avgval,data->cost(),weight);
#endif
	}/*}}}*/
	DynamicRangeEntropyInfo entropy_div(object data,object r,multiset ids,int multer)
	{
		object res=entropy_from_dynamic_range(data->dynamic_range(r,ids),data->weight,r->count(ids),data->cost());
		res->multer=multer;
		return res;
	}
	DynamicRangeEntropyInfo entropy_of(array data_list,object r,multiset ids)/*{{{*/
	{
		int count=r->count(ids);

		//array vals=({}),keys=({});

		//熵=原始数据熵-经过模型解释以后的数据熵-模型熵

		do{
			mapping dynamic_range_data=([]);
			float cost=0.0;
			//array zz=({});
			array vv=({});
			array minvals=({}),maxvals=({}),avgvals=({});
			foreach(data_list,object data){
				object info=entropy_single(data,r,ids);
				if(data->cost()!=info->cost){
					werror("%O %O\n",data->cost(),info->cost);
					throw(({"data->cost not match with info->cost.\n",backtrace()}));
				}
				cost+=data->cost();
				//zz+=({info->z});
				vv+=({/*info->z*info->count+data->cost()*/-info->explan_power()});
				if(count!=info->count){
					werror("%O %O\n",count,info->count);
					throw(({"count not match with info->count.\n",backtrace()}));
				}
				minvals+=info->minval;
				maxvals+=info->maxval;
				avgvals+=info->avgval;
				//dynamic_range_data[data->key]=({info->minval,info->maxval,info->avgval});
			}
			//werror("i0=%f count=%d\n",i0,count);
			float entropy=-`+(0.0,@vv);
			object info=DynamicRangeEntropyInfo(/*`+(0.0,@zz),*/count,minvals,maxvals,avgvals,cost,1.0);
			return info;
			/*if(entropy==info2entropy(info)){
				return info;
			}else{
				werror("entropy=%f info2entropy(info)=%f\n",entropy,info2entropy(info));
				throw(({"entropy not match with info.\n",backtrace()}));
			}*/
			/*mapping info=(["type":"list","subtype":"none",
					"dynamic_range":dynamic_range_data,
					"entropy":entropy,
					"count":count,
					]);*/
		}while(0);
	}/*}}}*/

#ifdef OLDMERGE
private void clean_merge_cache(mapping cache,int id)/*{{{*/
{
	foreach(indices(cache),int key){
		int id1=key&0xffffffff;
		int id2=key>>64;
		if(id1==id||id2==id){
			m_delete(cache,key);
		}
	}
}/*}}}*/
private void print_best_list(array best_list)/*{{{*/
{
	werror("our best list is:\n");
	foreach(best_list;int k;[int j,object cell,float|object delta,object entropy,mapping entropy_info]){
		foreach(cell->query_selected(),[int k,int i,int j]){
			werror("%d,%d,%d;",k,i,j);
		}
		werror("\n delta=%O entropy=%f info=%O\n",delta,entropy->a[0],entropy_info);
	}
}/*}}}*/
	private void clean_nearby_mapping(mapping nearby_mapping,int i)/*{{{*/
	{
		foreach(nearby_mapping[i];int j;int one){
			if(nearby_mapping[j])
				nearby_mapping[j][i]=0;
		}
		m_delete(nearby_mapping,i);
	}/*}}}*/
	int merge(object r,mapping node2entropy)/*{{{*/
	{
		int rsize=r->size();

		mapping nearby_mapping=([]);

		PROFILING_BEGIN("build_nearby_mapping")
		//werror("build nearby_mapping ...\n");
		foreach(r->a;int i0;object node1){
			if(!node1)
				continue;
			nearby_mapping[i0]=nearby_mapping[i0]||(<>);
			foreach(r->query_nearby(i0);int j0;int one){
				nearby_mapping[i0][j0]=1;
			}
		}
		//werror("build nearby_mapping done\n");
		PROFILING_END

		mapping cache=([]);


		array g_range_caches=({CacheLite.Cache(CACHESIZE,1),CacheLite.Cache(CACHESIZE,1),CacheLite.Cache(CACHESIZE,1),CacheLite.Cache(CACHESIZE,1),CacheLite.Cache(CACHESIZE,1)});

		object dxdy_precision_cache=CacheLite.Cache(CACHESIZE,1);

		void handle_result(array res)
		{
			array ids=({});
			foreach(res,[string ig,object node1,object node2,object node,float|object entropy,mapping entropy_info]){
				//合并merge计算于此

				int i=r->find(node1);
				int j=r->find(node2);

				r->remove(i);
				r->remove(j);
				m_delete(node2entropy,node1);
				m_delete(node2entropy,node2);
				clean_nearby_mapping(nearby_mapping,i);
				clean_nearby_mapping(nearby_mapping,j);
				clean_merge_cache(cache,i);
				clean_merge_cache(cache,j);

				int id=r->add(node);
				r->a=copy_value(r->a);
				node2entropy[node]=entropy;
				node->info=entropy_info;

				ids+=({id});

				//合并merge计算完毕
			}
			foreach(ids,int id){
				nearby_mapping[id]=nearby_mapping[id]||(<>);
				foreach(r->query_nearby(id);int j0;int one){
					nearby_mapping[id][j0]=1;
					nearby_mapping[j0]=nearby_mapping[j0]||(<>);
					nearby_mapping[j0][id]=1;
				}
			}
		};

		int found;
		do{

			multiset working=(<>);
			multiset done=(<>);
			array res=({});
			//mapping merge_count=([]);

			//找出和i相邻的所有块中，i最想与其合并的块j
			//如果j也最想和i合并，则合并i,j
			//否则，找j最想合并的块，类推，直到找到双方都有意愿合并；
			//一定会有这样的块，因为最佳合并对一定是双方都最想和对方合并的。
			//如果j和别的块合并，从i的最佳合并列表中剔除j
			//并列第一会导致团团转，通过把当前节点直接标注为done来防止

			int merge_with_best_nearby(int i,int from)/*{{{*/
			{
				//werror("merge_with_best_nearby %d %d\n",i,sizeof(nearby_mapping[i]));
				if(done[i]||working[i])
					return 0;
				else 
					working[i]=1;

				//找出最佳合并列表 best_list
				array delta_list=({});
				array change_list=({});
				object node1=r->a[i];
				if(!node1){
					working[i]=0;
					done[i]=1;
					return 0;
				}
				foreach(nearby_mapping[i];int j;int one){
					object node2=r->a[j];
					if(node2==0){
						throw(({"bad node2.\n",backtrace()}));
					}
					[object node,float|object entropy,int entropy_count,mapping entropy_info]=entropy_if_merge(r,i,j,cache);
					float|object entropy1=node2entropy[node1];
					float|object entropy2=node2entropy[node2];
					//werror("entropy1=%O entropy2=%O\n",entropy1,entropy2);
					float|object extra_entropy=0.0;
					float|object old_extra_entropy=0.0;
					if(using_dynamic_colorrange_cost){/*{{{*/
						/* 每个聚合类有一个残差范围，[r..R] [g..G] [b..B]
							 残差的基质视为无冗余，我们希望减小残差范围宽度的熵，
							 即每个聚合类有三个属性，D_r,D_g,D_b
							 对表{(class_id,D_r,D_g,D_b)*n}进行归约
							 class_id应该被视为有序的
							 对D_r,D_g,D_b计算范围[0,(D_r)_{max}] [0,(D_g)_{max}] [0,(D_b)_{max}] 
							 熵为：(ln((D_r)_max+1)+ln((D_g)_max+1)+ln((D_b)_max+1))*N_{class_id}
							 */
						array a1=filter(r->a,`!=,0);
						array a2=a1-({node1,node2})+({node});
						int mycount(object node,int n)
						{
							return (node->info->valncount(n)-1)/node->info->multer+1;
						};
						array old_valcounts=({0,0,0});
						for(int i=0;i<3;i++){
							old_valcounts[i]=g_range_caches[i](r->a,lambda(){
									//werror("range cache miss.\n");
									return max(0,@map(a1,mycount,i))+1;
									});
						}
						array new_valcounts=({0,0,0});
						for(int i=0;i<3;i++){
							int count1=mycount(node1,i);
							int count2=mycount(node2,i);
							int count=mycount(node,i);
							int oldmaxcount=old_valcounts[i];
							if(count1==oldmaxcount&&count<count1||count2==oldmaxcount&&count<count2){
								werror("count=%d count1=%d count2=%d oldmax=%d slowmode\n",count,count1,count2,oldmaxcount);
								new_valcounts[i]=max(0,@map(a2,mycount,i))+1;
							}else if(count1<oldmaxcount&&count2<oldmaxcount){
								new_valcounts[i]=max(0,@map(a2,mycount,i))+1;
								//new_valcounts[i]=max(old_valcounts[i],count);
							}else{
								abort();
							}
						}
						extra_entropy+=Math.log2(`*(1.0,@new_valcounts))*(r->size()-1);
						old_extra_entropy+=Math.log2(`*(1.0,@old_valcounts))*r->size();
						/*for(int i=0;i<=2;i++){
							extra_entropy+=Math.log2(0.0+max(0,@map(a1,mycount,i))+1)*(r->size()-1);
							old_extra_entropy+=Math.log2(0.0+max(0,@map(a2,mycount,i))+1)*r->size();
						}*/
						/*
						int valcount1=max(0,@map(a1,mycount,0))*max(0,@map(a1,mycount,1))*max(0,@map(a1,mycount,2));
						int valcount2=max(0,@map(a2,mycount,0))*max(0,@map(a2,mycount,1))*max(0,@map(a2,mycount,2));
						//int level_count1=max(0,@map(a1,lambda(object node){return node->info->valncount();}));
						//int level_count2=max(0,@map(a2,lambda(object node){return node->info->valncount();}));
						extra_entropy+=boson_classify_entropy(r->size()-1,valcount2);
						old_extra_entropy+=boson_classify_entropy(r->size(),valcount1);
						*/
					}/*}}}*/
					if(using_dynamic_dxdy_precision_cost){
						array a1=filter(r->a,`!=,0);
						array a2=a1-({node1,node2})+({node});

#ifndef DXDY_PRECISION_USING_PIXELNODE
						[mapping id2range,mapping node2id]=dxdy_precision_cache(r->a,lambda(){
						mapping id2range=([]);
						mapping node2id=([]);

						for(int i=0;i<r->image->xsize();i++){/*{{{*/
							for(int j=0;j<r->image->ysize();j++){
								array c=r->image->getpixel(i,j);
								multiset m=r->color2ids(c);
								if(sizeof(m)==0){
									abort();
								}
								foreach(m;int id;int one){
									id2range[id]=id2range[id]||({Int.NATIVE_MAX,0,Int.NATIVE_MAX,0});
									id2range[id][0]=min(id2range[id][0],i);
									id2range[id][1]=max(id2range[id][1],i);
									id2range[id][2]=min(id2range[id][2],j);
									id2range[id][3]=max(id2range[id][3],j);
								}
							}
						}/*}}}*/
						foreach(r->a;int id;object node){
							if(node)
								node2id[node]=id;
						}

						return ({id2range,node2id});
						});

						object newnode=node;
						int mycount1(object node,int n)
						{
							/*int i=node2id[node1];
							int j=node2id[node2];
							*/
							int i=r->find(node1);
							int j=r->find(node2);
							if(node==newnode){
								if(id2range[i]==0){
									werror("%O",r->a[i]->query_selected());
								}
								if(id2range[j]==0){
									werror("%O",r->a[j]->query_selected());
								}
								if(n==0){
									return max(id2range[i][1],id2range[j][1])-min(id2range[i][0],id2range[j][0])+1;
								}else if(n==1){
									return max(id2range[i][3],id2range[j][3])-min(id2range[i][2],id2range[j][2])+1;
								}
							}else{
								int id=node2id[node];
								if(id2range[id]==0){
									werror("%O",r->a[id]->query_selected());
								}
								if(n==0){
									return id2range[id][1]-id2range[id][0]+1;
								}else if(n==1){
									return id2range[id][3]-id2range[id][2]+1;
								}
							}
						};
						int mycount2(object node,int n)
						{
							if(n==0){
								return node->x_max-node->x_min+1;
							}else if(n==1){
								return node->y_max-node->y_min+1;
							}
						};
						int mycount(object node,int n)
						{
							int res1,res2;
							res1=mycount1(node,n);
							res2=mycount2(node,n);
							if(res1==res2){
								return res1;
							}else{
								werror("res1=%d res2=%d n=%d\n",res1,res2,n);
								werror("%O",node->query_selected());
								if(node!=newnode){
									int id=r->find(node);
									for(int i=0;i<r->image->xsize();i++){
										for(int j=0;j<r->image->ysize();j++){
											array c=r->image->getpixel(i,j);
											multiset m=r->color2ids(c);
											if(m[id]){
												werror("%d %d\n",i,j);
											}
										}
									}
								}
								abort();
							}
						};
#else
						int mycount(object node,int n)
						{
							if(n==0){
								return node->x_max-node->x_min+1;
							}else if(n==1){
								return node->y_max-node->y_min+1;
							}
						};
#endif
						array old_valcounts=({0,0});
						for(int i=0;i<2;i++){
							old_valcounts[i]=g_range_caches[2+i](r->a,lambda(){
									//werror("range cache miss.\n");
									return max(0,@map(a1,mycount,i))+1;
									});
						}
						array new_valcounts=({0,0});
						for(int i=0;i<2;i++){
							new_valcounts[i]=max(0,@map(a2,mycount,i))+1;
						}
						extra_entropy+=Math.log2(`*(1.0,@new_valcounts))*(r->size()-1);
						old_extra_entropy+=Math.log2(`*(1.0,@old_valcounts))*r->size();
					}
					if(using_edge_entropy){/*{{{*/
						object create_edge_mask(multiset m1,multiset m2)
						{
							return (cellgroup_mask(r,m1)[0])&(cellgroup_mask(r,m2)[0]);
						};
						float query_edge_entropy(object node,multiset ids)
						{
							float res=0.0;
							multiset m=`|(@map((array)ids,r->query_nearby))-ids;
							object mask=cellgroup_mask(r,ids)[0];
							foreach(m;int id;int one){
								object node1=r->a[id];
								object mask1=cellgroup_mask(r,(<id>))[0];
								res+=this->edge_entropy(ids,(<id>),node,node1,mask,mask1);
							}
						};
						float|object edge_entropy1=query_edge_entropy(node1,(<i>));
						float|object edge_entropy2=query_edge_entropy(node2,(<j>));
						float|object edge_entropy3=query_edge_entropy(node,(<i,j>));
						old_extra_entropy+=edge_entropy1+edge_entropy2-this->edge_entropy((<i>),(<j>),node1,node2,cellgroup_mask(r,(<i>))[0],cellgroup_mask(r,(<j>))[0]);
						extra_entropy+=edge_entropy3;
					}/*}}}*/
					if(objectp(entropy)){
#ifdef COMPAREARRAY_ENTROPY
						extra_entropy=CompareArray.CompareArray(({extra_entropy,extra_entropy}));
						old_extra_entropy=CompareArray.CompareArray(({old_extra_entropy,old_extra_entropy}));
#endif
					}
					float|object ep=entropy;//entropy 实际是解释力 extra_entropy 是熵
					float|object ep1=entropy1;
					float|object ep2=entropy2;
					float|object delta=ep-ep1-ep2+(old_extra_entropy-extra_entropy);
					array info=({j,node,delta,entropy,entropy_info});
					if(monitor_pixel_flag){
						entropy_info->entropy1=entropy1->a[0];
						entropy_info->entropy2=entropy2->a[0];
					}
#ifdef COMPAREARRAY_ENTROPY
					if(floatp(delta))
						delta=CompareArray.CompareArray(({delta,0.0}));
					if(delta>CompareArray.CompareArray(({0.0,0.0}))){
						delta_list+=({CompareArray.CompareArray(({delta,working[j],-done[j]}))});
						change_list+=({info});
					}
#else
					if(delta>0.0){
						delta_list+=({CompareArray.CompareArray(({delta,working[j],-done[j]}))});
						change_list+=({info});
					}
#endif
				}
				sort(delta_list,change_list);
				array best_list=reverse(change_list);

				int monitor_this;
				if(monitor_pixel_flag){
#ifdef USING_LEVELLIMIT
					int k=node1->levellimit;
					//werror("monitor_pixel_xy=%O\n",monitor_pixel_xy);
					int i=monitor_pixel_xy[0][0];
					int j=monitor_pixel_xy[0][1];
					if(node1->is_selected(k,i,j)/*||node1->is_partly_selected(k,i,j)*/)
						monitor_this=1;
#else
					//werror("monitor_pixel_xy=%O\n",monitor_pixel_xy);
					int i=monitor_pixel_xy[0][0];
					int j=monitor_pixel_xy[0][1];
					if(node1->is_selected(0,i,j)/*||node1->is_partly_selected(k,i,j)*/)
						monitor_this=1;
#endif
					/*array a=node1->query_selected();
					foreach(a,[int k,int i,int j]){
						if(k==node1->levellimit&&i==monitor_pixel_xy[0]&&j==monitor_pixel_xy[1]){
							monitor_this=1;
						}
						break;
					}*/
				}
				foreach(best_list;int k;[int j,object node,object|float delta,float|object entropy,mapping entropy_info]){
					if(monitor_this){
						array a=node->query_selected();
						werror("want to merge with ");
						foreach(a,[int k,int i,int j]){
							werror("%d,%d,%d;",k,i,j);
						}
						werror("\n");
					}
#ifdef COMPAREARRAY_ENTROPY
					if(delta<=CompareArray.CompareArray(({0.0,0.0}))){
						if(monitor_this)
							werror("delta<=0\n");
						break;
					}
#else
					if(delta<=0.0){
						if(monitor_this)
							werror("delta<=0\n");
						break;
					}
#endif
					if(j==from){ //i最想和j合并，而上一步正好是从j过来的，j也最想和i合并
						if(monitor_this){
							werror("good! we just walk from there.\n");
							print_best_list(best_list);
							//exit(0);
						}
						//werror("merge %d %d\n",i,j);
						//merge_count[i]++;
						//merge_count[j]++;

						res+=({({"merge",r->a[i],r->a[j],node,entropy,entropy_info})});
						working[i]=0;
						done[i]=1;
						return 1;
					}else{
						if(monitor_this){
							werror("does it want to merge with us?\n");
						}
						int succ;
						succ=merge_with_best_nearby(j,i);
						if(monitor_this){
							if(succ){
								werror("yes, merged.\n");
								print_best_list(best_list);
								//exit(0);
							}else if(k+1<sizeof(best_list)&&best_list[k+1][2]==delta)
								werror("no, try next.\n");
							else
								werror("no, wait next phase.\n");

						}
						if(k+1<sizeof(best_list)&&best_list[k+1][2]==delta)
							;
						else
							break;//只要最好的，没有最好的，就等下一轮
						if(succ)
							break;
					}
				}
				working[i]=0;
				done[i]=1;
			};/*}}}*/

			//werror("count=%d\n",r->size());
			PROFILING_BEGIN("merge_with_best_nearby")
			found=0;
			foreach(r->a;int i;object node1){
				if(node1&&!done[i]){
					merge_with_best_nearby(i,-1);
				}
			}
			PROFILING_END
			//werror("%O",merge_count);
			if(sizeof(res)){
				found=1;
				//werror("count=%d -%d\n",r->size(),sizeof(res));
				handle_result(res);
			}
			res=({});
		}while(found);

		/*
		mapping nodeid_badpixels=([]);
		PROFILING_BEGIN("build_nodeid_badpixels")
		werror("build nodeid_badpixels ...\n");
		foreach(r->a;int i0;object node1){
			if(!node1)
				continue;
			nodeid_badpixels[i0]=nodeid_badpixels[i0]||(<>);
			for(int i=0;i<r->xsize();i++){
				for(int j=0;j<r->ysize();j++){
				}
			}
		}
		werror("build nodeid_badpixels done\n");
		PROFILING_END

		int merge_with_best_splited(int i)
		{
			object node1=r->a[i];
			if(!node1)
				return 0;

			foreach(r->query_nearby_atom(i);array pair;int one){
				int id2=r->find_node(pair);
				object node2=r->a[id2]->clone();
				node2->unselect(levellimit,@pair);
			}
		}
		*/
		return rsize-r->size();
	}/*}}}*/
#else

	/* 老的merge策略重复使用一个递归算法，寻找多对互为最想合并的节点对，
		 如果找到，合并以后，更新数据重新搜索。我认为重新搜索浪费了上一次搜索
		 的中间过程。新的想法如下：我们建立一张图，每个节点指向自己最想合并的节点，
		 以及这个决策依赖于那些节点，如果被依赖的节点发生了变化，更新这张图。
		 根据这张动态更新的图，我们总能找到任何一个时刻最应该被合并的节点。
		 */

	class MergeNode(object node){
		inherit MergeGraph.Node;
	}

	class MyMergeGraph{
		inherit MergeGraph.MergeGraph;
		array g_range_caches=({CacheLite.Cache(CACHESIZE,1),CacheLite.Cache(CACHESIZE,1),CacheLite.Cache(CACHESIZE,1),CacheLite.Cache(CACHESIZE,1),CacheLite.Cache(CACHESIZE,1)});
		MergeGraph.MergeResult query_merge_result(MergeNode first,MergeNode second)
		{
			object node1=first->node;
			object node2=second->node;
			int i=r->find(node1);
			int j=r->find(node2);
			
			mapping cache=([]);
			[object node,float ep,int entropy_count,object entropy_info]=entropy_if_merge(r,i,j,cache);
			float ep1=node2entropy[node1];
			float ep2=node2entropy[node2];
			return MergeGraph.MergeResult(MergeNode(node),ep-ep1-ep2);
			
			//return MergeGraph.MergeResult(MergeNode(0,0),0.0);
		}
		private int mycount(object node,int n)
		{
			return (node->info->valncount(n)-1)/node->info->multer+1;
		};
		MergeGraph.GlobalGain query_global_gain(MergeNode first,MergeNode second,MergeNode result,mixed global_status)/*{{{*/
		{
			object node1=first->node;
			object node2=second->node;
			object node=result->node;

			float|object extra_entropy=0.0;
			float|object old_extra_entropy=0.0;

			array new_valcounts=({0,0,0});

			if(using_dynamic_colorrange_cost){/*{{{*/
				/* 每个聚合类有一个残差范围，[r..R] [g..G] [b..B]
					 残差的基质视为无冗余，我们希望减小残差范围宽度的熵，
					 即每个聚合类有三个属性，D_r,D_g,D_b
					 对表{(class_id,D_r,D_g,D_b)*n}进行归约
					 class_id应该被视为有序的
					 对D_r,D_g,D_b计算范围[0,(D_r)_{max}] [0,(D_g)_{max}] [0,(D_b)_{max}] 
					 熵为：(ln((D_r)_max+1)+ln((D_g)_max+1)+ln((D_b)_max+1))*N_{class_id}
					 */
				array a1=filter(r->a,`!=,0);
				array a2=a1-({node1,node2})+({node});
				/*
				array old_valcounts=({0,0,0});
				for(int i=0;i<3;i++){
					old_valcounts[i]=g_range_caches[i](r->a,lambda(){
							werror("range cache miss.\n");
							return max(0,@map(a1,mycount,i))+1;
							});
				}*/
				array old_valcounts=global_status;
				for(int i=0;i<3;i++){
					int count1=mycount(node1,i);
					int count2=mycount(node2,i);
					int count=mycount(node,i);
					int oldmaxcount=old_valcounts[i];
					if(count1==oldmaxcount&&count<count1||count2==oldmaxcount&&count<count2){
						werror("count=%d count1=%d count2=%d oldmax=%d slowmode\n",count,count1,count2,oldmaxcount);
						new_valcounts[i]=max(0,@map(a2,mycount,i))+1;
					}else if(count1<oldmaxcount&&count2<oldmaxcount){
						new_valcounts[i]=max(0,@map(a2,mycount,i))+1;
						//new_valcounts[i]=max(old_valcounts[i],count);//有可能会变小
					}else{//count1>oldmaxcount||count2>oldmaxcount
						abort();
					}
				}
				extra_entropy+=Math.log2(`*(1.0,@new_valcounts))*(r->size()-1);
				old_extra_entropy+=Math.log2(`*(1.0,@old_valcounts))*r->size();
			}/*}}}*/
			//werror("ggain=%f\n",old_extra_entropy-extra_entropy);
			return MergeGraph.GlobalGain(old_extra_entropy-extra_entropy,new_valcounts);
		}/*}}}*/

		array query_global_status()
		{
			array a1=filter(r->a,`!=,0);
			array old_valcounts=({0,0,0});
			for(int i=0;i<3;i++){
				old_valcounts[i]=g_range_caches[i](r->a,lambda(){
						//werror("range cache miss.\n");
						return max(0,@map(a1,mycount,i))+1;
						});
			}
			return old_valcounts;
		}
		void check_node(object(MergeNode)|int node)
		{
				mixed e=catch{
					r->find(node->node);
				};
				if(e){
					abort();
				}
		}
		void check(string info,multiset|void exclude)
		{
			exclude=exclude||(<>);
			foreach(nearby_mapping;object node;mapping paths){
				mixed e=catch{
					if(!exclude[node])
						r->find(node->node);
				};
				if(e){
					werror("node=%O\n",node);
					//master()->handle_error(e);
					abort();
				}
			}
			foreach(nearby_mapping;object node;mapping paths){
				mixed e=catch{
					foreach(paths;object node;mixed ig){
						if(!exclude[node])
							r->find(node->node);
					}
				};
				if(e){
					//master()->handle_error(e);
					abort();
				}
			}
			foreach(best_merges;object node;mixed ig){
				mixed e=catch{
					if(!exclude[node])
						r->find(node->node);
				};
				if(e){
					//master()->handle_error(e);
					abort();
				}
			}
		}
		MergeGraph.Action choose_action(multiset actions)
		{
			//werror("enter choose_action: r->size()=%d\n",r->size());
			/*foreach(actions;object t;int one){
				werror("t: %O %O\n",t->first,t->second);
			}*/
			if(sizeof(actions)>1){
				werror("sizeof actions=%d\n",sizeof(actions));
			}
			object action=actions[0];//XXX: select action

			/*foreach(nearby_mapping;object ob;mixed ig){
				if(ob->_byvalue_item_id==2203){
					werror("2203 exist before choose_action\n");
					if(ob!=action->first&&ob!=action->second){
						if(ob->node==action->first->node||ob->node==action->second->node){
							abort();
						}
					}
				}
			}*/

			object result=nearby_mapping[action->first][action->second]->node;
			//array global_status=best_merges[action->first]->nodes[action->second];
			object node1=action->first->node;
			object node2=action->second->node;
			object node=result->node;
			mixed e=catch{
				//array b=copy_value(r->a);
				//werror("remove %O %O\n",action->first,action->second);
				int i=r->find(node1);
				int j=r->find(node2);
				r->remove(i);
				r->remove(j);
				/*b=b-r->a-({node1,node2});
				if(sizeof(b)){
					werror("%O\n",b);
					abort();
				}*/
				m_delete(node2entropy,node1);
				m_delete(node2entropy,node2);
				//werror("add %O\n",result);
				int id=r->add(node);
				r->a=copy_value(r->a);
				node2entropy[node]=node->info->explan_power();
				/*if(node->info!=result->entropy_info){
					abort();
					node->info=result->entropy_info;
				}*/
				/*i=0; catch{ i=r->find(node1); };
				j=0; catch{ j=r->find(node2); };
				if(i||j){
					abort();
				}*/
			};
			if(e){
				werror("node1=%O node2=%O\n",node1,node2);
				throw(e);
			}
			/*foreach(nearby_mapping;object ob;mixed ig){
				if(ob->_byvalue_item_id==2203){
					werror("2203 exist after choose_action\n");
				}
			}*/

			//werror("leave choose_action: r->size()=%d\n",r->size());
			return action;

		}
	}

	int merge(object r,mapping node2entropy)
	{
		object merge_graph=MyMergeGraph();

		mapping id2node=([]);
		multiset done=(<>);
		int rsize=r->size();
		foreach(r->a;int i0;object node1){
			if(node1){
				foreach(r->query_nearby(i0);int j0;int one){
					object key=ByValue.Set(i0,j0);
					if(!done[key]){
						object node2=r->a[j0];
						id2node[i0]=id2node[i0]||MergeNode(node1);
						id2node[j0]=id2node[j0]||MergeNode(node2);
						merge_graph->insert_nearby((<id2node[i0],id2node[j0]>));
						done[key]=1;
					}
				}
			}
		}
		return merge_graph->merge();
	}
#endif

	void update_entropy(multiset|void m)/*{{{*/
	{
		foreach(r->a;int id;object node)
		{
			if(node&&(m==0||m[id])){
				object info=entropy_of(query_data_list(),r,(<id>));
				node->info=info;
				float entropy=info->explan_power();
				//werror("%d entropy=%f\n",sizeof(node2entropy),entropy);
#ifdef COMPAREARRAY_ENTROPY
				node2entropy[node]=CompareArray.CompareArray(({entropy,0.0}));
#else
				node2entropy[node]=entropy;
#endif
			}
		}
	}/*}}}*/

	void feed(object node)/*{{{*/
	{
		int id=r->find(node);
		//object info=node_entropy(init_data?({init_data}):data_list,r,(<id>));
		object info=entropy_of(query_data_list(),r,(<id>));
		node->info=info;
		float entropy=info->explan_power();
		werror("%d entropy=%f\n",sizeof(node2entropy),entropy);
#ifdef COMPAREARRAY_ENTROPY
		node2entropy[node]=CompareArray.CompareArray(({entropy,0.0}));
#else
		node2entropy[node]=entropy;
#endif
	}/*}}}*/
	void advance()/*{{{*/
	{
		while(1){
			int count;
			array before=r->a-({0});
			if(sizeof(before)==1){
				count+=split(before[0],r,node2entropy);
			}else{
				count+=merge(r,node2entropy);
				array after=r->a-({0});

				array new=after-before;
				foreach(new,object node){
					count+=split(node,r,node2entropy);
				}
			}
			if(count==0){
				break;
			}
		}
	}/*}}}*/

}

object MultiDataReduce=CLASS(EntropyReduce,EntropyReduceMode.UsingDataList,EntropyReduceSplitMode.DataSideSplit);
#ifdef MULTI_MODELS
object MultiModelReduce=CLASS(EntropyReduce,EntropyReduceMode.UsingModels,EntropyReduceSplitMode.DataSideSplit);
#else
object PlaneReduce=CLASS(EntropyReduce,EntropyReduceMode.UsingPlane,EntropyReduceSplitMode.DataSideSplit);
#endif
object FastReduce=CLASS(EntropyReduce,EntropyReduceMode.UsingInfoAdd,EntropyReduceSplitMode.DataSideSplit);
object OneDimReduceWithoutSpliter=CLASS(EntropyReduce,EntropyReduceMode.UsingDataList,EntropyReduceSplitMode.DataSideSplit);
object OneDimReduceWithSpliter=CLASS(EntropyReduce,EntropyReduceMode.UsingDataList,EntropyReduceSplitMode.OneDimSplit);
object OneDimReduceNoSplit=CLASS(EntropyReduce,EntropyReduceMode.UsingDataList,EntropyReduceSplitMode.NoSplit);

class SecurityData{/*{{{*/
	inherit PropertyData;
	inherit Tool;
	float costval;
	float cost(){return costval;}
	int multer;
	Candle.line line;
	//mapping line=(["a":({})]);
	array atom_value(int i,object r,multiset ids);

	void update_cost(int begin,int end)/*{{{*/
	{
		object dr=dynamic_range(([
					"a":({
						([
						 "beginpos":begin,
						 "endpos":min(end,sizeof(line->a)),
						 ])
					}),
					]),(<0>));
		costval=Math.log2(0.0+dr->maxval[0]-dr->minval[0]+1)*2;
		werror("max=%d min=%d\n",dr->maxval[0],dr->minval[0]);
		werror("costval=%f\n",costval);
	}/*}}}*/

	DynamicRange dynamic_range(RelationMap|mapping r,multiset ids/*,int|void debug*/)
	{
		/*if(debug){
			werror("dynamic_range debug begin\n");
		}*/
		float maxval=-Math.inf;
		float minval=Math.inf;
		float avgval;
		int count;
		foreach(ids;int pos;int one){
			//if(debug){ werror("pos=%d\n",pos); }
			object node=r->a[pos];
			if(node){
				//if(debug){ werror("node->beginpos=%d node->endpos=%d\n",node->beginpos,node->endpos); }
				int beginpos=node->beginpos;

				for(int i=beginpos;i<node->endpos;i++){
					/*
					Candle.Item item=line->a[i];
					float beginval;
					if(i>0)
						beginval=line->a[i-1]->closeval;
					else
						beginval=item->openval;
					float maxdelta=item->maxval-beginval;
					float mindelta=item->minval-beginval;
					float closedelta=item->closeval-beginval;
					*/
					[float|int closedelta]=atom_value(i,r,ids);
					closedelta=closedelta*1.0;
		/*if(debug){
			werror("closedelta(%d):%f-%f=%f\n",i,item->closeval,beginval,closedelta);
		}*/

					//maxval=max(maxdelta,maxval);
					//minval=min(mindelta,minval);
					maxval=max(closedelta,maxval);
					minval=min(closedelta,minval);
					avgval+=closedelta;
					count++;
				}
			}
		}
		//if(debug){ werror("dynamic_range debug end\n"); }
		if(count){
			avgval/=count;
			return DynamicRange(({(int)(minval)}),({(int)(maxval)}),({avgval}));
		}else{
			return DynamicRange(({0}),({0}),({0}));
		}
	}
}/*}}}*/

class SecurityPlaneData{/*{{{*/
	inherit SecurityData;
	object delta_data;
	void update_cost(int begin,int end)
	{
		if(end-begin<5){
			end=min(begin+5,sizeof(line->a));
		}
		::update_cost(begin,end);
	}

	void create(object _delta_data,int _multer)
	{
		delta_data=_delta_data;
		line=delta_data->line;
		multer=_multer;

		update_cost(0,1);

		//exit(0);
	}

	float p(int atom,float value,object r,multiset ids)/*{{{*/
	{
		array dr=delta_data->dynamic_range(r,ids);
		return(atom*dr->avgval[0]+value);
	}/*}}}*/

	array atom_value(int i,object r,multiset ids)
	{
		Candle.Item item=line->a[i];
		return ({(int)(p(i,item->closeval,r,ids)*multer)});
	}
}/*}}}*/

class SecurityDeltaData{/*{{{*/
	inherit SecurityData;
	void create(object _line/*mapping inst2lines,int interval*/,int _multer)
	{
		line=_line;
		multer=_multer;

		update_cost(0,1);

		//exit(0);
	}
	array atom_value(int i,object r,multiset ids)
	{
		Candle.Item item=line->a[i];
		float beginval;
		if(i>0)
			beginval=line->a[i-1]->closeval;
		else
			beginval=item->openval;
		float maxdelta=item->maxval-beginval;
		float mindelta=item->minval-beginval;
		float closedelta=item->closeval-beginval;
		return ({(int)(closedelta*multer)});
	}
}/*}}}*/

	class LineSegSpliter(object data,int beginpos,int endpos)/*{{{*/
	{
		inherit Tool;
		array left=({});
		array right=({});
		DynamicRange dynamic_range_onedim(object data,int pos)
		{
			array a=data->atom_value(pos,0,0);
			return DynamicRange(a,a,map(a,Cast.floatfy));
		}
		DynamicRange dynamic_range_onedim_add(DynamicRange old,int oldcount,object data,int pos)
		{
			array val=data->atom_value(pos,0,0);
			array res_minval=min(old->minval[*],val[*]);
			array res_maxval=max(old->maxval[*],val[*]);
			array res_avgval=map(map(old->avgval,`*,oldcount)[*]+val[*],`/,oldcount+1);
			return DynamicRange(res_minval,res_maxval,res_avgval);
		}
		void create()
		{
			left=({dynamic_range_onedim(data,beginpos)});
			for(int i=beginpos+1;i<endpos;i++){
				left+=({dynamic_range_onedim_add(left[-1],sizeof(left),data,i)});
			}
			right=({dynamic_range_onedim(data,endpos-1)});
			for(int i=endpos-2;i>=beginpos;i--){
				right+=({dynamic_range_onedim_add(right[-1],sizeof(right),data,i)});
			}
		}
		void expand_left()
		{
			beginpos--;
			right+=({dynamic_range_onedim_add(right[-1],sizeof(right),data,beginpos)});
			for(int i=0;i<sizeof(left);i++){
				left[i]=dynamic_range_onedim_add(left[i],i+1,data,beginpos);
			}
			left=({dynamic_range_onedim(data,beginpos)})+left;
		}
		void expand_right()
		{
			int pos=endpos;
			endpos++;
			left+=({dynamic_range_onedim_add(left[-1],sizeof(left),data,pos)});
			for(int i=0;i<sizeof(right);i++){
				right[i]=dynamic_range_onedim_add(right[i],i+1,data,pos);
			}
			right=({dynamic_range_onedim(data,pos)})+right;
		}
		array split(object reducer,object r,LineSegNode node)
		{
			if(node->beginpos==beginpos&&node->endpos==endpos){
				float cost=data->cost();
				float ep0=reducer->entropy_from_dynamic_range(left[-1],data->weight,endpos-beginpos,cost)->explan_power();
				if(r){
					float ep01=reducer->entropy_from_dynamic_range(data->dynamic_range(r,(<r->find(node)>)),data->weight,endpos-beginpos,cost)->explan_power();
					assert(ep0==ep01,lambda(){
								//werror("%O %O\n",left[-1]->save(),data->dynamic_range(r,(<r->find(node)>),1)->save());
								//werror("%f %f %d %d %d %d\n",ep0,ep01,beginpos,endpos,node->beginpos,node->endpos);
								//werror("%d %d\n",beginpos,endpos);
								//for(int i=beginpos;i<endpos;i++){
									//werror("%d=%O\n",i,data->atom_value(i));
								//}

							});
				}
				array delta_list=({});
				array result_list=({});
				for(int i=0;i<endpos-beginpos-1;i++){
					object dr1,dr2;
					dr1=left[i];
					dr2=right[-2-i];
					object info1=reducer->entropy_from_dynamic_range(dr1,data->weight,i+1,cost);
					object info2=reducer->entropy_from_dynamic_range(dr2,data->weight,(endpos-beginpos)-(i+1),cost);
					if(info1->explan_power()+info2->explan_power()>ep0){
						delta_list+=({info1->explan_power()+info2->explan_power()-ep0});
						result_list+=({({LineSegNode(beginpos,beginpos+i+1),LineSegNode(beginpos+i+1,endpos),info1,info2})});
					}
				}
				sort(delta_list,result_list);
				if(sizeof(result_list)){
					write("split at %d\n",result_list[-1][0]->endpos);
					return result_list[-1];
				}else{
					return ({0,0,0,0});
				}
			}else{
				return ({0,0,0,0});
			}
		}
	}/*}}}*/
class LineSegSpliterHandler(object data){
	object last;
	array split(object reducer,object r,LineSegNode node)
	{
		object spliter;
		if(last&&last->beginpos==node->beginpos&&last->endpos==node->endpos-1){
			last->expand_right();
			spliter=last;
		}else{
			last=spliter=LineSegSpliter(data,node->beginpos,node->endpos);
		}
		return spliter->split(reducer,r,node);
	}
}

class SecurityRelationMap(object(SecurityData) data){
	inherit ArrayRelationMap;

	int table_size(){return 0;}

	object clone()/*{{{*/
	{
		object res=SecurityRelationMap(data);
		res->a=copy_value(a);
		res->listeners=copy_value(listeners);
		return res;
	}/*}}}*/
	int count(multiset ids)/*{{{*/
	{
		int res;
		foreach(ids;int id;int one){
			object node=a[id];
			if(node)
				res+=node->size();
		}
		return res;
	}/*}}}*/
	multiset query_nearby(int pos)/*{{{*/
	{
		multiset res=(<>);
		PROFILING_BEGIN("query_nearby")
		object node=a[pos];
		if(node){
			for(int i=0;i<sizeof(a);i++){
				if(i!=pos&&a[i]&&(a[i]->beginpos==node->endpos||a[i]->endpos==node->beginpos)){
					res[i]=1;
				}
			}
		}
		PROFILING_END
		//werror("nearby size=%d\n",sizeof(res));
		return res;
	}/*}}}*/
	int find_node(int atom)/*{{{*/
	{
		foreach(a;int pos;object node)
		{
			if(node&&node->beginpos<=atom&&node->endpos>atom){
				return pos;
			}
		}
	}/*}}}*/

	array split(int pos)/*{{{*/
	{
		array res=({});
		object node=a[pos];
		if(node&&node->endpos-node->beginpos>1){
			for(int i=node->beginpos;i+1<node->endpos;i++){
				object older=LineSegNode(node->beginpos,i+1);
				object rest=LineSegNode(i+1,node->endpos);
				res+=({({older,rest})});
			}
		}
		return res;
	}/*}}}*/
}

// beginpos <= aware_beginpos < endpos <= aware_endpos
class Concept(
		string inst,
		int interval,
		int beginpos,
		int aware_beginpos,
		int endpos,
		int aware_endpos
){
		inherit Save.Save;
}

array save_concept(object concept)
{
	return ({concept->inst,concept->interval,concept->beginpos,concept->aware_beginpos,concept->endpos,concept->aware_endpos});
}

object load_concept(array a)
{
	return Concept(@a);
}

#include <args.h>
int test_spliter_main(int argc,array argv)
{
	array a=({});
	for(int i=0;i<10000;i++){
		a+=({Save.load(Candle.Item(i*3600),([
						 "timeval":i*3600,
						 "minval":i*2*(i/5000),
						 "maxval":i*2*(i/5000),
						 "openval":i*2*(i/5000),
						 "closeval":i*2*(i/5000),
						 "volume":100,
						 ])
					)
					});
	}
	object line=Candle.line(3600);
	line->a=a;
	object data=SecurityDeltaData(line,1);
	object spliter=LineSegSpliter(data,1,9999);
	object reducer=OneDimReduceWithSpliter();
	reducer->data_list=({data});
	[object older,object rest,object info1,object info2]=spliter->split(reducer,0,LineSegNode(1,9999));
	werror("%d %d\n",older->beginpos,older->endpos);
}

object coprime;//=Choose.Coprime(256,(int)pow(2.0,LEVELLIMIT));

constant X_MIN=0;
constant X_MAX=255;
constant DX_MIN=X_MIN-X_MAX;
constant DX_MAX=X_MAX-X_MIN;
constant D2X_MIN=DX_MIN-DX_MAX;
constant D2X_MAX=DX_MAX-DX_MIN;
#define IDX (Math.log2(DX_MAX-DX_MIN+1.0)*3)
#define ID2X (Math.log2(D2X_MAX-D2X_MIN+1.0)*3)

#define ICOLOR (Math.log2(X_MAX-X_MIN+1.0)*3)
#define IFLOAT 64
#define IINT 64

object MDX(object mask)/*{{{*/
{
	return mask->copy(0,0,mask->xsize()-2,mask->ysize()-1)
		&(mask->copy(1,0,mask->xsize()-1,mask->ysize()-1));
}/*}}}*/
object MDY(object mask)/*{{{*/
{
	return mask->copy(0,0,mask->xsize()-1,mask->ysize()-2)
		&(mask->copy(0,1,mask->xsize()-1,mask->ysize()-1));
}/*}}}*/
object CUTX(object image,int n)/*{{{*/
{
	return image->copy(n,0,image->xsize()-1-n,image->ysize()-1);
}/*}}}*/
object CUTY(object image,int n)/*{{{*/
{
	return image->copy(0,n,image->xsize()-1,image->ysize()-1-n);
}/*}}}*/
object DX(object image,int|void flag_add)/*{{{*/
{
	if(image->xsize()<2){
		throw(({"too small.\n",backtrace()}));
	}
	object t=.ImageInteger.ImageInteger(image->xsize()-1,image->ysize())+image->copy(0,0,image->xsize()-2,image->ysize()-1);
	if(!flag_add)
		t=t-image->copy(1,0,image->xsize()-1,image->ysize()-1);
	else
		t=t+image->copy(1,0,image->xsize()-1,image->ysize()-1);
	return t;
}/*}}}*/
object DY(object image,int|void flag_add)/*{{{*/
{
	if(image->ysize()<2){
		throw(({"too small.\n",backtrace()}));
	}
	object t=.ImageInteger.ImageInteger(image->xsize(),image->ysize()-1)+image->copy(0,0,image->xsize()-1,image->ysize()-2);
	if(!flag_add)
		t=t-image->copy(0,1,image->xsize()-1,image->ysize()-1);
	else
		t=t+image->copy(0,1,image->xsize()-1,image->ysize()-1);
	return t;
}/*}}}*/

object create_coord(int w,int h)/*{{{*/
{
	object res=.ImageInteger.ImageInteger(w,h);
	for(int i=0;i<w;i++){
		for(int j=0;j<h;j++){
			res->setpixel(i,j,i,j,0);
		}
	}
	return res;
}/*}}}*/

mapping prepare_pixeldata(string target,int levellimit,int test_tuned_box_flag,int scale_flag,array|void files)/*{{{*/
{
	array images;
	array file_datas=({});
	if(files){
		images=map(files,lambda(string target){
#ifdef USING_LEVELLIMIT
				return Image.BMP.decode(Stdio.read_file(target))->scale((int)pow(2,levellimit),(int)pow(2,levellimit));
#else
				object res=Image.BMP.decode(Stdio.read_file(target));
				float factor=pow(2.0,levellimit)/max(res->xsize(),res->ysize());
				if(factor<1.0)
					return res->scale((int)(res->xsize()*factor),(int)(res->ysize()*factor));
				else
					return res;
#endif
				});
		int layer=0;
		file_datas=map(images,lambda(object image){
				return PixelData(.ImageInteger.ImageInteger(image->xsize(),image->ysize())+image)->set_layer(layer++);});
	}
object image0=Image.BMP.decode(Stdio.read_file(target));
#ifdef USING_LEVELLIMIT
image0=image0->scale((int)pow(2,levellimit)+2,(int)pow(2,levellimit)+2);
#else
float factor=pow(2.0,levellimit)/max(image0->xsize(),image0->ysize());
werror("factor=%f\n",factor);
werror("new xsize=%d\n",(int)(image0->xsize()*factor));
werror("new ysize=%d\n",(int)(image0->ysize()*factor));
if(factor<1.0)
	image0=image0->scale((int)(image0->xsize()*factor)+2,(int)(image0->ysize()*factor)+2);
#endif
if(test_tuned_box_flag){
	image0=image0->tuned_box(image0->xsize()/3,image0->ysize()/3,image0->xsize()*2/3,image0->ysize()*2/3,({({254,0,0}),({253,0,0}),({253,0,0}),({252,0,0})}));
}
if(scale_flag){
	image0=image0->scale(1.1,1.1)->copy(0,0,image0->xsize()-1,image0->ysize()-1);
}

object image=image0->copy(1,1,image0->xsize()-2,image0->ysize()-2);

object coord=PixelData(create_coord(image->xsize(),image->ysize()))->set_cost(Math.log2(0.0+image->xsize())+Math.log2(0.0+image->ysize()))->set_key("coord");

array multi=({});
for(int i=0;i<3;i++){
	for(int j=0;j<3;j++){
		object t=PixelData(.ImageInteger.ImageInteger(image->xsize(),image->ysize())+image0->copy(i,j,i+image->xsize()-1,j+image->ysize()-1))
			->set_key("color"+i+j)->set_cost(ICOLOR*2);
		multi+=({t});
	}
}

object d0=PixelData(.ImageInteger.ImageInteger(image->xsize(),image->ysize())+image)
->set_key("color")->set_cost(ICOLOR*2);
object dd=.ImageInteger.ImageInteger(image0->xsize(),image0->ysize())+image0;
object dx=DX(dd);object dy=DY(dd);

object dx_left=PixelData(CUTY(dx->copy(0,0,dx->xsize()-2,dx->ysize()-1),1))->set_key("dx_left")->set_cost(IDX*2);
object dx_right=PixelData(CUTY(dx->copy(1,0,dx->xsize()-1,dx->ysize()-1),1))->set_key("dx_right")->set_cost(IDX*2);
object dy_up=PixelData(CUTX(dy->copy(0,0,dy->xsize()-1,dy->ysize()-2),1))->set_key("dy_up")->set_cost(IDX*2);
object dy_down=PixelData(CUTX(dy->copy(0,1,dy->xsize()-1,dy->ysize()-1),1))->set_key("dy_down")->set_cost(IDX*2);

object d1x=PixelData(CUTY(DX(dx,1),1))->set_key("d1x")->set_cost(IDX*2); 
object d1y=PixelData(CUTX(DY(dy,1),1))->set_key("d1y")->set_cost(IDX*2);
for(int i=0;i<image->xsize();i++){
	for(int j=0;j<image->ysize();j++){
		d1x->data->setpixel(i,j,@map(d1x->data->getpixel(i,j),`/,2));
		d1y->data->setpixel(i,j,@map(d1y->data->getpixel(i,j),`/,2));
	}
}

object d2x=PixelData(CUTY(DX(dx),1))->set_key("d2x")->set_cost(ID2X*2);
object d2y=PixelData(CUTX(DY(dy),1))->set_key("d2y")->set_cost(ID2X*2);
//object dxdy=PixelData(DY(DY(DX(dx)),1))->set_key("dxdy")->set_cost(ID2X*2);
//object dydx=PixelData(DX(DX(DY(dy)),1))->set_key("dydx")->set_cost(ID2X*2);

return (["image":image,"d0":d0,"dx_left":dx_left,"dx_right":dx_right,"dy_up":dy_up,"dy_down":dy_down,"d1x":d1x,"d1y":d1y,"multi":multi,"d2x":d2x,"d2y":d2y,"images":images,"files":file_datas,"coord":coord]);
}/*}}}*/

object create_output_image(object image,object r,string k,int layer)/*{{{*/
{
	int w=1024;
	int h=1024;
	object p;
	if(arrayp(r[k]))
		p=r[k][layer]->scale(w,h);
	else
		p=r[k]->scale(w,h);
	foreach(r->a;int pos;object cell){
		if(cell){
			array color=r->id2color(pos);
			p=p->outline(255,0,0,@color);
			p=p->outline(0,255,0,@color);
		}
	}

	object large=image->scale(w,h);
	foreach(r->a;int pos;object cell){
		if(cell){
			array a=Tool()->cellgroup_mask(r,(<pos>));
			object mask=a[layer];

			mask=mask->scale(w,h);
			mask=mask->outline(0,0,0,255,255,255);
			mask=mask->outline(0,0,0,255,255,255);

			p->paste_mask(large,mask);
		}
	}
	w=1024*4;h=1024*4;
	p=p->scale(w,h);

	object ft=Image.Font();

#ifdef DUMP_PIXEL
	for(int i=0;i<image->xsize();i++){
		for(int j=0;j<image->ysize();j++){
			p->paste(ft->write(sprintf("%03d%03d",i,j)),i*w/image->xsize(),j*h/image->ysize());
			p->paste(ft->write(sprintf("%03d%03d%03d",@image->getpixel(i,j))),i*w/image->xsize(),j*h/image->ysize()+10);
		}
	}
	/*
	foreach(pixel_relations->a;int pos;object cell){
		if(cell){
			[float i1,mapping entropy_info]=cellgroup_entropy_perpixel_plain(pixel_relations,(<pos>));
			for(int i=0;i<image->xsize();i++){
				for(int j=0;j<image->ysize();j++){
					if(pixel_relations->color2id(pixel_relations->image->getpixel(i,j))==pos){
						p->paste(ft->write(sprintf("%f",i1)),i*w/image->xsize(),j*h/image->ysize()+20);
					}
				}
			}
		}
	}
	*/
#endif
	foreach(r->a;int pos;object cell){
		if(cell){
			object info=cell->info;
			for(int i=0;i<image->xsize();i++){
				for(int j=0;j<image->ysize();j++){
					mixed t=r[k];
					if(arrayp(t)) t=t[layer];
					if(r->color2id(t->getpixel(i,j))==pos){
#ifdef DUMP_ID
//p->paste(ft->write(sprintf("%03d%03d%03d",@image->getpixel(i,j))),i*w/image->xsize(),j*h/image->ysize()+10);
p->paste(ft->write(sprintf("%d",pos)),i*w/image->xsize(),j*h/image->ysize()+20);
#endif
//p->paste(ft->write(sprintf("%d",cell->ph)),i*w/image->xsize(),j*h/image->ysize()+30);
					}
				}
			}
		}
	}

return p;
}/*}}}*/
object create_output_image2(object image,object r,string k,int layer)/*{{{*/
{
	int w=1024;
	int h=1024;
	object p=image->bitscale(w,h);
	foreach(r->a;int pos;object cell){
		if(cell){
			[object mask]=r->query_mask(pos);
			mask=mask->bitscale(w,h);
			mask=mask->outline(255,0,0,255,255,255);
			mask=mask->outline(0,255,0,255,255,255);
			mask=mask->change_color(255,255,255,0,0,0);
			p=p->paste_mask(mask,mask->change_color(255,0,0,255,255,255)->change_color(0,255,0,255,255,255));
		}
	}

	/*object large=image->scale(w,h);
	foreach(r->a;int pos;object cell){
		if(cell){
			array a=Tool()->cellgroup_mask(r,(<pos>));
			object mask=a[layer];

			mask=mask->bitscale(w,h);
			mask=mask->outline(0,0,0,255,255,255);
			mask=mask->outline(0,0,0,255,255,255);

			p->paste_mask(large,mask);
		}
	}*/
	w=1024*4;h=1024*4;
	p=p->scale(w,h);

	object ft=Image.Font();

#ifdef DUMP_PIXEL
	for(int i=0;i<image->xsize();i++){
		for(int j=0;j<image->ysize();j++){
			p->paste(ft->write(sprintf("%03d%03d",i,j)),i*w/image->xsize(),j*h/image->ysize());
			p->paste(ft->write(sprintf("%03d%03d%03d",@image->getpixel(i,j))),i*w/image->xsize(),j*h/image->ysize()+10);
		}
	}
	/*
	foreach(pixel_relations->a;int pos;object cell){
		if(cell){
			[float i1,mapping entropy_info]=cellgroup_entropy_perpixel_plain(pixel_relations,(<pos>));
			for(int i=0;i<image->xsize();i++){
				for(int j=0;j<image->ysize();j++){
					if(pixel_relations->color2id(pixel_relations->image->getpixel(i,j))==pos){
						p->paste(ft->write(sprintf("%f",i1)),i*w/image->xsize(),j*h/image->ysize()+20);
					}
				}
			}
		}
	}
	*/
#endif
#ifdef DUMP_ID
	for(int i=0;i<image->xsize();i++){
		for(int j=0;j<image->ysize();j++){
			mixed t=r[k];
			if(arrayp(t)) t=t[layer];
			multiset m=r->color2ids(t->getpixel(i,j));
			if(sizeof(m)){
				p->paste(ft->write(sprintf("%s",map((array)m,Cast.stringfy)*",")),i*w/image->xsize(),j*h/image->ysize()+20);
			}else{
				p->paste(ft->write(sprintf("%s","?")),i*w/image->xsize(),j*h/image->ysize()+20);
			}
#ifdef DUMP_PLANE
			if(sizeof(m)==1){
				foreach(m;int id;int one){
					object node=r->a[id];
					array dxval=node->info->dxval||({0.0,0.0,0.0});
					array dyval=node->info->dyval||({0.0,0.0,0.0});
					//werror("%O %O",dxval,dyval);
					p->paste(ft->write(sprintf("%0.3f,%0.3f,%0.3f",@dxval)),i*w/image->xsize(),j*h/image->ysize()+30);
					p->paste(ft->write(sprintf("%0.3f,%0.3f,%0.3f",@dyval)),i*w/image->xsize(),j*h/image->ysize()+40);

				}
			}
#endif
		}
	}
#endif

return p;
}/*}}}*/
void output_image(string file,object image,object r,string k,int layer)/*{{{*/
{
	object ob=create_output_image(image,r,k,layer);
	mkdir("output");
	Stdio.write_file(sprintf("output/%s.png",file),Image.PNG.encode(ob));
}/*}}}*/
void output_image2(string file,object image,object r,string k,int layer)/*{{{*/
{
	object ob=create_output_image2(image,r,k,layer);
	mkdir("output");
	Stdio.write_file(sprintf("output/%s.png",file),Image.PNG.encode(ob));
}/*}}}*/
void output_result_text(string file,object r)
{
	string res="";
	mapping data=([]);
	for(int i=0;i<sizeof(r->a);i++){
		if(r->a[i]!=0){
			object cell=r->a[i];
			res+=sprintf("%d: ",i);
			foreach(cell->info->minval+cell->info->maxval,int v){
				res+=sprintf("%d ",v);
			}
			res+="\n";
		}
	}
	Stdio.write_file(sprintf("output/%s.result.txt",file),res);
}
void output_result(string file,object r)/*{{{*/
{
	mapping data=([]);
	for(int i=0;i<sizeof(r->a);i++){
		if(r->a[i]!=0){
			object cell=r->a[i];
			
			data[i]=(["paths":r->query_nearby(i),
					"info":cell->info->save(),
					"cell":cell->query_selected(),
					//"range":cell->range(),
					]);
		}
	}
	Stdio.write_file(sprintf("output/%s.result",file),encode_value(data));
}/*}}}*/
#if 0
void output_dumpdata(string file,object r)/*{{{*/
{
	mapping data=([]);
	for(int i=0;i<sizeof(r->a);i++){
		if(r->a[i]!=0){
			object cell=r->a[i];
			data[i]=cell->query_selected();
		}
	}
	Stdio.write_file(sprintf("output/%s.dump",file),encode_value(data));
}/*}}}*/
#endif

object create_image_relation_map(object image,int levellimit)/*{{{*/
{
	int w=image->xsize();
	int h=image->ysize();
	object r=PixelRelationMap(w,h);
	werror("create cells ...\n");
	PROFILING_BEGIN("create_cells")
	for(int i=0;i<w;i++){
		for(int j=0;j<h;j++){
#ifdef USING_LEVELLIMIT
			object cell=PixelNode(levellimit,1,image->xsize(),image->ysize());
			cell->select(levellimit,i,j);
#else
			object cell=PixelNode(1,1,image->xsize(),image->ysize());
			cell->select(0,i,j);
#endif
			r->add(cell);
			//analyze->feed(cell);
		}
	}
	PROFILING_END
	werror("create cells OK\n");
	return r;

}/*}}}*/
object create_fast_reducer(object r,array data_list)/*{{{*/
{
	object reducer=FastReduce(/*r,data_list,using_models_or_add==1,using_models_or_add==2,models||({}),init_data*/);
	reducer->data_list=data_list;
	reducer->r=r;
	return reducer;
}/*}}}*/
object create_plane_reduce(object r,array arouse_data_list,object d0,object dx_left,object dy_up)/*{{{*/
{
	object reducer=PlaneReduce();
	reducer->PixelData=PixelData;
	reducer->target=d0;
	reducer->dx_left=dx_left;
	reducer->dy_up=dy_up;
	reducer->arouse_data_list=arouse_data_list;
	reducer->r=r;
	reducer->using_dynamic_colorrange_cost=1; //和set_cost有关，必须为1
	reducer->using_dynamic_dxdy_precision_cost=1; //和set_cost有关，必须为1
	reducer->using_edge_entropy=0;
	return reducer;
}/*}}}*/
object do_feed(object reducer)/*{{{*/
{
	object r=reducer->r;
	foreach(r->a;int pos;object cell)
	{
		if(cell){
			mixed e=catch{
				reducer->feed(cell);
				werror("feed %d done\n",pos);
			};
			if(e){
				werror("%O\n",cell->query_selected());
				throw(e);
			}
		}
	}
	return reducer;
}/*}}}*/

object create_edge_relation_map(object image,int levellimit)/*{{{*/
{
	int w=image->xsize();
	int h=image->ysize();
	object r=PixelEdgeRelationMap(w,h);
	werror("create cells ...\n");
	PROFILING_BEGIN("create_cells")
	for(int i=0;i<w;i++){
		for(int j=0;j<h;j++){
			object cell;
			if(i+1<w){
				cell=PixelNode(1,1,image->xsize(),image->ysize());
				cell->select(0,i,j);
				cell->select(0,i+1,j);
				r->add(cell);
			}
			if(j+1<h){
				cell=PixelNode(1,1,image->xsize(),image->ysize());
				cell->select(0,i,j);
				cell->select(0,i,j+1);
				r->add(cell);
			}
		}
	}
	PROFILING_END
	werror("create cells OK\n");
	werror("r->size()=%d\n",r->size());
	return r;

}/*}}}*/

object finish_reduce(object reducer)/*{{{*/
{
	reducer->advance();

	float sum;
	int count;
#ifdef COMPAREARRAY_ENTROPY
	foreach(reducer->node2entropy;object cell;object entropy){
		sum+=entropy->a[0];
		count++;
	}
#else
	foreach(reducer->node2entropy;object cell;float entropy){
		sum+=entropy;
		count++;
	}
#endif

	werror("final explan power=%f count=%d\n",sum,count);
	return reducer;
}/*}}}*/

int parse_image_main(int argc,array argv)
{
	mapping args=Arg.parse(argv);
	array rest=args[Arg.REST];

	DECLARE_ARGUMENT_STRING("mode",mode_flag,mode_str,"=D1X|D1Y|DX|DY|RGB|MOVE|MERGE|EDGE\tDefault is RGB.");
	DECLARE_ARGUMENT_FLAG("test-tuned-box",test_tuned_box_flag,"");
	DECLARE_ARGUMENT_FLAG("scale",scale_flag,"");

	if(Usage.usage(args,"FILE LEVEL",2))
		return 0;

	HANDLE_ARGUMENTS();

	string target=rest[0];
	int levellimit=(int)(rest[1]);

	signal(signum("SIGINT"),lambda(){ master()->handle_error(({"sigint",backtrace()}));exit(0);});

	coprime=Choose.Coprime(256,(int)pow(2.0,levellimit));

	mode_str=upper_case(mode_str);
	mapping all=prepare_pixeldata(target,levellimit,test_tuned_box_flag,scale_flag);

	if(mode_str=="D1X"){
		all->d1x->update_cost();
		object reducer=finish_reduce(do_feed(create_fast_reducer(create_image_relation_map(all->image,levellimit),({all->d1x}))));
		//output_dumpdata(target+"-dx",reducer->r);
		output_result(target+"-d1x",reducer->r);
		output_result_text(target+"-d1x",reducer->r);
		output_image(target+"-d1x",all->image,reducer->r,"image",0);
	}else if(mode_str=="D1Y"){
		all->d1y->update_cost();
		//object reducer=parse_image("dy",all->image,({all->dy_up}),levellimit);
		object reducer=finish_reduce(do_feed(create_fast_reducer(create_image_relation_map(all->image,levellimit),({all->d1y}))));
		//output_dumpdata(target+"-dy",reducer->r);
		output_result(target+"-d1y",reducer->r);
		output_image(target+"-d1y",all->image,reducer->r,"image",0);
	}else if(mode_str=="PLANES"){
		all->d1x->update_cost();
		all->d1y->update_cost();
		all->d0->update_cost();

		array data_list=prepare_planes_data(target,all);
		map(data_list,"update_cost");

		object reducer=finish_reduce(do_feed(create_fast_reducer(create_image_relation_map(all->image,levellimit),data_list)));
		//output_dumpdata(target+"-dy",reducer->r);
		output_result(target+"-planes",reducer->r);
		output_image(target+"-planes",all->image,reducer->r,"image",0);

	}else if(mode_str=="DX"){
		all->dx_left->update_cost();
		object reducer=finish_reduce(do_feed(create_fast_reducer(create_image_relation_map(all->image,levellimit),({all->dx_left}))));
		//output_dumpdata(target+"-dx",reducer->r);
		output_result(target+"-dx",reducer->r);
		output_result_text(target+"-dx",reducer->r);
		output_image(target+"-dx",all->image,reducer->r,"image",0);
	}else if(mode_str=="DY"){
		all->dy_up->update_cost();
		//object reducer=parse_image("dy",all->image,({all->dy_up}),levellimit);
		object reducer=finish_reduce(do_feed(create_fast_reducer(create_image_relation_map(all->image,levellimit),({all->dy_up}))));
		//output_dumpdata(target+"-dy",reducer->r);
		output_result(target+"-dy",reducer->r);
		output_image(target+"-dy",all->image,reducer->r,"image",0);
	}else if(mode_str=="RGB"||mode_str==0){
		all->d0->update_cost();
		//object reducer=parse_image("image",all->image,({all->d0}),levellimit);
		object reducer=finish_reduce(do_feed(create_fast_reducer(create_image_relation_map(all->image,levellimit),({all->d0}))));
		//output_dumpdata(target+"-rgb",reducer->r);
		output_result(target+"-rgb",reducer->r);
		output_image(target+"-rgb",all->image,reducer->r,"image",0);
	}else if(mode_str=="MOVE"){
		all->dx_left->update_cost();
		all->dy_up->update_cost();
		all->d0->update_cost();

		[object rf,object dxf,object dyf]=prepare_triple_data(target,all);

		triple_reduce(all->d0,rf,dxf,dyf,0);

		//output_dumpdata(target+"-triple",reducer->r);
		output_result(target+"-triple-rgb",rf->r);
		output_result(target+"-triple-dx",dxf->r);
		output_result(target+"-triple-dy",dyf->r);

		output_image(target+"-triple-rgb",all->image,rf->r,"image",0);
		output_image(target+"-triple-dx",all->image,dxf->r,"image",0);
		output_image(target+"-triple-dy",all->image,dyf->r,"image",0);

	}else if(mode_str=="MERGE"){
		all->dx_left->update_cost();
		all->dy_up->update_cost();
		all->d0->update_cost();

		[object rf,object dxf,object dyf]=prepare_triple_data(target+"-triple",all);

		triple_reduce(all->d0,rf,dxf,dyf,1);

		output_result(target+"-triple2-rgb",rf->r);
		output_result(target+"-triple2-dx",dxf->r);
		output_result(target+"-triple2-dy",dyf->r);

		output_image(target+"-triple2-rgb",all->image,rf->r,"image",0);
		output_image(target+"-triple2-dx",all->image,dxf->r,"image",0);
		output_image(target+"-triple2-dy",all->image,dyf->r,"image",0);
	}else if(mode_str=="EDGE"){
		//all->d0->update_cost();
		[object d0,object dx_left,object dx_right,object dy_up,object dy_down]=({all->d0,all->dx_left,all->dx_right,all->dy_up,all->dy_down});
		dx_left->set_cost(0); dx_right->set_cost(0); dy_up->set_cost(0); dy_down->set_cost(0);
		//d0->set_cost(ICOLOR+12*3*2);//XXX: why
		object gr=d0->global_range();
		float icolor=gr->atom_entropy();
		werror("icolor=%O\n",icolor);
		d0->set_cost(/*icolor+*/
				(icolor+3+(/*Math.log2(0.0+d0->data->xsize())+*/1)*3)+
				(icolor+3+(/*Math.log2(0.0+d0->data->ysize())+*/1)*3)); 
		//本来应该是 ICOLOR*2+IDX+IDY 但所有边界都被两边解释，意味着全局只需要一个ICOLOR来表示基准值，每个聚合类需要一个ICOLOR来表示范围，dx,dy用分数表示，分子熵为icolor+3，3为符号位；分母熵为(Math.log2(WIDIT_OR_HEIGHT)+1)*3，理由如下：如果dx,dy的精度精细到跨越整个图像范围也不改变0.5个点的值，那么dx,dy叠加考虑，跨越整个图像范围，也不会改变1个点的值，精细到超过这个程度就没有意义，因此最大的精细度是1/WIDIT_OR_HEIGHT/2，所以小数点以后的位数的熵为ln(WIDIT_OR_HEIGHT)+1，小数点以前的熵是ICOLOR/3，因为ICOLOR是三色总计，再加上一个符号位，然后总体乘3。
		//使用using_dynamic_colorrange_cost，表示范围的icolor会动态计算
		//使用using_dynamic_dxdy_precision_cost，上述依赖于色块宽度高度的小数部分会动态计算。
		d0->set_weight(1);
		//连续观察，静态当作动态
		object reducer=finish_reduce(do_feed(create_plane_reduce(create_edge_relation_map(all->image,levellimit),({/*dx_left,dy_up,dx_right,dy_down*/}),d0,dx_left,dy_up)));
		output_result(target+"-edge",reducer->r);
		output_image2(target+"-edge",all->image,reducer->r,"image",0);
	}
}
array prepare_triple_data(string target,mapping all)/*{{{*/
{
		int w,h;
		w=all->d0->data->xsize(); h=all->d0->data->ysize();
		object rr=PixelRelationMap(w,h)->load(decode_value(Stdio.read_file("output/"+target+"-rgb.result")));
		object rf=do_feed(create_fast_reducer(rr,({all->d0})));
		w=all->dx_left->data->xsize(); h=all->dx_left->data->ysize();
		object dxr=PixelRelationMap(w,h)->load(decode_value(Stdio.read_file("output/"+target+"-dx.result")));
		object dxf=do_feed(create_fast_reducer(dxr,({all->dx_left})));
		w=all->dy_up->data->xsize(); h=all->dy_up->data->ysize();
		object dyr=PixelRelationMap(w,h)->load(decode_value(Stdio.read_file("output/"+target+"-dy.result")));
		object dyf=do_feed(create_fast_reducer(dyr,({all->dy_up})));

		return ({rf,dxf,dyf});
}/*}}}*/

array prepare_planes_data(string target,mapping all)/*{{{*/
{
		int w,h;

		w=all->d1x->data->xsize(); h=all->d1x->data->ysize();
		object dxr=PixelRelationMap(w,h)->load(decode_value(Stdio.read_file("output/"+target+"-d1x.result")));
		object dxf=do_feed(create_fast_reducer(dxr,({all->d1x})));
		w=all->d1y->data->xsize(); h=all->d1y->data->ysize();
		object dyr=PixelRelationMap(w,h)->load(decode_value(Stdio.read_file("output/"+target+"-d1y.result")));
		object dyf=do_feed(create_fast_reducer(dyr,({all->d1y})));

		int id;

		id=0;
		array dxe=map(dxr->a,lambda(object ob){
				id++;
				if(ob){
					return dxf->entropy_of(dxf->query_data_list(),dxr,(<id-1>));
				}
				});

		id=0;
		array dye=map(dyr->a,lambda(object ob){
				id++;
				if(ob){
					return dyf->entropy_of(dyf->query_data_list(),dyr,(<id-1>));
				}
				});

		object d=all->d0->data->clone();
		for(int i=0;i<d->xsize();i++){
			for(int j=0;j<d->ysize();j++){
				array dx=dxe[dxr->find_node(({i,j}))]->avgval;
				array dy=dye[dyr->find_node(({i,j}))]->avgval;
				array a=d->getpixel(i,j);
				d->setpixel(i,j,
						(int)(a[0]-dx[0]*i-dy[0]*j),
						(int)(a[1]-dx[1]*i-dy[1]*j),
						(int)(a[2]-dx[2]*i-dy[2]*j),
						);
			}
		}

		return ({PixelData(d)->set_key("color")->set_cost(ICOLOR*2)});
}/*}}}*/
class Triple(/*{{{*/
	int x1,int y1,int x2,int y2,
	int from,int action,int to,
	){
	int key()
	{
		return (((from<<16)|action)<<16)|to;
	}
	int from_action_key()
	{
		return ((from<<16)|action);
	}
	int to_action_key()
	{
		return ((to<<16)|action);
	}
	int from_to_key()
	{
		return ((from<<16)|to);
	}
};/*}}}*/
class TripleAtom(object r,int x,int y){}
class CrossMergeInfo(int dx_id,int dy_id,int is_div,int n){} // dx=is_div ? (dy/n):(dy*n)
void triple_reduce(object rgb,object rf,object dxf,object dyf,int phase)/*{{{*/
{
	int count=(rgb->data->xsize()-1)*(rgb->data->ysize()-1)*2;

	object rr=rf->r;
	object dxr=dxf->r;
	object dyr=dyf->r;

	array cross_merges=({});

	object find_reducer(object r)/*{{{*/
	{
		if(r==rr)
			return rf;
		else if(r==dxr)
			return dxf;
		else if(r==dyr)
			return dyf;
	};/*}}}*/

	string find_relation_map_name(object|string r)/*{{{*/
	{
		if(stringp(r))
				return r;
		if(r==rr)
			return "rgb";
		else if(r==dxr)
			return "dx";
		else if(r==dyr)
			return "dy";
	};/*}}}*/

	int rr_size=rr->size();
	int dxr_size=dxr->size();
	int dyr_size=dyr->size();
	int cross_merge_size=sizeof(cross_merges);
	int multer_size=max(1,@map(cross_merges,`->,"n"));//sizeof(1..max)==max
	multiset keys;
	mapping path_multitarget;
	float e0;

	int build_triple_node(object|string r,int id)/*{{{*/
	{
		if(r==rr)
			return (id<<2)|0;
		else if(r==dxr)
			return (id<<2)|1;
		else if(r==dyr)
			return (id<<2)|2;
		else if(r=="cross")
			return (id<<2)|3;
		else 
			throw(({"unknown axis.\n",backtrace()}));
	};/*}}}*/
	array parse_triple_node(int triple_node)/*{{{*/
	{
		if((triple_node&3)==0){
			return ({rr,triple_node>>2});
		}else if((triple_node&3)==1){
			return ({dxr,triple_node>>2});
		}else if((triple_node&3)==2){
			return ({dyr,triple_node>>2});
		}else{
			return ({"cross",triple_node>>2});
		}
	};/*}}}*/

	int build_path(object triple,string target_key)/*{{{*/
	{
		if(target_key=="to"){
			return (triple->from_action_key()<<2)|1;
		}else if(target_key=="from"){
			return (triple->to_action_key()<<2)|2;
		}else if(target_key=="action"){
			return (triple->from_to_key()<<2)|0;
		}else{
			throw(({"unknown path type.\n",backtrace()}));
		}
	};/*}}}*/
	array parse_path(int path)/*{{{*/
	{
		if((path&3)==1){
			return ({"from_action_key","to"});
		}else if((path&3)==2){
			return ({"to_action_key","from"});
		}else if((path&3)==0){
			return ({"from_to_key","action"});
		}
	};/*}}}*/

	array replace_if_merged(int dx_node,int dy_node)
	{
		[object dxr1,int id1]=parse_triple_node(dx_node);
		[object dyr1,int id2]=parse_triple_node(dy_node);
		ASSERT(dxr1==dxr&&dyr1==dyr);
		foreach(cross_merges;int id;object info){
			if(info->dx_id==id1&&info->dy_id==id2){
				if(!info->is_div){
					return ({dy_node,dy_node});
				}else{
					return ({dx_node,dx_node});
				}
				//int res=build_triple_node("cross",id);
				//return ({res,res});
			}
		}
		return ({dx_node,dy_node});
	};


	array build_triples()/*{{{*/
	{
		multiset keys=(<>);
		mapping path_multitarget=([]);

		for(int i=0;i<rgb->data->xsize()-1;i++){
			for(int j=0;j<rgb->data->ysize()-1;j++){
				int this_node=build_triple_node(rr,rr->find_node(({i,j})));
				int right_node=build_triple_node(rr,rr->find_node(({i+1,j})));
				int down_node=build_triple_node(rr,rr->find_node(({i,j+1})));
				int right_action_node=build_triple_node(dxr,dxr->find_node(({i+1,j})));
				int down_action_node=build_triple_node(dyr,dyr->find_node(({i,j+1})));

				[right_action_node,down_action_node]=replace_if_merged(right_action_node,down_action_node);

				foreach(({Triple(i,j,i+1,j,this_node,right_action_node,right_node),
						Triple(i,j,i,j+1,this_node,down_action_node,down_node),
						}),object triple){

					int key;

					keys[triple->key()]=1;

					foreach(({({build_path(triple,"to"),triple->to}),
								({build_path(triple,"from"),triple->from}),
								({build_path(triple,"action"),triple->action})}),[key,int target]){
						path_multitarget[key]=path_multitarget[key]||([]);
						path_multitarget[key][target]=path_multitarget[key][target]||(<>);
						path_multitarget[key][target][triple]=1;
						//path_triples[key]=path_triples[key]||(<>);
						//path_triples[key][triple]=1;
					}
				}
			}
		}
		return ({keys,path_multitarget});
	};/*}}}*/
	float e(int rr_size,int dxr_size,int dyr_size,int key_size,int cross_merge_size,int mulper_size)/*{{{*/
	{
		float g=(Math.log2(0.0+rr_size)*2+Math.log2(0.0+dxr_size+dyr_size/*-cross_merge_size*/))*key_size+(Math.log2(0.0+dxr_size)+Math.log2(0.0+dyr_size)+1+Math.log2(0.0+mulper_size))*cross_merge_size; //不减 cross_merge_size 因为可能只是局部合并了
		return g+Math.log2(0.0+key_size)*count;
	};/*}}}*/

	multiset find_atoms(multiset triples,string key,int target)/*{{{*/
	{
		if(key=="from"){
			return map(triples,lambda(object triple){
					return TripleAtom(rr,triple->x1,triple->y1);
					});
		}else if(key=="to"){
			return map(triples,lambda(object triple){
					return TripleAtom(rr,triple->x2,triple->y2);
					});
		}else if(key=="action"){
			multiset res=(<>);
			foreach(triples;object triple;int one){
				[object|string r,int node]=parse_triple_node(triple[key]);
				if(!stringp(r)){
					res[TripleAtom(r,triple->x2,triple->y2)]=1;//dxr,dyr的数据是向左向上，所以用x2,y2来检索
				}else if(r=="cross"){
					res[TripleAtom(dxr,triple->x2,triple->y2)]=1;
					res[TripleAtom(dyr,triple->x2,triple->y2)]=1;
				}else{
					throw(({"unknown triple type.\n",backtrace()}));
				}
			}
			return res;
		}
	};/*}}}*/
	array if_move(multiset(TripleAtom) m,object r_from,int node_id_from,object r_to,int node_id_to){/*{{{*/
		ASSERT(r_from==r_to);
		object r=r_from;
		int rr_size1=rr_size,dxr_size1=dxr_size,dyr_size1=dyr_size,key_size1,cross_merge_size1=cross_merge_size,multer_size1=multer_size;float cost;
		array kij_list=({});
		foreach(m;TripleAtom atom;int one){
			ASSERT(atom->r==r);
			kij_list+=({({0,atom->x,atom->y})});
		}
		object f=find_reducer(r);
		[object r_res,array from_res0,array to_res0,array from_res,array to_res,multiset changed]=f->entropy_if_alter(r,node_id_from,node_id_to,kij_list);
		object|float ep0=from_res0[1]+to_res0[1];
		object|float ep1=from_res[1]+to_res[1];

		object|float delta_ep=ep0-ep1;
		if(objectp(delta_ep))
			delta_ep=delta_ep[0];

		cost=delta_ep;

		int count_from=from_res[2];
		int count_to=to_res[2];

		if(count_from==0){
			if(r==rr) rr_size1--; else if(r==dxr) dxr_size1--; else if(r==dyr) dyr_size1--;
		}
		object rr1=rr,dxr1=dxr,dyr1=dyr;
		if(r==rr) rr1=r_res; else if(r==dxr) dxr1=r_res; else if(r==dyr) dyr1=r_res;
		

		array backup=({rr,dxr,dyr});
		[rr,dxr,dyr]=({rr1,dxr1,dyr1});
		[multiset keys1,mapping path_multitarget1]=build_triples();
		[rr,dxr,dyr]=backup;
		

		//werror("sizeof(keys1)=%d\n",sizeof(keys1));

		key_size1=sizeof(keys1);

		return ({rr_size1,dxr_size1,dyr_size1,key_size1,cross_merge_size1,multer_size1,cost,([
					"rr":rr1,"dxr":dxr1,"dyr":dyr1,"changed":changed,
					"keys":keys1,"path_multitarget":path_multitarget1,
					"cross_merges":cross_merges,
					])});
	};/*}}}*/
	array if_merge(multiset(TripleAtom) m,object r_from,int node_id_from,object r_to,int node_id_to)
	{
		int rr_size1=rr_size,dxr_size1=dxr_size,dyr_size1=dyr_size,key_size1,cross_merge_size1=cross_merge_size,multer_size1;float cost;

		cost=0.0;

		array old_cross_merges=cross_merges;

		if(r_from==dxr&&r_to==dyr)
			cross_merges+=({CrossMergeInfo(node_id_from,node_id_to,0,1)});
		else if(r_from==dyr&&r_to==dxr)
			cross_merges+=({CrossMergeInfo(node_id_to,node_id_from,0,1)});
		else
			throw(({"unknown axis.\n",backtrace()}));

		foreach(cross_merges[..<1],object info){
			object curr=cross_merges[-1];
			if(info->dx_id==curr->dx_id&&info->dy_id==curr->dy_id){
				if(info->is_div==curr->is_div&&info->n==curr->n){
					cross_merges=cross_merges[..<1];
					break;
				}else{
					throw(({"cross merges not match.\n",backtrace()}));
				}
			}
		}


		//werror("t=%d\n",sizeof(cross_merges));

		cross_merge_size=sizeof(cross_merges);
		multer_size=max(1,@map(cross_merges,`->,"n"));//sizeof(1..max)==max

		cross_merge_size1=cross_merge_size;
		multer_size1=multer_size;

		[multiset keys1,mapping path_multitarget1]=build_triples();

		array cross_merges1=cross_merges;
		cross_merges=old_cross_merges;
		cross_merge_size=sizeof(cross_merges);
		multer_size=max(1,@map(cross_merges,`->,"n"));//sizeof(1..max)==max

		key_size1=sizeof(keys1);

		return ({rr_size1,dxr_size1,dyr_size1,key_size1,cross_merge_size1,multer_size1,cost,([
					"rr":rr,"dxr":dxr,"dyr":dyr,"changed":(<>),
					"keys":keys1,"path_multitarget":path_multitarget1,
					"cross_merges":cross_merges1,
					])});
	};

	void do_alter(multiset(TripleAtom) m,object r_from,int node_id_from,object r_to,int node_id_to,mapping extra){/*{{{*/
		if(r_from==r_to)
			werror("alter %d atoms in %s\n",sizeof(m),find_relation_map_name(r_from));
		else
			werror("merge\n");
		object f=find_reducer(r_from);
		rf->r=rr=extra->rr;
		dxf->r=dxr=extra->dxr;
		dyf->r=dyr=extra->dyr;
		if(sizeof(extra->changed)){
			f->update_entropy(extra->changed);
		}
		keys=extra->keys;
		path_multitarget=extra->path_multitarget;
		rr_size=rr->size();
		dxr_size=dxr->size();
		dyr_size=dyr->size();
		cross_merges=extra->cross_merges;
		cross_merge_size=sizeof(cross_merges);
		multer_size=max(1,@map(cross_merges,`->,"n"));//sizeof(1..max)==max
	};/*}}}*/

	[keys,path_multitarget]=build_triples();
	e0=e(rr_size,dxr_size,dyr_size,sizeof(keys),cross_merge_size,multer_size);

	//e 只与 r类数，dx类数数，dy类数，三元组数 有关
	//我们需要计算把一个现象从一个类移动到另一个类
	//我们需要计算合并任意两个r类，任意两个dx类，任意两个dy类，以及重点是：任意一个dx类和一个dy类
	//合并dx类和dy类到底有没有意义呢？有意义，在某个约束下，通过某个dx变化和某个dy变化总到达同一个地方，这是回路

	array delta_list;
	array result_list;
	//for(int phase=0;phase<=1;phase++){
		do{
			werror("rr_size=%d dxr_size=%d dyr_size=%d key_size=%d cross_merge_size=%d multer_size=%d\n",rr_size,dxr_size,dyr_size,sizeof(keys),cross_merge_size,multer_size);
			delta_list=({});
			result_list=({});
			foreach(path_multitarget;int path_key;mapping target_triples){
				int min_count=count;
				int min_target=-1;
				multiset min_triples;
				string min_target_key;
				[string ig,min_target_key]=parse_path(path_key);
				foreach(target_triples;int target;multiset triples){
					if(sizeof(triples)<min_count){
						min_count=sizeof(triples);
						min_target=target;
						min_triples=triples;
					}
				}
				ASSERT(min_target!=-1);
				
				if(sizeof(target_triples)>1){
					multiset set=find_atoms(min_triples,min_target_key,min_target);
					[object|string r0,int node0]=parse_triple_node(min_target);
					foreach(indices(target_triples),int target1){
						if(target1!=min_target){
							[object|string r,int node]=parse_triple_node(target1);
							int rr_size1,dxr_size1,dyr_size1,key_size1,cross_merge_size1,multer_size1;float cost;mapping extra;
							if(phase==0&&r==r0&&objectp(r)&&objectp(r0)){
								[rr_size1,dxr_size1,dyr_size1,key_size1,cross_merge_size1,multer_size1,cost,extra]=if_move(set,r0,node0,r,node);
							}else if(phase==1&&r!=rr&&r0!=rr&&r!=r0&&objectp(r)&&objectp(r0)){
								[rr_size1,dxr_size1,dyr_size1,key_size1,cross_merge_size1,multer_size1,cost,extra]=if_merge(set,r0,node0,r,node);
								werror("if_merge: key_size1=%d key_size=%d\n",key_size1,sizeof(keys));
							}else{
								continue;
							}
							float e1=e(rr_size1,dxr_size1,dyr_size1,key_size1,cross_merge_size1,multer_size1);
							float delta=e0-e1-cost;
							if(delta>0){
								delta_list+=({delta});
								result_list+=({({set,r0,node0,r,node,extra})});
								if(sizeof(delta_list)>128){
										sort(delta_list,result_list);
										delta_list=delta_list[<0..];
										result_list=result_list[<0..];
								}
								werror("delta_list size: %d\n",sizeof(delta_list));
							}
						}
					}
				}
			}
			if(sizeof(delta_list)){
				sort(delta_list,result_list);
				do_alter(@result_list[-1]);
				e0=e(rr_size,dxr_size,dyr_size,sizeof(keys),cross_merge_size,multer_size);
			}
		}while(sizeof(delta_list));
	//}
	foreach(path_multitarget;int path_key;mapping target_triples){
		werror("path target count: %d",sizeof(target_triples));
		foreach(target_triples;int target;multiset m){
			[object|string r,int node]=parse_triple_node(target);
			werror(" %s",find_relation_map_name(r));
		}
		werror("\n");
	}
}/*}}}*/
int security_main(int argc,array argv)/*{{{*/
{

	mapping args=Arg.parse(argv);
	array rest=args[Arg.REST];

	DECLARE_ARGUMENT_STRING_REQUIRED("inst",inst_flag,inst,"=INST");
	DECLARE_ARGUMENT_INTEGER_REQUIRED("interval",interval_flag,interval,"=SECONDS");
	DECLARE_ARGUMENT_STRING_REQUIRED("out",out_flag,outfile,"=FILE.db");
	DECLARE_ARGUMENT_INTEGER("multer",multer_flag,multer,"=N\tDefault is 1.");
	DECLARE_ARGUMENT_FLAG("include-unclosed",include_unclosed_flag,"");
	DECLARE_ARGUMENT_STRING_LIST("exclude",exclude_flag,exclude_days,"=DAY:...");
	DECLARE_ARGUMENT_FLAG("day-line",day_line_flag,"");
	DECLARE_ARGUMENT_FLAG("without-spliter",without_spliter_flag,"Do not use spliter.");
	DECLARE_ARGUMENT_FLAG("using-plane",using_plane_flag," Use plane instead.");
	DECLARE_ARGUMENT_FLAG("no-split",no_split_flag,"");
	DECLARE_ARGUMENT_FLAG("no-remove-old",no_remove_old_flag,"");

	if(Usage.usage(args,"",0)){
		return 0;
	}

	HANDLE_ARGUMENTS();

	multer=multer||1;

	object line=Candle.line(interval,Stdio.stdin);
	if(day_line_flag)
		line=line->day_line();
	if(exclude_flag){
		multiset days=(multiset)map(exclude_days,Calendar.ISO.dwim_day);
		line->a=filter(line->a,lambda(object item){
				return days[Calendar.ISO.Second(item->timeval)->day()]==0;
				});
	}

	object data=SecurityDeltaData(line,multer);
	object plane_data=SecurityPlaneData(data,multer);
	object r=SecurityRelationMap(data);

	object reducer;
	if(without_spliter_flag){
		reducer=OneDimReduceWithoutSpliter();
		if(using_plane_flag)
			reducer->data_list=({plane_data});
		else
			reducer->data_list=({data});
	}else if(no_split_flag){
		reducer=OneDimReduceNoSplit();
		reducer->data_list=({data});
	}else{
		reducer=OneDimReduceWithSpliter();
		reducer->data_list=({data});
	}

	reducer->r=r;

	mapping pos2concept=([]);

	string print_timeval(object a,int pos)/*{{{*/
	{
		if(pos<sizeof(a)){
			return Calendar.ISO.Second(a[pos]->timeval)->format_time_short();
		}else{
			return "end";
		}
	};/*}}}*/
	void print_concept(object a,object concept)
	{
		write("beginpos=%s aware_beginpos=%s endpos=%s aware_endpos=%s\n",
				print_timeval(a,concept->beginpos),
				print_timeval(a,concept->aware_beginpos),
				print_timeval(a,concept->endpos),
				print_timeval(a,concept->aware_endpos),
				 );
	};
	void print_result()/*{{{*/
	{
		foreach(r->a;int pos;object node)
		{
			if(node){
				object concept=pos2concept[node->beginpos];
				object info=reducer->entropy_single(data,r,(<pos>));
				write("minval=%+3d maxval=%+3d avgval=%3f begin=%s end=%s len=%d ",
						info->minval[0],info->maxval[0],info->avgval[0],
						print_timeval(data->line->a,node->beginpos),
						print_timeval(data->line->a,node->endpos),
						node->endpos-node->beginpos,
						);
				if(concept==0){
					write("\nMISS CONCEPT! following is all concepts: \n");
					foreach(SortMapping.sort(pos2concept);int pos;object concept){
						write(" | beginpos=%d aware_beginpos=%d endpos=%d aware_endpos=%d\n",
								concept->beginpos,
								concept->aware_beginpos,
								concept->endpos,
								concept->aware_endpos,
						     );
					}
				}else{
					write("beginpos=%d aware_beginpos=%d endpos=%d aware_endpos=%d\n",
							concept->beginpos,
							concept->aware_beginpos,
							concept->endpos,
							concept->aware_endpos,
					     );
				}
			}
		}
	};/*}}}*/
	void save_result()/*{{{*/
	{
		write("final:\n");
		object db=MassGdbm.gdbm(outfile,"crwf");
		object a=BigArray.BigArray(db,"size",save_concept,load_concept);
		array concept_list=({});
		foreach(SortMapping.sort(pos2concept);int pos;object concept){
			if(concept->endpos>concept->beginpos){
				print_concept(data->line->a,concept);
				concept_list+=({data->line->a[concept->beginpos]->timeval+"-"+data->line->a[concept->endpos-1]->timeval});
				a+=({concept});
			}
		}
		write("%s\n",concept_list*":");
		db->close();
	};/*}}}*/

	object last_concept_node;

	object last_node(object r,object curr)/*{{{*/
	{
		int pos=curr->beginpos;
		foreach(r->a;int id;object node){
			if(node){
				if(node->endpos==pos){
					return node;
				}
			}
		}
	};/*}}}*/

	object curr_node(object r,int endpos)/*{{{*/
	{
		foreach(r->a;int id;object curr)
		{
			if(curr&&curr->endpos==endpos){
				return curr;
			}
		}
	};/*}}}*/

	int last_what_happend;
	object last_curr;
	if(!without_spliter_flag&&!no_split_flag){
		reducer->spliter=LineSegSpliterHandler(data);
	}

	foreach(data->line->a;int pos;Candle.Item item)
	{
		data->update_cost(0,pos+1);
		reducer->update_entropy();
		object node=LineSegNode(pos,pos+1);

		r->add(node);
		reducer->feed(node);
		reducer->advance();

		int nowpos=node->endpos;
		object curr=curr_node(r,nowpos);
		last_curr=curr;

		int what_haapend; // 1=merged 2=splitted 3=stoped
		if(last_concept_node&&curr->beginpos<=last_concept_node->beginpos&&pos2concept[curr->beginpos]){
			werror("%d(%d-%d) %d(%d-%d)\n",last_concept_node->size(),last_concept_node->beginpos,last_concept_node->endpos,curr->size(),curr->beginpos,curr->endpos);
			//merged;
			what_haapend=1;
		}else{
			if(curr->size()!=1){
				//splitted
				what_haapend=2;
			}else{
				//stoped
				what_haapend=3;
			}
		}

		if(what_haapend==2||what_haapend==3){
			object last=last_node(r,curr);
			if(last){
				if(pos2concept[last->beginpos]){ //当发生两次split的时候可能为null
/*
split at 61234
split at 61164
*/
					pos2concept[last->beginpos]->aware_endpos=nowpos;
					pos2concept[last->beginpos]->endpos=curr->beginpos;
				}
			}
			pos2concept[curr->beginpos]=pos2concept[curr->beginpos]||Concept(inst,interval,curr->beginpos,nowpos,0,0);
		}

		if(!no_remove_old_flag){
			if(what_haapend==2||what_haapend==3){
				object last=last_node(r,curr);
				if(last){
					last=last_node(r,last);
					if(last){
						r->remove(r->find(last));
						m_delete(reducer->node2entropy,last);
					}
				}
			}
		}

		if(what_haapend){
			write("%s %d\n",print_timeval(data->line->a,pos),r->size());
			print_result();
		}
		last_concept_node=node;
		last_what_happend=what_haapend;
	}
	if(include_unclosed_flag){
		int nowpos=last_curr->endpos;
		pos2concept[last_curr->beginpos]->aware_endpos=nowpos;
		pos2concept[last_curr->beginpos]->endpos=nowpos;
	}
	save_result();

}/*}}}*/
int test_empty_mask_main(int argc,array argv)/*{{{*/
{
	int w=1024,h=1024;
	object r=PixelRelationMap(w,h);
	object cell=PixelNode(1,1,w,h);
	int pos=r->add(cell);
	werror("%d %d\n",sizeof(cell->query_selected()),r->count((<pos>)));
}/*}}}*/
int main(int argc,array argv)/*{{{*/
{
	mapping args=Arg.parse(argv);
	array rest=args[Arg.REST];

	DECLARE_ARGUMENT_EXECUTE("parse-image",parse_image_main,"")
	DECLARE_ARGUMENT_EXECUTE("security",security_main,"")
	DECLARE_ARGUMENT_EXECUTE("test-spliter",test_spliter_main,"")
	DECLARE_ARGUMENT_EXECUTE("test-empty-mask",test_empty_mask_main,"")

	if(Usage.usage(args,"",0)){
		return 0;
	}

	HANDLE_ARGUMENTS();
}/*}}}*/
