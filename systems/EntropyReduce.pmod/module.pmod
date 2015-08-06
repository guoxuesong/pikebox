#define DEBUG
#include <class.h>
#define CLASS_HOST "EntropyReduce"
class DynClass{
#include <class_imp.h>
}
#include <assert.h>

#define SIGMA Sigma

int myencode(int i,int j)/*{{{*/
{
	return (i<<32)|j;
}/*}}}*/
array mydecode(int k)/*{{{*/
{
	return ({k>>32,k&0xffffffff});
}/*}}}*/

int myencode_edgepos(int k,int x,int y,int x1,int y1)
{
	array a=({({x,y}),({x1,y1})});
	sort(column(a,0),a);
	sort(column(a,1),a);
	[x,y]=a[0];[x1,y1]=a[1];
	int dx=x1-x;int dy=y1-y;
	ASSERT(dx>=0&&dx<=1);
	ASSERT(dy>=0&&dy<=1);
	ASSERT(dx+dy==1);
	return ((((((((k<<16)|x)<<16)|y)<<1)|dx)<<1)|dy);
}
array mydecode_edgepos(int kk)
{
	int dx,dy,x,y,k;
	dy=kk&1;kk=kk>>1;
	dx=kk&1;kk=kk>>1;
	y=kk&0xffff;kk=kk>>16;
	x=kk&0xffff;kk=kk>>16;
	k=kk;
	return ({k,x,y,x+dx,y+dy});
}

float entropy_average(array a,int n)/*{{{*/
{
	float res=0.0;
	foreach(a,float e){
		res+=pow(2.0,-e);
	}
	res/=n;
	return -Math.log2(res);
}/*}}}*/
float diffa(array a1,array a2)/*{{{*/
{
	float res=0.0;
	for(int i=0;i<max(sizeof(a1),sizeof(a2));i++){
		res+=pow(a1[i]-a2[i],2);
	}
	return pow(res,0.5);
}/*}}}*/
float p2sumf(object image)/*{{{*/
{
	float sum=0.0;
	for(int i=0;i<image->xsize();i++){
		for(int j=0;j<image->ysize();j++){
			array color=image->getpixel(i,j);
			sum+=pow(0.0+color[0],2)+pow(0.0+color[1],2)+pow(0.0+color[2],2);
		}
	}
	return sum;
}/*}}}*/

array(float) global_std2(array nodes)/*{{{*/
{
	int N=3;
	array(float) errsum=({0.0})*N;
	float total=0.0;
	foreach(nodes,object node){
		object info=node->info;
		for(int i=0;i<N;i++){
			errsum[i]+=pow(info->stdval[i],2)*info->count;
			total+=info->count;
		}
	}
	errsum=map(errsum,`/,total);
	errsum=map(errsum,`+,1.0);
	return errsum;
}/*}}}*/

array coordlist2sigma(array coordlist)/*{{{*/
{
	int|float xsum,ysum,count;
	foreach(coordlist,[int|float i,int|float j]){
		xsum+=i;
		ysum+=j;
		count++;
	}
	float ex=1.0*xsum/count;
	float ey=1.0*ysum/count;

	float std2x,std2y,cov;
	foreach(coordlist,[int|float i,int|float j]){
		std2x+=pow(i-ex,2.0);
		std2y+=pow(j-ey,2.0);
		cov+=(i-ex)*(j-ey);
	}
	std2x/=count;
	std2y/=count;
	cov/=count;

	return ({({std2x,cov,}),({cov,std2y,})});
}/*}}}*/


//#define PROFILING
#include <profiling.h>

#define DUMP_ID
#define DUMP_PIXEL
//#define DUMP_PLANE

#define CACHESIZE 50000

#define OLDMERGE
//#define COMPAREARRAY_ENTROPY
//#define USING_COPY_OFFSET

#define REMOVE_CONT_IN_ENTROPYINFO
#define MOVE_COUNT_FROM_RELATIONMAP_TO_DATA

/* 抽象类型定义 开始 */
class InfomationEntity/*{{{*/
{
	int multer=1;
	float atom_entropy();
	array properties();
}/*}}}*/

class UniformDistribution(array minval,array maxval)/*{{{*/
{
	inherit InfomationEntity;
	inherit Save.Save; 
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
	float atom_entropy()/*{{{*/
	{
		array t=maxval[*]-minval[*];
		t=map(t,max,0.0);
		t=map(t,`+,1.0);
		t=map(t,Math.log2);
		float res=`+(0.0,@t);
		if(multer==1){
			return res;
		}else{
			return Math.log2((pow(2,res)-1)/multer+1);
		}
	}/*}}}*/
}/*}}}*/
class NormalDistribution(array avgval,array stdval,array diffsumval,mapping value_count)/*{{{*/
{
	inherit InfomationEntity;
	inherit Save.Save; 
	float cdf(float avg,float std,float x)
	{
		return 0.5*(1+SpecialFunction.erf((x-avg)/pow(2,0.5)/std));
	}
	float p(float avg,float std,int|float n)
	{
		avg=avg/multer;
		std=std/multer;
		n=1.0*n/multer;
		return cdf(avg,std,n+0.5)-cdf(avg,std,n-0.5);
	}
	float atom_entropy()
	{
		float res=0.0;
		int total;
		foreach(value_count;array val;int count){
			total+=count;
			res+=Math.log2(1/p(avgval[0],stdval[0],val[0])/p(avgval[1],stdval[1],val[1])/p(avgval[2],stdval[2],val[2]))*count;
		}
		if(total)
			res/=total;
		return res;
	}
}/*}}}*/


//已过时
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

class AvgValue(array avgval){}

class PropertyData{/*{{{*/
	string key;
	int weight=1;
	object set_weight(int n){weight=n;return this;}
	float cost(){return 0.0;}
	object set_key(string k){key=k;return this;}
	UniformDistribution uniform_distribution(RelationMap r,multiset ids);
	NormalDistribution normal_distribution(RelationMap r,multiset ids);
}/*}}}*/
class HasDynamicRange{/*{{{*/
	DynamicRange dynamic_range(RelationMap r,multiset ids);
}/*}}}*/
class HasAverageValue{/*{{{*/
	AvgValue average_value(RelationMap r,multiset ids,function|void maskfilter);
}/*}}}*/
class EntropyInfo
{
	inherit Save.Save;
	float explan_power();
}

class MultiEntropyInfo(SingleEntropyInfo ... infos)
{
	inherit EntropyInfo;
	float explan_power()
	{
		return `+(0.0,@map(infos,"explan_power"));
	}
}
class SingleEntropyInfo(
		int count, 
		array minval,
		array maxval,
		array avgval,
		float cost,
		float weight,
		)
{ 
	array dxval,dyval;
	int multer=1;
	inherit .EntropyInfo;
	object add(EntropyInfo rhd)/*{{{*/
	{
		if(cost!=rhd->cost)
			throw(({"cost not match.\n",backtrace()}));
		array res_minval=min(minval[*],rhd->minval[*]);
		array res_maxval=max(maxval[*],rhd->maxval[*]);
		return .SingleEntropyInfo(//`+(@map(map(res_maxval[*]-res_minval[*],`+,1.0),Math.log2)),
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
		//werror("SingleEntropyInfo\n");
		//throw(({"error",backtrace()}));
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

array eig(array sigma) // [V,LAMBDA]=eig(A) /*{{{*/
{
	assert(sigma[0][1]==sigma[1][0]);
	float cov=sigma[0][1];
	float std2x=sigma[0][0];
	float std2y=sigma[1][1];

	//sigma - z E = a z^2 + b z + c
	//sigma - z E = (sigma[0,0]-z)*(sigma[1,1]-z)-sigma[1,0]*sigma[0,1]
	//						= (std2x-z)*(std2y-z)-cov^2
	//						= z^2-(std2x+std2y)z-cov^2+(std2x*std2y)
	// a = 1
	// b = -(std2x+std2y)
	// c = -cov^2+(std2x*std2y)
	// 配方法 ( z + b/2a )^2 = (b^2-4ac)/4a^2
	// 当cov=0时：
	// sigma - z E = (std2x-z)*(std2y-z)
	// 因此两个特征值分别为std2x,std2y



	float a=1.0;
	float b=-sigma[0][0]-sigma[1][1];
	float c=-sigma[0][1]*sigma[1][0]+sigma[0][0]*sigma[1][1];
	float t=(pow(b,2.0)-4*a*c)/(4*pow(a,2.0));
	float z1,z2;
	if(t>-1e-9)
		t=max(t,0.0);
	if(t>=0){
		z1=pow(t,0.5)-b/(2*a);
		z2=-pow(t,0.5)-b/(2*a);
		//A1=[std2x-z1,cov;cov,std2y-z1]
		//方程组是
		//	(std2x-z1)*u1+cov*u2=0
		//	cov*u1+(std2y-z1)*u2=0
		//假设cov!=0有
		//	u2=-(std2x-z1)/cov*u1
		//	u1=-(std2y-z1)/cov*u2
		//要有解需要：
		//	(std2x-z1)/cov=cov/(std2y-z1)
		//已知 (std2x-z1)*(std2y-z1)=cov^2 所以上式一定成立。
		//此时特征向量为 k*({1,-(std2x-z1)/cov})

		if(cov==0.0){
			return ({({({1.0,0.0}),({0.0,1.0})}),({({std2x,0.0}),({0.0,std2y})})});
		}else{
			float s1=pow(1.0+pow(-(std2x-z1)/cov,2.0),0.5);
			float s2=pow(1.0+pow(-(std2x-z2)/cov,2.0),0.5);
			return ({({({1.0/s1,-(std2x-z1)/cov/s1}),({1.0/s2,-(std2x-z2)/cov/s2})}),({({z1,0.0}),({0.0,z2})})});
		}
	}else{
		werror("t=%O\n",t);
		throw(({"bad eigenvalues.\n",backtrace()}));
	}
}/*}}}*/
class SingleEntropyInfoWithNormalDistribution{
	inherit .SingleEntropyInfo;
	array stdval;
	array diffsumval;
	array sigma=({({0.0,0.0}),({0.0,0.0})});//xy坐标协方差矩阵
	array coordlist;
	/*array `minval(){
		throw(({"not support.\n",backtrace()}));
	}
	array `maxval(){
		throw(({"not support.\n",backtrace()}));
	}*/
	object add(EntropyInfo rhd)
	{
		//throw(({"not support.\n",backtrace()}));
		if(cost!=rhd->cost)
			throw(({"cost not match.\n",backtrace()}));
		//array res_minval=min(minval[*],rhd->minval[*]);
		//array res_maxval=max(maxval[*],rhd->maxval[*]);
		object res=.SingleEntropyInfoWithNormalDistribution(//`+(@map(map(res_maxval[*]-res_minval[*],`+,1.0),Math.log2)),
				count+rhd->count,
				0,//res_minval,
				0,//res_maxval,
				map(map(avgval,`*,count)[*]+map(rhd->avgval,`*,rhd->count)[*],`/,count+rhd->count),
				cost,
				weight,
				);
		res->coordlist=coordlist+rhd->coordlist;
		//res->sigma=.coordlist2sigma(res->coordlist);
		/* std2'=(sum[(xi-(u1+delta1))^2]+sum[(xj-(u2+delta2))^2])/(n1+n2)
			     =(sum[((xi-u1)-delta)^2]+sum[((xj-u2)-delta2)^2])/(n1+n2)
					 =(sum[(xi-u1)^2-2*(xi-u1)*delta1+delta1^2]+sum[(xj-u2)^2-2*(xj-u2)*delta2+delta2^2])/(n1+n2)
					 =(std21*n1-2*delta1*diffsum1+delta1^2+std22*n2-2*delta2*diffsum2+delta2^2)/(n1+n2)
					 */
		res->stdval=({0.0,0.0,0.0});
		array delta1=res->avgval[*]-avgval[*];
		array delta2=res->avgval[*]-rhd->avgval[*];
		for(int i=0;i<3;i++){
			res->stdval[i]=pow(stdval[i],2.0)*count-2*delta1[i]*diffsumval[i]+pow(delta1[i],2.0)
				+pow(rhd->stdval[i],2.0)*rhd->count-2*delta2[i]*rhd->diffsumval[i]+pow(delta2[i],2.0);
		}
		res->stdval=map(res->stdval,`/,(count+rhd->count));
		res->stdval=map(res->stdval,pow,0.5);
		res->diffsumval=(diffsumval[*]-map(delta1,`*,count)[*])[*]+(rhd->diffsumval[*]-map(delta2,`*,rhd->count)[*])[*];
		return res;
	}
	float explan_power()/*{{{*/
	{
		//werror("SingleEntropyInfoWithNormalDistribution\n");
		if(multer>1){
			throw(({"not support.\n",backtrace()}));
		}
		/*float res=0.0;
		foreach(stdval,float std){
			res+=0.5*Math.log2(2*Math.pi*Math.e*(1.0+pow(std,2)));
		}
		
		return -(res*count*weight+cost);*/

		//return -(cost+space());

		/*float m=space();
		float res=cost+Math.log2(m);
		if(count!=0.0)
			res+=Math.log2(1.0*m/count)*count;
		if(m-count!=0.0)
			res+=Math.log2(1.0*m/(m-count))*(m-count);
		return -res;*/

		return -cost;
		
	}/*}}}*/
	array v,l;
	float minx1=Math.inf;float maxx1=-Math.inf;
	float miny1=Math.inf;float maxy1=-Math.inf;
	float space()
	{
		if(v==0){
			[v,l]=.eig(sigma);
			sort(({l[0][0],l[1][1]}),v);
			[array u1,array u2]=reverse(v);

			foreach(coordlist,[int x,int y]){
				float x1=u1[0]*x+u1[1]*y;
				float y1=u2[0]*x+u2[1]*y;
				minx1=min(minx1,x1);
				miny1=min(miny1,y1);
				maxx1=max(maxx1,x1);
				maxy1=max(maxy1,y1);
			}
		}
		return (maxx1-minx1+1)*(maxy1-miny1+1);
	}
}


class Node{/*{{{*/
	EntropyInfo info;
	Node add(Node rhd);
}/*}}}*/
class RelationMap{/*{{{*/
	int size();
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
	int _add(mixed node,int|void _pos)/*{{{*/
	{
		if(_pos){
			while(sizeof(a)<_pos+1){
				a+=({0});
			}
			if(a[_pos]==0){
				a[_pos]=node;
				return _pos;
			}
		}
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
	int add(mixed node,int|void _pos)/*{{{*/
	{
		int pos=_add(node,_pos);
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
	mapping image_query_nearby_detail(object image1,object image2,int id,array|void mask,int|void keep_self)/*{{{*/
	{
		mapping res=([]);
		image_query_nearby_tool(image1,image2,id,mask,lambda(object t,int i,int j){
				array color=t->getpixel(i,j);
				int k=color2id(color);
				if(k>=0){
					res[k]=res[k]||({});
					res[k]+=({({i,j})});
				}
				},keep_self);
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
	multiset tags=(<>);
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
		res->tags=copy_value(tags);
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
		res->tags+=rhd->tags;
		return res;
	}/*}}}*/

}

class PixelRelationMapInterface{
	int xsize();
	int ysize();
	int zsize();

	void create(int w,int h);
	object clone();
	int count(multiset ids,function|void maskfilter);
	array query_mask(multiset ids);

	object load(mapping result_o);
	multiset find_nodes(array atom);
}

class PixelRelationMapTool{/*{{{*/
	array cellgroup_mask(object pixel_relations,multiset ids,function id2mask)/*{{{*/
	{
		array mask;
		foreach(ids;int id;int one)
		{
			array a=id2mask(id);
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
#if 0
array cellgroup_count(object pixel_relations,multiset ids)/*{{{*/
{
	array mask=cellgroup_mask(pixel_relations,ids);
	return map(mask,.ImageInteger.mask_count);
}/*}}}*/
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

class PixelEdgeRelationMap{
	inherit ArrayRelationMap;
	inherit IdImageTool;
	inherit IdsImageTool;
	inherit PixelRelationMapTool;
	inherit PixelRelationMapInterface;
	object image;

	/* 以下是实现 RelationMap */

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
		return `+(0,@map(query_mask(ids),.ImageInteger.mask_count));
	}/*}}}*/
	array query_mask(multiset ids)/*{{{*/
	{
		return cellgroup_mask(this,ids,lambda(int id){
				return ({ids_create_mask(image,id)});
				});
		//return ({ids_create_mask(image,pos)});
	}/*}}}*/
	object load(mapping result_o/*,int levellimit*/)/*{{{*/
	{
		foreach(result_o;int id0;mapping m){
			array aa=m->cell;
			object cell=PixelNode(/*levellimit*/1,1,image->xsize(),image->ysize());
			cell->info=m->info;
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
	inherit PixelRelationMapTool;
	inherit PixelRelationMapInterface;
	object image;
	int nearby_level2;

	/* 以下是实现 RelationMap */

	int add(object cell,int|void _pos)/*{{{*/
	{
		int pos=_add(cell,_pos);
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
		array mask;
		multiset res=image_query_nearby(image,image,pos,mask);
		if(nearby_level2){
			return `|(res,@map((array)res,Function.curry(image_query_nearby)(image,image),mask))-(<pos>);
		}else{
			return res;
		}
	}/*}}}*/

	/* 以下是实现 PixelRelationMapInterface */
	int xsize(){return image->xsize();}
	int ysize(){return image->ysize();}
	int zsize(){return 1;}
	int count(multiset ids,function|void maskfilter)/*{{{*/
	{
		if(maskfilter==0){
			return `+(0,@map(query_mask(ids),.ImageInteger.mask_count));
		}else{
			return `+(0,@map(map(query_mask(ids),maskfilter),.ImageInteger.mask_count));
		}
		//return `+(0,@cellgroup_count(this,ids));
	}/*}}}*/
	array query_mask(multiset ids)/*{{{*/
	{
		return cellgroup_mask(this,ids,lambda(int id){
				return ({id_create_mask(image,id)});
				});
		//return ({id_create_mask(image,pos)});
	}/*}}}*/
	object load(mapping result_o/*,int levellimit*/)/*{{{*/
	{
		foreach(result_o;int id0;mapping m){
			array aa=m->cell;
			object cell=PixelNode(/*levellimit*/1,1,image->xsize(),image->ysize());
			cell->info=m->info;
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
	object clone(int|void clone_nodes,object|void res)/*{{{*/
	{
		res=res||PixelRelationMap(image->xsize(),image->ysize());
		res->image=image->clone();
		//test_compare_image(res->image,image);
		res->a=copy_value(a);
		if(clone_nodes){
			foreach(res->a;int id;object node){
				if(node){
					res->a[id]=node->clone();
				}
			}
		}
		res->listeners=copy_value(listeners);
		return res;
	}/*}}}*/
	multiset find_nodes(array atom)/*{{{*/
	{
		return (<color2id(image->getpixel(@atom))>);
	}/*}}}*/

	/* 以下是当前类特有 */

	multiset query_raw_nearby(int pos)/*{{{*/
	{
		array mask;
		multiset res=image_query_nearby(image,image,pos,mask);
		return res;
	}/*}}}*/
	mapping query_raw_nearby_detail(int pos)/*{{{*/
	{
		array mask;
		mapping res=image_query_nearby_detail(image,image,pos,mask);
		return res;
	}/*}}}*/

	int find_node(array atom)/*{{{*/
	{
		return color2id(image->getpixel(@atom));
	}/*}}}*/
}
class PixelRelationLevel2Map{
	inherit PixelRelationMap;
	object r;
	void create(PixelRelationMap _r)
	{
		r=_r;
		::create(r->image->xsize(),r->image->ysize());
		r->clone(1,this);
		foreach(a;int pos;object node){
			if(node){
				node->tags=(<pos>);
			}
		}
	}
	int count(multiset ids)
	{
		ids=`+((<>),@map((array)ids,lambda(int id){
					if(r->a[id])
						return r->a[id]->tags;
					else
						return (<>);
				}));
		return sizeof(ids);
	}
}

class ThreeDimRelationMap{
	inherit ArrayRelationMap;
	inherit IdImageTool;
	inherit PixelRelationMapTool;
	array(object) images;

	/* 以下是实现 RelationMap */

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
		array masks=query_mask((<pos>));

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
		return `+(0,@map(query_mask(ids),.ImageInteger.mask_count));
		//return `+(0,@cellgroup_count(this,ids));
	}/*}}}*/
	array query_mask(multiset ids)/*{{{*/
	{
		return cellgroup_mask(this,ids,lambda(int id){
				return map(images,id_create_mask,id);
				});
		//return ({ids_create_mask(image,pos)});
	}/*}}}*/
	object load(mapping result_o/*,int levellimit*/)/*{{{*/
	{
		foreach(result_o;int id0;mapping m){
			array aa=m->cell;
			object cell=PixelNode(/*levellimit*/sizeof(images),1,images[0]->xsize(),images[0]->ysize());
			cell->info=m->info;
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
		return `+(0,@map(query_mask(ids),.ImageInteger.mask_count));
		//return cellgroup_count(this,ids);
	}/*}}}*/

}


class PixelData(object/*(ImageInteger)*/ data){
	inherit PropertyData;
	inherit HasAverageValue;
	float costval;
	int layer;
	object set_layer(int n){layer=n;return this;}
	float cost() { return costval; }
	object set_cost(int|float val){costval=(float)val;return this;}
	AvgValue average_value(PixelRelationMap r,multiset ids,function|void maskfilter)/*{{{*/
	{
		array a=r->query_mask(ids);
		object mask0=a[layer];

		if(maskfilter)
			mask0=maskfilter(mask0);

#ifndef USING_COPY_OFFSET
		/*
		if(mask0->xsize()==data->xsize()&&mask0->ysize()==data->ysize())
			;
		else
			throw(({"size not match.\n",backtrace()}));
			*/
#endif


		
		[object mask,object dd0]=.ImageInteger.mask_autocrop(mask0,data);
		//[object mask,object dd0]=({mask0,data});

		/*if(mask==0){
			if(mask0==0)
				throw(({"zero mask0.\n",backtrace()}));
			throw(({"zero mask.\n",backtrace()}));
		}*/

		array avgval=dd0->average(mask);
		//werror("minval=%O maxval=%O",minval,maxval);
		return AvgValue(avgval);
	}/*}}}*/
	UniformDistribution uniform_distribution(PixelRelationMap r,multiset ids,function|void maskfilter)/*{{{*/
	{
		array a=r->query_mask(ids);
		object mask0=a[layer];

		if(maskfilter)
			mask0=maskfilter(mask0);

#ifndef USING_COPY_OFFSET
		/*
		if(mask0->xsize()==data->xsize()&&mask0->ysize()==data->ysize())
			;
		else
			throw(({"size not match.\n",backtrace()}));
			*/
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
		//werror("minval=%O maxval=%O",minval,maxval);
		return UniformDistribution(minval,maxval);
	}/*}}}*/
	NormalDistribution normal_distribution(RelationMap r,multiset ids)/*{{{*/
	{
		array a=r->query_mask(ids);
		object mask0=a[layer];

#ifndef USING_COPY_OFFSET
		/*
		if(mask0->xsize()==data->xsize()&&mask0->ysize()==data->ysize())
			;
		else
			throw(({"size not match.\n",backtrace()}));
			*/
#endif

		[object mask,object dd0]=.ImageInteger.mask_autocrop(mask0,data);

		array avgval=dd0->average(mask);
		array stdval=({0.0,0.0,0.0});
		array diffsumval=({0.0,0.0,0.0});
		mapping m=([]);
		int count;

		foreach(ids;int id;int one){
			foreach(r->a[id]->query_selected(),[int k,int i,int j]){
				array val=data->getpixel(i,j);
				stdval[0]+=pow(val[0]-avgval[0],2);
				stdval[1]+=pow(val[1]-avgval[1],2);
				stdval[2]+=pow(val[2]-avgval[2],2);
				diffsumval[0]+=val[0]-avgval[0];
				diffsumval[1]+=val[1]-avgval[1];
				diffsumval[2]+=val[2]-avgval[2];
				count++;
				m[ByValue.Array(@val)]++;
			}
		}
		if(count)
			stdval=map(stdval,`/,count);
		stdval=map(stdval,pow,0.5);
		mapping value_count=([]);
		foreach(m;object key;int val){
			value_count[m->a]=val;
		}

		return NormalDistribution(avgval,stdval,diffsumval,value_count);
	}/*}}}*/
	object global_range()/*{{{*/
	{
		return UniformDistribution(data->min(),data->max());
	}/*}}}*/
	void update_cost()/*{{{*/
	{
		object gr=global_range();
		costval=gr->atom_entropy()*2;
		werror("costval=%f\n",costval);
	}/*}}}*/
	int count(object r,multiset ids)/*{{{*/
	{
		return r->count(ids);
	}/*}}}*/
}

class DxInternalData{ //XXX: 麻烦事，r->count()假设对一个归并元所有的data看到的原子数是一样的，但r,dxinternal,dyinternal归并中原子数不等
	inherit PixelData;
	object mask_cache=CacheLite.Cache(1024,1);
	protected object _mask2dx_internal(object mask)/*{{{*/
	{
		return mask->outline(({
				({0,0,0}),
				({0,1,1}),
				({0,0,0})
				}),0,0,0,255,255,255);
	};/*}}}*/
	protected object mask2dx_internal(object mask)/*{{{*/
	{
		return mask_cache(mask,_mask2dx_internal,mask);
	}/*}}}*/
	AvgValue average_value(PixelRelationMap r,multiset ids,function|void maskfilter)/*{{{*/
	{
		return ::average_value(r,ids,mask2dx_internal);
	}/*}}}*/
	UniformDistribution uniform_distribution(PixelRelationMap r,multiset ids,function|void maskfilter)/*{{{*/
	{
		return ::uniform_distribution(r,ids,mask2dx_internal);
	}/*}}}*/
	int count(object r,multiset ids)/*{{{*/
	{
		return r->count(ids,mask2dx_internal);
	}/*}}}*/
}
class DyInternalData{
	inherit PixelData;
	object mask_cache=CacheLite.Cache(1024,1);
	protected object _mask2dy_internal(object mask)/*{{{*/
	{
		return mask->outline(({
				({0,0,0}),
				({0,1,0}),
				({0,1,0})
				}),0,0,0,255,255,255);
	};/*}}}*/
	protected object mask2dy_internal(object mask)/*{{{*/
	{
		return mask_cache(mask,_mask2dy_internal,mask);
	}/*}}}*/
	AvgValue average_value(PixelRelationMap r,multiset ids,function|void maskfilter)/*{{{*/
	{
		return ::average_value(r,ids,mask2dy_internal);
	}/*}}}*/
	UniformDistribution uniform_distribution(PixelRelationMap r,multiset ids,function|void maskfilter)/*{{{*/
	{
		return ::uniform_distribution(r,ids,mask2dy_internal);
	}/*}}}*/
	int count(object r,multiset ids)/*{{{*/
	{
		return r->count(ids,mask2dy_internal);
	}/*}}}*/
}

class RangeData(int n,object rr){
	inherit PropertyData;
	inherit HasAverageValue;
	float costval;
	int layer;
	object set_layer(int n){layer=n;return this;}
	float cost() { return costval; }
	object set_cost(int|float val){costval=(float)val;return this;}
	AvgValue average_value(PixelRelationMap r,multiset ids,function|void maskfilter){/*{{{*/
		if(maskfilter)
			throw(({"maskfilter not supported.\n",backtrace()}));

		array avgval=({0})*n;
		int count;

		ids=`+((<>),@map((array)ids,lambda(int id){
				return r->a[id]->tags;
				}));
		foreach(ids;int id;int one){
			if(rr->a[id]){
				if(n!=sizeof(rr->a[id]->info->minval)){
					werror("n=%d n0=%d\n",n,sizeof(rr->a[id]->info->minval));
					throw(({"bad property count\n",backtrace()}));
				}
				for(int i=0;i<n;i++){
					avgval[i]+=rr->a[id]->info->maxval[i]-rr->a[id]->info->minval[i];
				}
				count++;
			}
		}
		avgval=map(avgval,`/,count*1.0);
		return AvgValue(avgval);
	}/*}}}*/
	UniformDistribution uniform_distribution(PixelRelationMap r,multiset ids/*,function|void maskfilter*/)/*{{{*/
	{
		array minval=({Int.NATIVE_MAX})*n;
		array maxval=({Int.NATIVE_MIN})*n;
		int count;

		ids=`+((<>),@map((array)ids,lambda(int id){
				return r->a[id]->tags;
				}));
		foreach(ids;int id;int one){
			if(rr->a[id]){
				if(n!=sizeof(rr->a[id]->info->minval))
					throw(({"bad property count\n",backtrace()}));
				for(int i=0;i<n;i++){
					minval[i]=min(minval[i],rr->a[id]->info->maxval[i]-rr->a[id]->info->minval[i]);
					maxval[i]=max(maxval[i],rr->a[id]->info->maxval[i]-rr->a[id]->info->minval[i]);
				}
				count++;
			}
		}
		/*for(int i=0;i<n;i++){
			werror("[%d,%d] ",minval[i],maxval[i]);
		}
		werror("\n");*/
		return UniformDistribution(minval,maxval);
	}/*}}}*/
	NormalDistribution normal_distribution(RelationMap r,multiset ids)/*{{{*/
	{
			throw(({"not support.\n",backtrace()}));
	}/*}}}*/
	object global_range()
	{
		throw(({"not support.\n",backtrace()}));
		//return UniformDistribution(data->min(),data->max());
	}
	void update_cost()
	{
		throw(({"not support.\n",backtrace()}));
		//object gr=global_range();
		//costval=gr->atom_entropy()*2;
	}
}
class MinMaxData(int n,object rr){
	inherit PropertyData;
	inherit HasAverageValue;
	float costval;
	int layer;
	object set_layer(int n){layer=n;return this;}
	float cost() { return costval; }
	object set_cost(int|float val){costval=(float)val;return this;}
	AvgValue average_value(PixelRelationMap r,multiset ids,function|void maskfilter){/*{{{*/
		if(maskfilter)
			throw(({"maskfilter not supported.\n",backtrace()}));

		array avgval=({0})*n*2;
		int count;

		ids=`+((<>),@map((array)ids,lambda(int id){
				return r->a[id]->tags;
				}));
		foreach(ids;int id;int one){
			if(rr->a[id]){
				if(n!=sizeof(rr->a[id]->info->minval)){
					werror("n=%d n0=%d\n",n,sizeof(rr->a[id]->info->minval));
					throw(({"bad property count\n",backtrace()}));
				}
				for(int i=0;i<n;i++){
					avgval[i*2]+=rr->a[id]->info->minval[i];
					avgval[i*2+1]+=rr->a[id]->info->maxval[i];
				}
				count++;
			}
		}
		avgval=map(avgval,`/,count*1.0);
		return AvgValue(avgval);
	}/*}}}*/
	UniformDistribution uniform_distribution(PixelRelationMap r,multiset ids/*,function|void maskfilter*/)/*{{{*/
	{
		array minval=({Int.NATIVE_MAX})*n*2;
		array maxval=({Int.NATIVE_MIN})*n*2;
		int count;

		ids=`+((<>),@map((array)ids,lambda(int id){
				return r->a[id]->tags;
				}));
		foreach(ids;int id;int one){
			if(rr->a[id]){
				if(n!=sizeof(rr->a[id]->info->minval))
					throw(({"bad property count\n",backtrace()}));
				for(int i=0;i<n;i++){
					minval[i*2]=min(minval[i*2],rr->a[id]->info->minval[i]);
					minval[i*2+1]=min(minval[i*2+1],rr->a[id]->info->maxval[i]);
					maxval[i*2]=max(maxval[i*2],rr->a[id]->info->minval[i]);
					maxval[i*2+1]=max(maxval[i*2+1],rr->a[id]->info->maxval[i]);
				}
				count++;
			}
		}
		for(int i=0;i<n;i++){
			werror("[%d,%d] ",minval[i],maxval[i]);
		}
		werror("\n");
		return UniformDistribution(minval,maxval);
	}/*}}}*/
	NormalDistribution normal_distribution(RelationMap r,multiset ids)/*{{{*/
	{
			throw(({"not support.\n",backtrace()}));
	}/*}}}*/
	object global_range()
	{
		throw(({"not support.\n",backtrace()}));
		//return UniformDistribution(data->min(),data->max());
	}
	void update_cost()
	{
		throw(({"not support.\n",backtrace()}));
		//object gr=global_range();
		//costval=gr->atom_entropy()*2;
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
		
		extern SingleEntropyInfo entropy_of(array data_list,object r,multiset ids);
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
		extern SingleEntropyInfo entropy_of(array data_list,object r,multiset ids);
		extern SingleEntropyInfo entropy_single(object data,object r,multiset ids);
		extern SingleEntropyInfo entropy_div(object data,object r,multiset ids,int multer);
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
#ifndef REMOVE_CONT_IN_ENTROPYINFO
				cache[key]=({node,info->explan_power(),info->count,info});
#else
				cache[key]=({node,info->explan_power(),info});
#endif
#ifdef COMPAREARRAY_ENTROPY
				cache[key][1]=CompareArray.CompareArray(({cache[key][1],0.0}));
#endif

				PROFILING_END
			}
			return cache[key];
		}
#ifndef REMOVE_CONT_IN_ENTROPYINFO
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
#endif
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
#ifndef REMOVE_CONT_IN_ENTROPYINFO
#ifdef COMPAREARRAY_ENTROPY
				cache[key]=({node,CompareArray.CompareArray(({node->info->explan_power(),0.0})),node->info->count,node->info});
#else
				cache[key]=({node,node->info->explan_power(),node->info->count,node->info});
#endif
#else
#ifdef COMPAREARRAY_ENTROPY
				cache[key]=({node,CompareArray.CompareArray(({node->info->explan_power(),0.0})),node->info});
#else
				cache[key]=({node,node->info->explan_power(),node->info});
#endif
#endif

				PROFILING_END
			}
			return cache[key];
		}
	}
#ifndef REMOVE_CONT_IN_ENTROPYINFO
#ifdef MULTI_MODELS
	class UsingModels
#else
	class UsingPlane
#endif
	{
		inherit Interface;
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
			object res=(.ImageInteger.ImageInteger(x2-x1+1,y2-y1+1)+image->copy(x1,y1,x2,y2))->set_copy_offset(x1,y1,x2,y2);
			for(int i=x1;i<=x2;i++){
				for(int j=y1;j<=y2;j++){
					array a=image->getpixel(i,j);
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
		[object mask]=r->query_mask(ids);
		[int x1,int y1,int x2,int y2]=.ImageInteger.mask_find_autocrop(mask);
		array dxval;array dyval;//array cval;
		//mixed e;
		/*if(dx&&dy&&g){
			dxval=dx(r,ids)->avgval;
			dyval=dy(r,ids)->avgval;
			return ({({g(dxval,dyval),dxval,dyval,({0,0,target->data->xsize()-1,target->data->ysize()-1})})});
		}else if(dx&&dy){*/

			if(r->count(ids)<=1){
				return ({({target->data,({0,0,0}),({0,0,0}),({x1,y1,x2,y2})})});
			}

			array res=({});
			int add_empty_flag;
			foreach(({mask2dx_internal/*,mask2dx_left,mask2dx_right,mask2dx_both*/}),function dxfilter){
				object av;
				av=dx(r,ids,dxfilter);
				dxval=av->avgval;
				foreach(({mask2dy_internal/*,mask2dy_up,mask2dy_down,mask2dy_both*/}),function dyfilter){
					object av;
					av=dy(r,ids,dyfilter);
					dyval=av->avgval;
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
		/*}else{
			e=catch{
				[dxval,dyval,cval]=target->data->linear_fit(r->query_mask(ids)[0]);
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
		}*/
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
				array allplanes=ids_create_planes(r,ids,target,dx_left->average_value,dy_up->average_value,100);
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
#endif
}

class EntropyReduceEntropyMode{
	class Interface{
		//SingleEntropyInfo entropy_of(array data_list,object r,multiset ids);
		SingleEntropyInfo entropy_single(object data,object r,multiset ids);
		SingleEntropyInfo entropy_div(object data,object r,multiset ids,int multer);
	}
	class UsingDynamicRange{ //老的实现，OneDim还在使用
	SingleEntropyInfo entropy_from_dynamic_range(object dr,int weight,int count,float cost){/*{{{*/
		object res=dr;
		return .SingleEntropyInfo(count,res->minval,res->maxval,res->avgval,cost,weight*1.0);
	}/*}}}*/
	SingleEntropyInfo entropy_single(object data,object r,multiset ids)//类似v1，改用PixelRelationMap来获取数据/*{{{*/
	{
#ifndef MOVE_COUNT_FROM_RELATIONMAP_TO_DATA
		return entropy_from_dynamic_range(data->dynamic_range(r,ids),data->weight,r->count(ids),data->cost());
#else
		return entropy_from_dynamic_range(data->dynamic_range(r,ids),data->weight,data->count(r,ids),data->cost());
#endif
	}/*}}}*/
	SingleEntropyInfo entropy_div(object data,object r,multiset ids,int multer)/*{{{*/
	{
#ifndef MOVE_COUNT_FROM_RELATIONMAP_TO_DATA
		object res=entropy_from_dynamic_range(data->dynamic_range(r,ids),data->weight,r->count(ids),data->cost());
#else
		object res=entropy_from_dynamic_range(data->dynamic_range(r,ids),data->weight,data->count(r,ids),data->cost());
#endif
		res->multer=multer;
		return res;
	}/*}}}*/
	}
	class UsingAvgValue{ //应该使用这个实现
	SingleEntropyInfo entropy_single(object data,object r,multiset ids)//类似v1，改用PixelRelationMap来获取数据/*{{{*/
	{
		//werror("entropy_single of UsingAvgValue\n");
		//throw(({"error",backtrace()}));
		object av=data->average_value(r,ids);
		object ud=data->uniform_distribution(r,ids);

#ifndef MOVE_COUNT_FROM_RELATIONMAP_TO_DATA
		return .SingleEntropyInfo(r->count(ids),ud->minval,ud->maxval,av->avgval,data->cost(),data->weight*1.0);
#else
		return .SingleEntropyInfo(data->count(r,ids),ud->minval,ud->maxval,av->avgval,data->cost(),data->weight*1.0);
#endif
	}/*}}}*/
	SingleEntropyInfo entropy_div(object data,object r,multiset ids,int multer)/*{{{*/
	{
		//werror("entropy_div of UsingAvgValue\n");
		//throw(({"error",backtrace()}));
		object av=data->average_value(r,ids);
		object ud=data->uniform_distribution(r,ids);
#ifndef MOVE_COUNT_FROM_RELATIONMAP_TO_DATA
		object res=.SingleEntropyInfo(r->count(ids),ud->minval,ud->maxval,av->avgval,data->cost(),data->weight*1.0);
#else
		object res=.SingleEntropyInfo(data->count(r,ids),ud->minval,ud->maxval,av->avgval,data->cost(),data->weight*1.0);
#endif
		res->multer=multer;
		return res;
	}/*}}}*/
	}
	class UsingAvgValueWithNormalDistribution{ //测试，用正态分布来统计残差熵
	SingleEntropyInfo entropy_single(object data,object r,multiset ids)//类似v1，改用PixelRelationMap来获取数据/*{{{*/
	{
		//werror("entropy_single of UsingAvgValueWithNormalDistribution\n");
		object av=data->average_value(r,ids);
		object ud=data->uniform_distribution(r,ids);
		object nd=data->normal_distribution(r,ids);

#ifndef MOVE_COUNT_FROM_RELATIONMAP_TO_DATA
		object res=.SingleEntropyInfoWithNormalDistribution(r->count(ids),ud->minval,ud->maxval,av->avgval,data->cost(),data->weight*1.0);
#else
		object res=.SingleEntropyInfoWithNormalDistribution(data->count(r,ids),ud->minval,ud->maxval,av->avgval,data->cost(),data->weight*1.0);
#endif
		res->stdval=nd->stdval;
		res->diffsumval=nd->diffsumval;

		/*
		int xsum,ysum,count;
		foreach(ids;int id;int one){
			object cell=r->a[id];
			foreach(cell->query_selected(),[int k,int i,int j]){
				xsum+=i;
				ysum+=j;
				count++;
			}
		}
		float ex=1.0*xsum/count;
		float ey=1.0*ysum/count;

		float std2x,std2y,cov;
		array coordlist=({});
		foreach(ids;int id;int one){
			object cell=r->a[id];
			foreach(cell->query_selected(),[int k,int i,int j]){
				std2x+=pow(i-ex,2.0);
				std2y+=pow(j-ey,2.0);
				cov+=(i-ex)*(j-ey);
				coordlist+=({({i,j})});
			}
		}
		std2x/=count;
		std2y/=count;
		cov/=count;

		res->sigma=({({std2x,cov,}),({cov,std2y,})});
		*/
		array coordlist=({});
		foreach(ids;int id;int one){
			object cell=r->a[id];
			foreach(cell->query_selected(),[int k,int i,int j]){
				coordlist+=({({i,j})});
			}
		}
		res->sigma=.coordlist2sigma(coordlist);
		res->coordlist=coordlist;

		return res;
	}/*}}}*/
	SingleEntropyInfo entropy_div(object data,object r,multiset ids,int multer)/*{{{*/
	{
		throw(({"not support.\n",backtrace()}));
	}/*}}}*/
	}
}

/*float relative_sharp_entropy(object mask,object mask0)
{
	float mincount=Math.inf;
	for(int i=mask0->xsize()-mask->xsize()+1;i<=mask0->xsize();i++){
		for(int j=mask0->ysize()-mask->ysize()+1;i<=mask0->ysize();i++){
			float count=(mask-(mask0->copy(i,j,i+mask->xsize()-1,j+mask->ysize()-1)))->sumf()[0]/255;
			mincount=min(count,mincount);
		}
	}
	return mincount*Math.log2(mask->sumf()[0]/255);
}*/

class EntropyReduce{
	inherit EntropyReduceMode.Interface;
	inherit EntropyReduceSplitMode.Interface;
	inherit EntropyReduceEntropyMode.Interface;
	object r;
	mapping node2entropy=([]);
	int using_dynamic_colorrange_cost;
	object set_using_dynamic_colorrange_cost(int v)
	{
		using_dynamic_colorrange_cost=v;
		return this;
	}
	int using_dynamic_dxdy_precision_cost;
	int using_edge_entropy;
	int using_global_error;

	PixelData coord;

	int monitor_pixel_flag;
	array monitor_pixel_xy;

	SingleEntropyInfo entropy_of(array data_list,object r,multiset ids)/*{{{*/
	{
#ifndef MOVE_COUNT_FROM_RELATIONMAP_TO_DATA
		int count=r->count(ids);
#else
		array count_list=({});
		array pos_list=({});
		array cost_list=({});
#endif
		array info_list=({});


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
				vv+=({-info->explan_power()});
				/*if(count!=info->count){
					werror("%O %O\n",count,info->count);
					throw(({"count not match with info->count.\n",backtrace()}));
				}*/
				info_list+=({info});
#ifdef MOVE_COUNT_FROM_RELATIONMAP_TO_DATA
				count_list+=({data->count(r,ids)});
				pos_list+=({sizeof(minvals)});
				cost_list+=({data->cost()});
#endif
				minvals+=info->minval;
				maxvals+=info->maxval;
				avgvals+=info->avgval;
				//dynamic_range_data[data->key]=({info->minval,info->maxval,info->avgval});
			}
#ifdef MOVE_COUNT_FROM_RELATIONMAP_TO_DATA
			if(sizeof(Array.uniq(count_list))==1){
				//werror("i0=%f count=%d\n",i0,count);
				float entropy=-`+(0.0,@vv);
				object info;
				if(sizeof(count_list)==1){
					info=info_list[0];
					assert(info->count==count_list[0]);
					assert(equal(info->minval,minvals));
					assert(equal(info->maxval,maxvals));
					assert(equal(info->avgval,avgvals));
					assert(info->cost==cost);
					assert(info->weight==1.0);
				}else{
					info=SingleEntropyInfo(count_list[0],minvals,maxvals,avgvals,cost,1.0);
				}
				return info;
			}else{
				array res=({});
				int p=0;
				foreach(pos_list;int i;int pos){
					res+=({SingleEntropyInfo(count_list[i],minvals[p..p+pos-1],maxvals[p..p+pos-1],avgvals[p..p+pos-1],cost_list[i],1.0)});
					p+=pos;
				}
				return MultiEntropyInfo(@res);
			}
#else
			//werror("i0=%f count=%d\n",i0,count);
			float entropy=-`+(0.0,@vv);
			object info=SingleEntropyInfo(count,minvals,maxvals,avgvals,cost,1.0);
			return info;
#endif
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

		//object dxdy_precision_cache=CacheLite.Cache(CACHESIZE,1);

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
			if(r->nearby_level2){//XXX
				multiset m=(multiset)ids;
				foreach(ids,int id0){
					foreach(r->query_raw_nearby(id0);int id;int one){
						if(!m[id]){
							nearby_mapping[id]=nearby_mapping[id]||(<>);
							foreach(r->query_nearby(id);int j0;int one){
								nearby_mapping[id][j0]=1;
								nearby_mapping[j0]=nearby_mapping[j0]||(<>);
								nearby_mapping[j0][id]=1;
							}
						}
					}
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
#ifndef REMOVE_CONT_IN_ENTROPYINFO
					[object node,float|object entropy,int entropy_count,mapping entropy_info]=entropy_if_merge(r,i,j,cache);
#else
					[object node,float|object entropy,mapping entropy_info]=entropy_if_merge(r,i,j,cache);
#endif
					float|object entropy1=node2entropy[node1];
					float|object entropy2=node2entropy[node2];
					//werror("entropy1=%O entropy2=%O\n",entropy1,entropy2);
					float|object extra_entropy=0.0;
					float|object old_extra_entropy=0.0;
					if(using_dynamic_colorrange_cost){/*{{{*/
						/* 每个聚合类有一个残差范围，[r..R] [g..G] [b..B]
							 残差的基值视为无冗余，我们希望减小残差范围宽度的熵，
							 即每个聚合类有三个属性，D_r=R-r,D_g=G-g,D_b=B-b
							 对表{(class_id,D_r,D_g,D_b)*n}进行归约
							 class_id应该被视为有序的
							 对D_r,D_g,D_b计算范围[1,(D_r)_{max}] [1,(D_g)_{max}] [1,(D_b)_{max}] 
							 熵为：(ln((D_r)_max)+ln((D_g)_max)+ln((D_b)_max))*N_{class_id}
							 */
						array a1=filter(r->a,`!=,0);
						array a2=a1-({node1,node2})+({node});
						int mycount(object node,int n)
						{
							return (node->info->valncount(n)-1)/node->info->multer+1;//XXX
						};
						array old_valcounts=({0,0,0});
						for(int i=0;i<3;i++){
							old_valcounts[i]=g_range_caches[i](r->a,lambda(){
									//werror("range cache miss.\n");
									return max(0,@map(a1,mycount,i));
									});
						}
						array new_valcounts=({0,0,0});
						for(int i=0;i<3;i++){
							/*
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
							*/
							new_valcounts[i]=max(0,@map(a2,mycount,i));
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
					if(using_dynamic_dxdy_precision_cost){/*{{{*/
						array a1=filter(r->a,`!=,0);
						array a2=a1-({node1,node2})+({node});

						int mycount(object node,int n)
						{
							if(n==0){
								return node->x_max-node->x_min+1;
							}else if(n==1){
								return node->y_max-node->y_min+1;
							}
						};
						array old_valcounts=({0,0});
						for(int i=0;i<2;i++){
							old_valcounts[i]=g_range_caches[3+i](r->a,lambda(){
									//werror("range cache miss.\n");
									return max(0,@map(a1,mycount,i));
									});
						}
						array new_valcounts=({0,0});
						for(int i=0;i<2;i++){
							new_valcounts[i]=max(0,@map(a2,mycount,i));
						}
						extra_entropy+=Math.log2(`*(1.0,@new_valcounts))*(r->size()-1);
						old_extra_entropy+=Math.log2(`*(1.0,@old_valcounts))*r->size();
					}/*}}}*/
					if(using_edge_entropy){/*{{{*/
						/*object create_edge_mask(multiset m1,multiset m2)
						{
							return (r->query_mask(m1)[0])&(r->query_mask(m2)[0]);
						};*/
						float query_edge_entropy(object node,multiset ids)
						{
							float res=0.0;
							multiset m=`|(@map((array)ids,r->query_nearby))-ids;
							object mask=r->query_mask(ids)[0];
							foreach(m;int id;int one){
								object node1=r->a[id];
								object mask1=r->query_mask((<id>))[0];
								res+=this->edge_entropy(ids,(<id>),node,node1,mask,mask1);
							}
						};
						float|object edge_entropy1=query_edge_entropy(node1,(<i>));
						float|object edge_entropy2=query_edge_entropy(node2,(<j>));
						float|object edge_entropy3=query_edge_entropy(node,(<i,j>));
						old_extra_entropy+=edge_entropy1+edge_entropy2-this->edge_entropy((<i>),(<j>),node1,node2,r->query_mask((<i>))[0],r->query_mask((<j>))[0]);
						extra_entropy+=edge_entropy3;
					}/*}}}*/
					if(using_global_error){
						int N=3;
						array(float) olderrsum=global_std2(indices(node2entropy));
						array(float) newerrsum=global_std2(indices(node2entropy)-({node1,node2})+({node}));
						/*
						array(float) olderrsum=({0.0})*N;
						array(float) newerrsum=({0.0})*N;
						float oldtotal=0.0;
						float newtotal=0.0;
						foreach(node2entropy;object node;float|object ig){
							object info=node->info;
							for(int i=0;i<N;i++){
								olderrsum[i]+=pow(info->stdval[i],2)*info->count;
								oldtotal+=info->count;
								if(node!=node1&&node!=node2){
									newerrsum[i]+=pow(info->stdval[i],2)*info->count;
									newtotal+=info->count;
								}
							}
						}
						for(int i=0;i<N;i++){
							object info=node->info;
							newerrsum[i]+=pow(info->stdval[i],2)*info->count;
							newtotal+=info->count;
						}
						olderrsum=map(olderrsum,`/,oldtotal);
						newerrsum=map(newerrsum,`/,newtotal);
						olderrsum=map(olderrsum,`+,1.0);
						newerrsum=map(newerrsum,`+,1.0);*/
						old_extra_entropy+=0.5*Math.log2(2*Math.pi*Math.e*(`*(1.0,@olderrsum)))*r->image->xsize()*r->image->ysize()+Math.log2(1.0*sizeof(node2entropy));
						extra_entropy+=0.5*Math.log2(2*Math.pi*Math.e*(`*(1.0,@newerrsum)))*r->image->xsize()*r->image->ysize();
						//Math.log2(1.0*sizeof(node2entropy))的含义：每个色块的位置定位靠色块的有序性来确定，有序性的商是ln(n!)，归并前后ln(n!)的差是ln(n)
					}
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
		array g_range_caches=({
				CacheLite.Cache(CACHESIZE,1),
				CacheLite.Cache(CACHESIZE,1),
				CacheLite.Cache(CACHESIZE,1),
				CacheLite.Cache(CACHESIZE,1),
				CacheLite.Cache(CACHESIZE,1)});
		MergeGraph.MergeResult query_merge_result(MergeNode first,MergeNode second)
		{
			object node1=first->node;
			object node2=second->node;
			int i=r->find(node1);
			int j=r->find(node2);
			
			mapping cache=([]);
#ifndef REMOVE_CONT_IN_ENTROPYINFO
			[object node,float ep,int entropy_count,object entropy_info]=entropy_if_merge(r,i,j,cache);
#else
			[object node,float ep,object entropy_info]=entropy_if_merge(r,i,j,cache);
#endif
			float ep1=node2entropy[node1];
			float ep2=node2entropy[node2];
			return MergeGraph.MergeResult(MergeNode(node),ep-ep1-ep2);
			
			//return MergeGraph.MergeResult(MergeNode(0,0),0.0);
		}
		private int mycount1(object node,int n)
		{
			return (node->info->valncount(n)-1)/node->info->multer+1;//XXX
		};
		private int mycount2(object node,int n)
		{
			if(n==0){
				return node->x_max-node->x_min+1;
			}else if(n==1){
				return node->y_max-node->y_min+1;
			}
		};
		MergeGraph.GlobalGain query_global_gain(MergeNode first,MergeNode second,MergeNode result,mixed global_status)/*{{{*/
		{
			object node1=first->node;
			object node2=second->node;
			object node=result->node;

			float|object extra_entropy=0.0;
			float|object old_extra_entropy=0.0;

			array old_valcounts=global_status;
			array new_valcounts=({1,1,1,1,1});
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
				for(int i=0;i<3;i++){
/*
					int count1=mycount1(node1,i);
					int count2=mycount1(node2,i);
					int count=mycount1(node,i);
					int oldmaxcount=old_valcounts[i];
					if(count1==oldmaxcount&&count<count1||count2==oldmaxcount&&count<count2){
						werror("count=%d count1=%d count2=%d oldmax=%d slowmode\n",count,count1,count2,oldmaxcount);
						new_valcounts[i]=max(0,@map(a2,mycount1,i))+1;
					}else if(count1<oldmaxcount&&count2<oldmaxcount){
						new_valcounts[i]=max(0,@map(a2,mycount1,i))+1;
						//new_valcounts[i]=max(old_valcounts[i],count);//有可能会变小
					}else{//count1>oldmaxcount||count2>oldmaxcount
						abort();
					}
*/
						new_valcounts[i]=max(0,@map(a2,mycount1,i));
				}
			}/*}}}*/
			if(using_dynamic_dxdy_precision_cost){/*{{{*/
				array a1=filter(r->a,`!=,0);
				array a2=a1-({node1,node2})+({node});

				//array old_valcounts=({0,0});
				/*for(int i=0;i<2;i++){
					old_valcounts[3+i]=g_range_caches[2+i](r->a,lambda(){
							//werror("range cache miss.\n");
							return max(0,@map(a1,mycount2,i))+1;
							});
				}*/
				//array new_valcounts=({0,0});
				for(int i=0;i<2;i++){
					new_valcounts[3+i]=max(0,@map(a2,mycount2,i));
				}
			}/*}}}*/
			extra_entropy+=Math.log2(`*(1.0,@new_valcounts))*(r->size()-1);
			old_extra_entropy+=Math.log2(`*(1.0,@old_valcounts))*r->size();
			//werror("ggain=%f\n",old_extra_entropy-extra_entropy);
			return MergeGraph.GlobalGain(old_extra_entropy-extra_entropy,new_valcounts);
		}/*}}}*/

		array query_global_status()
		{
			array a1=filter(r->a,`!=,0);
			array old_valcounts=({1,1,1,1,1});
			for(int i=0;i<3;i++){
				old_valcounts[i]=g_range_caches[i](r->a,lambda(){
						//werror("range cache miss.\n");
						return max(0,@map(a1,mycount1,i));
						});
			}
			for(int i=0;i<2;i++){
				old_valcounts[3+i]=g_range_caches[3+i](r->a,lambda(){
						//werror("range cache miss.\n");
						return max(0,@map(a1,mycount2,i));
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
			object action=((array)actions)[0];//XXX: select action

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
		//werror("%O",info);
		float entropy=info->explan_power();
		//werror("%d entropy=%f\n",sizeof(node2entropy),entropy);
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

object MultiDataReduce=CLASS(EntropyReduce,EntropyReduceMode.UsingDataList,EntropyReduceSplitMode.DataSideSplit,EntropyReduceEntropyMode.UsingAvgValue);
#ifdef MULTI_MODELS
object MultiModelReduce=CLASS(EntropyReduce,EntropyReduceMode.UsingModels,EntropyReduceSplitMode.DataSideSplit,EntropyReduceEntropyMode.UsingAvgValue);
#else
object PlaneReduce=CLASS(EntropyReduce,EntropyReduceMode.UsingPlane,EntropyReduceSplitMode.DataSideSplit,EntropyReduceEntropyMode.UsingAvgValue);
#endif
object FastReduce=CLASS(EntropyReduce,EntropyReduceMode.UsingInfoAdd,EntropyReduceSplitMode.DataSideSplit,EntropyReduceEntropyMode.UsingAvgValue);
object NDReduce=CLASS(EntropyReduce,EntropyReduceMode.UsingDataList,EntropyReduceSplitMode.DataSideSplit,EntropyReduceEntropyMode.UsingAvgValueWithNormalDistribution); /*UsingDataList*/
object OneDimReduceWithoutSpliter=CLASS(EntropyReduce,EntropyReduceMode.UsingDataList,EntropyReduceSplitMode.DataSideSplit,EntropyReduceEntropyMode.UsingDynamicRange);
object OneDimReduceWithSpliter=CLASS(EntropyReduce,EntropyReduceMode.UsingDataList,EntropyReduceSplitMode.OneDimSplit,EntropyReduceEntropyMode.UsingDynamicRange);
object OneDimReduceNoSplit=CLASS(EntropyReduce,EntropyReduceMode.UsingDataList,EntropyReduceSplitMode.NoSplit,EntropyReduceEntropyMode.UsingDynamicRange);

class SecurityData{/*{{{*/
	inherit PropertyData;
	inherit HasDynamicRange;
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
werror("scale factor=%f\n",factor);
werror("new xsize=%d\n",(int)(image0->xsize()*factor));
werror("new ysize=%d\n",(int)(image0->ysize()*factor));
if(factor<1.0){
	image0=image0->scale((int)(image0->xsize()*factor)+2,(int)(image0->ysize()*factor)+2);
}else{
	werror("skip scale.\n");
}
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

object dx_internal=DxInternalData(CUTY(dx->copy(0,0,dx->xsize()-2,dx->ysize()-1),1))->set_key("dx_internal")->set_cost(IDX*2);
object dx_left=PixelData(CUTY(dx->copy(0,0,dx->xsize()-2,dx->ysize()-1),1))->set_key("dx_left")->set_cost(IDX*2);
object dx_right=PixelData(CUTY(dx->copy(1,0,dx->xsize()-1,dx->ysize()-1),1))->set_key("dx_right")->set_cost(IDX*2);

object dy_internal=DyInternalData(CUTX(dy->copy(0,0,dy->xsize()-1,dy->ysize()-2),1))->set_key("dy_internal")->set_cost(IDX*2);
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

return (["image":image,"d0":d0,"dx_left":dx_left,"dx_right":dx_right,"dy_up":dy_up,"dy_down":dy_down,"d1x":d1x,"d1y":d1y,"multi":multi,"d2x":d2x,"d2y":d2y,"images":images,"files":file_datas,"coord":coord,"dx_internal":dx_internal,"dy_internal":dy_internal]);
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
			array a=r->query_mask((<pos>));
			//array a1=Tool()->cellgroup_mask(r,(<pos>));
			//ASSERT(equal(a,a1));
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
			[object mask]=r->query_mask((<pos>));
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
			array a=r->query_mask((<pos>));
			//array a1=Tool()->cellgroup_mask(r,(<pos>));
			//ASSERT(equal(a,a1));
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
void output_result_text(string file,object r)/*{{{*/
{
	string res="";
	mapping data=([]);
	for(int i=0;i<sizeof(r->a);i++){
		if(r->a[i]!=0){
			object cell=r->a[i];
			res+=sprintf("%d: ",i);
			if(Program.inherits(cell->info,SingleEntropyInfo)){
				foreach(cell->info->minval+cell->info->maxval,int v){
					res+=sprintf("%d ",v);
				}
			}
			res+="\n";
		}
	}
	Stdio.write_file(sprintf("output/%s.result.txt",file),res);
}/*}}}*/
void output_result(string file,object r)/*{{{*/
{
	mapping data=([]);
	for(int i=0;i<sizeof(r->a);i++){
		if(r->a[i]!=0){
			object cell=r->a[i];
			
			data[i]=(["paths":r->query_nearby(i),
					"info":cell->info->save()-(<"entity">),
					"entity":cell->info->entity?cell->info->entity->save():0,
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

object create_image_relation_map(object image,int levellimit,int|void nearby_level2)/*{{{*/
{
	int w=image->xsize();
	int h=image->ysize();
	object r=PixelRelationMap(w,h);
	if(nearby_level2)
		r->nearby_level2=1;
	werror("w=%d h=%d\n",w,h);
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
			//werror("select 0,%d,%d\n",i,j);
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
	object reducer=FastReduce();
	reducer->data_list=data_list;
	reducer->r=r;
	return reducer;
}/*}}}*/
object create_nd_reducer(object r,array data_list)/*{{{*/
{
	object reducer=NDReduce();
	reducer->data_list=data_list;
	reducer->r=r;
	reducer->using_global_error=1;
	return reducer;
}/*}}}*/
object create_multidata_reducer(object r,array data_list)/*{{{*/
{
	object reducer=MultiDataReduce();
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
	reducer->using_dynamic_colorrange_cost=0; //和set_cost有关，必须为0
	reducer->using_dynamic_dxdy_precision_cost=0; //和set_cost有关，必须为0
	reducer->using_edge_entropy=0;
	return reducer;
}/*}}}*/
object do_feed(object reducer)/*{{{*/
{
	werror("feed ...\n");
	object r=reducer->r;
	foreach(r->a;int pos;object cell)
	{
		if(cell){
			mixed e=catch{
				reducer->feed(cell);
				//werror("feed %d done\n",pos);
			};
			if(e){
				werror("%O\n",cell->query_selected());
				throw(e);
			}
		}
	}
	werror("feed done\n");
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
object create_box_relation_map(object image,int levellimit)/*{{{*/
{
	int w=image->xsize();
	int h=image->ysize();
	object r=PixelEdgeRelationMap(w,h);
	werror("create cells ...\n");
	PROFILING_BEGIN("create_cells")
	for(int i=0;i<w;i++){
		for(int j=0;j<h;j++){
			object cell;
			/*
			if(i+1<w&&j+1<h){
				cell=PixelNode(1,1,image->xsize(),image->ysize());
				cell->select(0,i,j);
				cell->select(0,i+1,j);
				cell->select(0,i,j+1);
				cell->select(0,i+1,j+1);
				r->add(cell);
			}
			*/
			if(i+1<w&&j+1<h){
				cell=PixelNode(1,1,image->xsize(),image->ysize());
				cell->select(0,i,j);
				cell->select(0,i+1,j);
				cell->select(0,i,j+1);
				r->add(cell);
			}
			if(i+1<w&&j-1>=0){
				cell=PixelNode(1,1,image->xsize(),image->ysize());
				cell->select(0,i,j);
				cell->select(0,i+1,j);
				cell->select(0,i,j-1);
				r->add(cell);
			}
			if(i-1>=0&&j+1<h){
				cell=PixelNode(1,1,image->xsize(),image->ysize());
				cell->select(0,i,j);
				cell->select(0,i-1,j);
				cell->select(0,i,j+1);
				r->add(cell);
			}
			if(i-1>=0&&j-1>0){
				cell=PixelNode(1,1,image->xsize(),image->ysize());
				cell->select(0,i,j);
				cell->select(0,i-1,j);
				cell->select(0,i,j-1);
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

object read_image(string target1,int levellimit)
{
	object image0=Image.BMP.decode(Stdio.read_file(target1));
	object image1;
	float factor=pow(2.0,levellimit)/max(image0->xsize(),image0->ysize());
	if(factor<1.0){
		image0=image0->scale((int)(image0->xsize()*factor)+2,(int)(image0->ysize()*factor)+2);
	}else{
		werror("skip scale.\n");
	}
	image1=image0->copy(1,1,image0->xsize()-2,image0->ysize()-2);
	return image1;
}

class SigmaER{
	mapping atom2nearby=([]);
	mapping m=([]);
	mapping id2sigma=([]);
	void create(multiset edges,mapping id2atom)
	{
		foreach(edges;int k;int ig){
			[int id1,int id2]=mydecode(k);
			foreach(({({id1,id2}),({id2,id1})}),[int id1,int id2]){
				atom2nearby[id2atom[id1]]=atom2nearby[id2atom[id1]]||(<>);
				atom2nearby[id2atom[id1]][id2atom[id2]]=1;
			}
		}
		int t=1;
		foreach(atom2nearby;object atom;multiset ig){
			m[atom]=t;
			id2sigma[t]=Sigma.Sigma(({
						atom->avgval+atom->sigma*({})
						}),1);
			t++;
		}
	}
}

class ERMRF2L{
	inherit IdImageTool;
	int w,h;
	array idimages;
	array ms;
	//mapping id2count=([]);
	mapping id2nearby=([]);
	array pair2counts=({([]),([])});
	multiset edges=(<>);
	mapping edge2poslist=([]);
	array id2sigmas=({([]),([])});
	mapping id2sigma=([]);
	array id2possigmas=({([]),([])});
	array datas;
	object modeldelta_sigma;
	object color_error_sigma;
	object color_mean_sigma;
	object color_delta_sigma;
	object edge_sigma;

	class Atom{/*{{{*/
		object sigma;
		array sigmas;
		array possigmas;
		array poslist;
		multiset edgelist;
	}/*}}}*/
	class PixelAtom(int k,int x,int y){/*{{{*/
		inherit Atom;
		constant is_pixel_atom=1;
		void create()
		{
			poslist=({({k,x,y})});
			array color=datas[k]->data->getpixel(x,y);
			sigma=color_atom_sigmas[k][x][y];
			if(k==0){
				possigmas=({pos_atom_sigmas[k][x][y],0});
				sigmas=({color_atom_sigmas[k][x][y],0});
			}
			else if(k==1){
				possigmas=({0,pos_atom_sigmas[k][x][y]});
				sigmas=({0,color_atom_sigmas[k][x][y]});
			}
			edgelist=(<>);
			if(x>0){ 
				edgelist[myencode_edgepos(k,x,y,x-1,y)]=1;
			}
			if(x<w-1){ 
				edgelist[myencode_edgepos(k,x,y,x+1,y)]=1;
			}
			if(y>0){ 
				edgelist[myencode_edgepos(k,x,y,x,y-1)]=1;
			}
			if(y<h-1){ 
				edgelist[myencode_edgepos(k,x,y,x,y+1)]=1;
			}
		}
	}/*}}}*/
	class BlockAtom(int id){/*{{{*/
		inherit Atom;
		constant is_block_atom=1;
		void create()
		{
			for(int k=0;k<1;k++){
				for(int i=0;i<w;i++){
					for(int j=0;j<h;j++){
						if(ms[k][i][j]==id){
							poslist+=({({k,i,j})});
						}
					}
				}
			}
			sigma=id2sigma[id];
			possigmas=({id2possigmas[0][id],id2possigmas[1][id]});
			sigmas=({id2sigmas[0][id],id2sigmas[1][id]});
			edgelist=(<>);
			foreach(id2nearby[id];int id1;int ig){
				edgelist=edgelist|edge2poslist[myencode(@sort(({id,id1})))];
			}
		}
	}/*}}}*/


	void remove_nearby(int id1,int id2)/*{{{*/
	{
		if(id1!=id2){
			foreach(({({id1,id2}),({id2,id1})}),[int id1,id2]){
				id2nearby[id1][id2]--;
				if(id2nearby[id1][id2]==0)
					m_delete(id2nearby[id1],id2);
				if(sizeof(id2nearby[id1])==0)
					m_delete(id2nearby,id1);
			}
		}
	}/*}}}*/
	void add_nearby(int id1,int id2)/*{{{*/
	{
		if(id1!=id2){
			foreach(({({id1,id2}),({id2,id1})}),[int id1,id2]){
				id2nearby[id1]=id2nearby[id1]||([]);;
				id2nearby[id1][id2]++;
			}
		}
	}/*}}}*/
	mapping backup_status()/*{{{*/
	{
		mapping res=([]);
		res->idimages=map(idimages,"clone");
		res->ms=copy_value(ms);
		//res->id2count=copy_value(id2count);
		res->pair2counts=copy_value(pair2counts);
		res->edges=copy_value(edges);
		res->id2sigmas=copy_value(id2sigmas);
		res->id2sigma=copy_value(id2sigma);
		res->id2possigmas=copy_value(id2possigmas);
		res->modeldelta_sigma=modeldelta_sigma;
		res->edge_sigma=edge_sigma;
		return res;
	}/*}}}*/
	void check_status(mapping m)/*{{{*/
	{
		assert(m->idimages[0]==idimages[0]);
		assert(m->idimages[1]==idimages[1]);
		assert(equal(m->ms,ms));
		//assert(equal(m->id2count,id2count));
		assert(equal(m->pair2counts,pair2counts));
		assert(equal(m->edges,edges));
		for(int k=0;k<=1;k++){
			foreach(indices(id2sigmas[k])|indices(m->id2sigmas[k]),int id){
				assert(m->id2sigmas[k][id]==id2sigmas[k][id]);
			}
			foreach(indices(id2possigmas[k])|indices(m->id2possigmas[k]),int id){
				assert(m->id2possigmas[k][id]==id2possigmas[k][id]);
			}
		}
		foreach(indices(id2sigma)|indices(m->id2sigma),int id){
			assert(m->id2sigma[id]==id2sigma[id]);
		}
		assert(m->modeldelta_sigma==modeldelta_sigma);
		assert(m->edge_sigma==edge_sigma);
	}/*}}}*/

	//DEBUG
	//array edge_sigma_init_list;
	//multiset edge_sigma_init_edges;
	//array id2sigmas_init;

	//OPT
	array color_atom_sigmas;
	array pos_atom_sigmas;

	array edgedelta_list(int kk)/*{{{*/
	{
		array list=({});
		//sscanf(kk,"%d,%d",int id1,int id2);
		[int id1,int id2]=mydecode(kk);
		if(id2possigmas[1][id1]&&id2possigmas[0][id1]
				&&id2possigmas[1][id2]&&id2possigmas[0][id2]){
			list+=({({diffa(id2sigma[id1]->avgval,id2sigma[id2]->avgval),
						diffa((id2possigmas[1][id1]->avgval[*]-id2possigmas[0][id1]->avgval[*]),
							(id2possigmas[1][id2]->avgval[*]-id2possigmas[0][id2]->avgval[*]))
						})});
			//werror("%O",list);
		}
		return list;
	};/*}}}*/
		object create_modeldelta_sigma()/*{{{*/
		{
			array list=({});
			foreach(id2sigma;int id;object ig){
				[mapping modelbefore,int totalbefore]=get_model(id,0);
				[mapping modelafter,int totalafter]=get_model(id,1);
				list+=modeldelta_list(modelbefore,totalbefore,modelafter,totalafter);
			}
			return Sigma.SIGMA(list);
		}/*}}}*/
	void create(object dr,object data1,object data2,mapping id2dx,mapping id2dy,mapping id2frontlist)/*{{{*/
	{
		datas=({data1,data2});
		w=dr->image->xsize();
		h=dr->image->ysize();
		idimages=({Image.Image(w,h,0,0,0),Image.Image(w,h,0,0,0)});
		color_atom_sigmas=allocate(2,allocate(w,allocate(h,0)));
		pos_atom_sigmas=allocate(2,allocate(w,allocate(h,0)));
		object idt=this;
		array(array) m0=allocate(w,allocate(h,-1));
		array(array) m=allocate(w,allocate(h,-1));
		array sw;
		mapping id2swidx,swidx2id;
		int maxid=-1;
		//初始化image1的像素分类表m0/*{{{*/
		void fill_m0(int id)/*{{{*/
		{
			object cell=dr->a[id];
			foreach(cell->query_selected(),[int k,int i,int j]){
				m0[i][j]=id;
				array color=id2color(id);
				idimages[0]->setpixel(i,j,@color);
			}
		};/*}}}*/
		foreach(dr->a;int id;object cell){/*{{{*/
			if(cell){
				fill_m0(id);
				maxid=max(maxid,id);
			}
		}/*}}}*//*}}}*/
		//初始化image2的像素分类表m为独立id
		for(int i=0;i<w;i++){/*{{{*/
			for(int j=0;j<h;j++){
				m[i][j]=++maxid;
				idimages[1]->setpixel(i,j,@id2color(m[i][j]));
			}
		}/*}}}*/
		ms=({m0,m});
		//初始化id2count,pair2counts,edges
		for(int k=0;k<2;k++){/*{{{*/
			for(int i=0;i<w;i++){
				for(int j=0;j<h;j++){
					int id=ms[k][i][j];
					//id2count[id]++;
					if(i<w-1){
						int id1=ms[k][i+1][j];
						add_nearby(id,id1);
						//id2nearby[id][id1]++;
						pair2counts[k][myencode(@sort(({id,id1})))]++;
						if(id1!=id) {
							int kk=myencode(@sort(({id,id1})));
							edges[kk]=1;
							edge2poslist[kk]=edge2poslist[kk]||(<>);
							edge2poslist[kk][myencode_edgepos(k,i,j,i+1,j)]=1;
						}
					}
					if(j<h-1){
						int id1=ms[k][i][j+1];
						add_nearby(id,id1);
						//id2nearby[id][id1]++;
						pair2counts[k][myencode(@sort(({id,id1})))]++;
						if(id1!=id) {
							int kk=myencode(@sort(({id,id1})));
							edges[kk]=1;
							edge2poslist[kk]=edge2poslist[kk]||(<>);
							edge2poslist[kk][myencode_edgepos(k,i,j,i,j+1)]=1;
						}
					}
				}
			}
		}/*}}}*/
		sw=allocate(sizeof(edges),1);
		id2swidx=mkmapping(sort(indices(edges)),indices(sw));
		swidx2id=mkmapping(values(id2swidx),indices(id2swidx));

		//id2sigmas
		//array id2sigmas=({([]),([])});
		for(int i=0;i<w;i++){
			for(int j=0;j<h;j++){
				for(int k=0;k<2;k++){
					int id=ms[k][i][j];
					array color=datas[k]->data->getpixel(i,j);
					color_atom_sigmas[k][i][j]=Sigma.SIGMA(({color}),1);
					pos_atom_sigmas[k][i][j]=Sigma.SIGMA(({({i,j})}),1);
					if(id2sigmas[k][id]==0){
						id2sigmas[k][id]=color_atom_sigmas[k][i][j];
						id2possigmas[k][id]=pos_atom_sigmas[k][i][j];
					}else{
						id2sigmas[k][id]+=color_atom_sigmas[k][i][j];
						id2possigmas[k][id]+=pos_atom_sigmas[k][i][j];
					}
				}
			}
		}
		for(int i=0;i<w;i++){
			for(int j=0;j<h;j++){
				for(int k=0;k<2;k++){
					int id=ms[k][i][j];
					if(id2sigma[id]==0){
						id2sigma[id]=id2sigmas[0][id]+id2sigmas[1][id];
						ASSERT(id2sigma[id]->abs()>-1e-9);
					}
				}
			}
		}
		color_error_sigma=0;
		for(int k=0;k<=1;k++){
			foreach(id2sigmas[k];int id;object sigma){
				color_error_sigma+=sigma->zero_mean();
			}
		}
		/*foreach(id2sigma;int id;object sigma){
			color_error_sigma+=sigma->zero_mean();
		}*/
		color_mean_sigma=0;
		foreach(id2sigma;int id;object sigma){
			color_mean_sigma+=Sigma.SIGMA(({sigma->avgval}),1);
		}
		color_delta_sigma=0;
		foreach(id2sigma;int id;object sigma){
			if(id2sigmas[0][id]&&id2sigmas[1][id]){
				color_delta_sigma+=Sigma.SIGMA(({id2sigmas[1][id]->avgval[*]-id2sigmas[0][id]->avgval[*]}),1);
				color_delta_sigma+=Sigma.SIGMA(({id2sigmas[0][id]->avgval[*]-id2sigmas[1][id]->avgval[*]}),1);
			}else if(id2sigma[id]){
				//color_delta_sigma+=Sigma.SIGMA(({({0,0,0})}),1);
			}
		}
		//id2sigmas_init=copy_value(id2sigmas);

		modeldelta_sigma=create_modeldelta_sigma();

		//将image2与image1归并/*{{{*/
		//multiset working=(<>);
#if 0
		void fill_m(int id,int over)/*{{{*/
		{
			if(working[id])
				return;
			working[id]=1;
			object cell=dr->a[id];
			foreach(cell->query_selected(),[int k,int i,int j]){
				int i2=i+id2dx[id];
				int j2=j+id2dy[id];
				if(i2>=0&&i2<w&&j2>=0&&j2<h&&m[i2][j2]==over){
					m[i2][j2]=id;
					array color=id2color(id);
					idimages[1]->setpixel(i2,j2,@color);
				}
			}
			foreach(id2frontlist[id]||({}),int id2){
				fill_m(id2,over==-1?id:over);
			}
			working[id]=0;
		};/*}}}*/
#endif
		int found;
		int t;
		do{
			found=0;
			foreach(dr->a;int id;object cell){
				if(cell){
					foreach(cell->query_selected(),[int k,int i,int j]){
						int i2=i+id2dx[id];
						int j2=j+id2dy[id];
						if(i2>=0&&i2<w&&j2>=0&&j2<h){
							werror("init %d %d\n",i,j);
							found+=reduce_one(1,i2,j2,get_nearby_ids(id,0)|(<id>),(<>));
							werror("t=%d found=%d\n",t,found);
						}
					}
				}
			}
			t++;
		}while(found);
#if 0
		//用最接近的像素初始化未知像素
		array(array) mm=allocate(w,allocate(h,-1));
		int find_near(int x,int y)/*{{{*/
		{
			int check(int i,int j)
			{
				if(i>=0&&i<w&&j>=0&&j<h){
					return m[i][j];
				}
				return -1;
			};
			int res;
			for(int k=1;k<max(w,h);k++){
				for(int i=x-k;i<=x+k;i++){
					res=check(i,y-k);
					if(res!=-1) return res;
					res=check(i,y+k);
					if(res!=-1) return res;
				}
				for(int i=y-k+1;i<=y+k-1;i++){
					res=check(x-k,i);
					if(res!=-1) return res;
					res=check(x+k,i);
					if(res!=-1) return res;
				}
			}
		};/*}}}*/
		for(int i=0;i<w;i++){/*{{{*/
			for(int j=0;j<h;j++){
				if(m[i][j]==-1){
					mm[i][j]=find_near(i,j);
				}
			}
		}/*}}}*/
		for(int i=0;i<w;i++){/*{{{*/
			for(int j=0;j<h;j++){
				if(m[i][j]==-1){
					m[i][j]=mm[i][j];
					idimages[1]->setpixel(i,j,@id2color(m[i][j]));
				}
			}
		}/*}}}*//*}}}*/

		//不需要初始化edge_sigma了
#if 0
		//edge_sigma
		do{/*{{{*/
			array list=map(indices(edges),edgedelta_list)*({});
			edge_sigma=Sigma.SIGMA(list,0/*,count*/);
			/*array list=({});
			//array count=({});
			foreach(edges;int kk;int ig){
				//werror("%s\n",kk);
				list+=edgedelta_list(kk);
				//count+=({pair2counts[0][kk]+pair2counts[1][kk]});
			}*/
			//edge_sigma_init_list=list;
			//edge_sigma_init_edges=edges;
			//werror("%O\n",edge_sigma->sigma);
			//werror("%O\n",edge_sigma->abs());
			//exit(0);
		}while(0);/*}}}*/
#endif

#endif
	}/*}}}*/
	int atom2id(object atom)/*{{{*/
	{
		if(atom->is_pixel_atom){
			int k=atom->k;
			int x=atom->x;
			int y=atom->y;
			return ms[k][x][y];
		}else if(atom->is_block_atom){
			int id=atom->id;
			return id;
		}
	}/*}}}*/
	void atom_set_id(object atom,int id)/*{{{*/
	{
		int oldid;
		multiset our=(<>);
		foreach(atom->poslist,[int k,int x,int y]){
			oldid=ms[k][x][y];
			ms[k][x][y]=id;
			idimages[k]->setpixel(x,y,@id2color(id));
			our[myencode(x,y)]=1;
			//pixel_update_edges(k,x,y,oldid,id);//XXX slow
		}
		foreach(atom->edgelist;int kk;int ig){
			[int k,int x1,int y1,int x2,int y2]=mydecode_edgepos(kk);
			if(our[myencode(x1,y1)])
				update_edge(k,x1,y1,x2,y2,oldid,id);
			else
				update_edge(k,x2,y2,x1,y1,oldid,id);
		}
	}/*}}}*/
	void update_edge(int k,int x,int y,int x1,int y1,int oldid,int id)/*{{{*/
	{
		int k1=myencode(@sort(({oldid,ms[k][x1][y1]})));
		int k2=myencode(@sort(({id,ms[k][x1][y1]})));
		remove_nearby(oldid,ms[k][x1][y1]);
		add_nearby(id,ms[k][x1][y1]);
		pair2counts[k][k1]--;
		if(pair2counts[k][k1]==0) m_delete(pair2counts[k],k1); 
		pair2counts[k][k2]++;
		edge2poslist[k1]=edge2poslist[k1]||(<>);
		edge2poslist[k2]=edge2poslist[k2]||(<>);
		edge2poslist[k1][myencode_edgepos(k,x,y,x1,y1)]=0;
		edge2poslist[k2][myencode_edgepos(k,x,y,x1,y1)]=1;
		if(pair2counts[0][k1]==0&&pair2counts[1][k1]==0)
			edges[k1]=0;
		if(!`==(@(mydecode(k2))))
			edges[k2]=1;
	}/*}}}*/
	void pixel_update_edges(int k,int x,int y,int oldid,int id)/*{{{*/
	{
		if(x>0){ 
			int k1=myencode(@sort(({oldid,ms[k][x-1][y]})));
			int k2=myencode(@sort(({id,ms[k][x-1][y]})));
			remove_nearby(oldid,ms[k][x-1][y]);
			add_nearby(id,ms[k][x-1][y]);
			pair2counts[k][k1]--;
			if(pair2counts[k][k1]==0) m_delete(pair2counts[k],k1); 
			pair2counts[k][k2]++;
		edge2poslist[k1]=edge2poslist[k1]||(<>);
		edge2poslist[k2]=edge2poslist[k2]||(<>);
			edge2poslist[k1][myencode_edgepos(k,x,y,x-1,y)]=0;
			edge2poslist[k2][myencode_edgepos(k,x,y,x-1,y)]=1;
			if(pair2counts[0][k1]==0&&pair2counts[1][k1]==0)
				edges[k1]=0;
			if(!`==(@(mydecode(k2))))
				edges[k2]=1;
		}
		if(x<w-1){ 
			int k1=myencode(@sort(({oldid,ms[k][x+1][y]})));
			int k2=myencode(@sort(({id,ms[k][x+1][y]})));
			remove_nearby(oldid,ms[k][x+1][y]);
			add_nearby(id,ms[k][x+1][y]);
			pair2counts[k][k1]--;
			if(pair2counts[k][k1]==0) m_delete(pair2counts[k],k1); 
			pair2counts[k][k2]++;
		edge2poslist[k1]=edge2poslist[k1]||(<>);
		edge2poslist[k2]=edge2poslist[k2]||(<>);
			edge2poslist[k1][myencode_edgepos(k,x,y,x+1,y)]=0;
			edge2poslist[k2][myencode_edgepos(k,x,y,x+1,y)]=1;
			if(pair2counts[0][k1]==0&&pair2counts[1][k1]==0)
				edges[k1]=0;
			if(!`==(@(mydecode(k2))))
				edges[k2]=1;
		}
		if(y>0){ 
			int k1=myencode(@sort(({oldid,ms[k][x][y-1]})));
			int k2=myencode(@sort(({id,ms[k][x][y-1]})));
			remove_nearby(oldid,ms[k][x][y-1]);
			add_nearby(id,ms[k][x][y-1]);
			pair2counts[k][k1]--;
			if(pair2counts[k][k1]==0) m_delete(pair2counts[k],k1); 
			pair2counts[k][k2]++;
		edge2poslist[k1]=edge2poslist[k1]||(<>);
		edge2poslist[k2]=edge2poslist[k2]||(<>);
			edge2poslist[k1][myencode_edgepos(k,x,y,x,y-1)]=0;
			edge2poslist[k2][myencode_edgepos(k,x,y,x,y-1)]=1;
			if(pair2counts[0][k1]==0&&pair2counts[1][k1]==0)
				edges[k1]=0;
			if(!`==(@(mydecode(k2))))
				edges[k2]=1;
		}
		if(y<h-1){ 
			int k1=myencode(@sort(({oldid,ms[k][x][y+1]})));
			int k2=myencode(@sort(({id,ms[k][x][y+1]})));
			remove_nearby(oldid,ms[k][x][y+1]);
			add_nearby(id,ms[k][x][y+1]);
			pair2counts[k][k1]--;
			if(pair2counts[k][k1]==0) m_delete(pair2counts[k],k1); 
			pair2counts[k][k2]++;
		edge2poslist[k1]=edge2poslist[k1]||(<>);
		edge2poslist[k2]=edge2poslist[k2]||(<>);
			edge2poslist[k1][myencode_edgepos(k,x,y,x,y+1)]=0;
			edge2poslist[k2][myencode_edgepos(k,x,y,x,y+1)]=1;
			if(pair2counts[0][k1]==0&&pair2counts[1][k1]==0)
				edges[k1]=0;
			if(!`==(@(mydecode(k2))))
				edges[k2]=1;
		}
	}/*}}}*/
	void if_change_label(object atom,int id,int noback,function f)/*{{{*/
	{
#if 0
		assert(atom->is_pixel_atom);
		int k=atom->k;
		int x=atom->x;
		int y=atom->y;
		array color=datas[k]->data->getpixel(x,y);
		object sigma=color_atom_sigmas[k][x][y];
		object possigma=pos_atom_sigmas[k][x][y];
#endif
		[object sigma,array sigmas,array possigmas]=({atom->sigma,atom->sigmas,atom->possigmas});

		int oldid=atom2id(atom);//ms[k][x][y];
		multiset nearby1=my_id2nearby(oldid);//get_nearby_ids(oldid,0)|get_nearby_ids(oldid,1);
		multiset nearby2=my_id2nearby(id);//get_nearby_ids(id,0)|get_nearby_ids(id,1);
#if 0
		object old_modeldelta_sigma=modeldelta_sigma;
		//modeldelta_sigma
		do{/*{{{*/
			array list=({});
			foreach(nearby1|nearby2|(<oldid,id>);int id;int ig){
				[mapping modelbefore,int totalbefore]=get_model(id,0);
				[mapping modelafter,int totalafter]=get_model(id,1);
				list+=modeldelta_list(modelbefore,totalbefore,modelafter,totalafter);
			}
			modeldelta_sigma=modeldelta_sigma->sub(Sigma.SIGMA(list));
			werror("modeldelta_sigma(-) = %O\n",modeldelta_sigma->sigma);
		}while(0);/*}}}*/
#endif
		object old_edge_sigma=edge_sigma;
		//edge_sigma
		do{/*{{{*/
			array list=({});
			//array count=({});
			multiset done=(<>);
			foreach(({({nearby1,oldid}),({nearby2,id})}),[multiset nearby,int id]){
				foreach(nearby;int id2;int ig){
					int kk=myencode(@sort(({id,id2})));
					ASSERT(edges[kk]);
					if(!done[kk]){
						list+=edgedelta_list(kk);
						//count+=pair2counts[0][kk]+pair2counts[1][kk];
						done[kk]=1;
					}
				}
			}

			if(sizeof(list))
				edge_sigma=edge_sigma->sub(Sigma.SIGMA(list,1/*,count*/));
#if 0
			ASSERT(edge_sigma->abs()>0,/*lambda(){
					multiset matched=(<>);
					foreach(list,array a){
						int found=0;
						foreach(edge_sigma_init_list,array b){
							if(equal(a,b)){
								matched[b]=1;
								found=1;
								break;
							}
						}
						if(!found){
							werror("bad list item: %O\n",a);
						}
					}
					object sigma0=Sigma.SIGMA(edge_sigma_init_list,0);
					object sigma1=Sigma.SIGMA(list,0);
					object sigma2=Sigma.SIGMA(edge_sigma_init_list-(array)matched,0);
					object sigma3=sigma0-sigma1;
					werror("should be: %O\n",sigma2->sigma);
					werror("but : %O\n",sigma3->sigma);
					werror("old should: %O\n",sigma0->sigma);
					werror("old : %O\n",old_edge_sigma->sigma);
					}*/);
#endif
		}while(0);/*}}}*/
		//ms[k][x][y]=id;
		atom_set_id(atom,id);
		//id2count[oldid]--;
		//if(id2count[oldid]==0) m_delete(id2count,oldid);
		//id2count[id]++;
		array oldsigma1=({id2sigmas[0][oldid],id2sigmas[1][oldid]});
		array oldsigma2=({id2sigmas[0][id],id2sigmas[1][id]});
		object oldgsigma1=id2sigma[oldid];
		object oldgsigma2=id2sigma[id];
		object old_color_error_sigma=color_error_sigma;
		for(int k=0;k<=1;k++){
			if(id2sigmas[k][oldid]){
				color_error_sigma-=id2sigmas[k][oldid]->zero_mean();
			}
			//color_error_sigma-=id2sigma[oldid]->zero_mean();
		}
		for(int k=0;k<=1;k++){
			if(id2sigmas[k][id]){
				color_error_sigma-=id2sigmas[k][id]->zero_mean();
			}
			//color_error_sigma-=id2sigma[id]->zero_mean();
		}
		object old_color_mean_sigma=color_mean_sigma;
		if(id2sigma[oldid])
			color_mean_sigma-=Sigma.SIGMA(({id2sigma[oldid]->avgval}),1);
		if(id2sigma[id])
			color_mean_sigma-=Sigma.SIGMA(({id2sigma[id]->avgval}),1);

		object old_color_delta_sigma=color_delta_sigma;
		foreach(({oldid,id}),int id){
			if(id2sigmas[0][id]&&id2sigmas[1][id]){
				color_delta_sigma-=Sigma.SIGMA(({id2sigmas[1][id]->avgval[*]-id2sigmas[0][id]->avgval[*]}),1);
				color_delta_sigma-=Sigma.SIGMA(({id2sigmas[0][id]->avgval[*]-id2sigmas[1][id]->avgval[*]}),1);
			}else if(id2sigma[id]){
				//color_delta_sigma-=Sigma.SIGMA(({({0,0,0})}),1);
			}
		}

		id2sigmas[0][oldid]=oldsigma1[0]-sigmas[0];
		id2sigmas[0][id]=oldsigma2[0]+sigmas[0];
		id2sigmas[1][oldid]=oldsigma1[1]-sigmas[1];
		id2sigmas[1][id]=oldsigma2[1]+sigmas[1];
		id2sigma[oldid]=oldgsigma1-sigma;
		if(id2sigma[oldid]==0) m_delete(id2sigma,oldid);
		id2sigma[id]=oldgsigma2+sigma;
		for(int k=0;k<=1;k++){
			if(id2sigmas[k][oldid]){
				color_error_sigma+=id2sigmas[k][oldid]->zero_mean();
			}
			//color_error_sigma+=id2sigma[oldid]->zero_mean();
		}
		for(int k=0;k<=1;k++){
			if(id2sigmas[k][id]){
				color_error_sigma+=id2sigmas[k][id]->zero_mean();
			}
			//color_error_sigma+=id2sigma[id]->zero_mean();
		}
		if(id2sigma[oldid])
			color_mean_sigma+=Sigma.SIGMA(({id2sigma[oldid]->avgval}),1);
		if(id2sigma[id])
			color_mean_sigma+=Sigma.SIGMA(({id2sigma[id]->avgval}),1);
		foreach(({oldid,id}),int id){
			if(id2sigmas[0][id]&&id2sigmas[1][id]){
				color_delta_sigma+=Sigma.SIGMA(({id2sigmas[1][id]->avgval[*]-id2sigmas[0][id]->avgval[*]}),1);
				color_delta_sigma+=Sigma.SIGMA(({id2sigmas[0][id]->avgval[*]-id2sigmas[1][id]->avgval[*]}),1);
			}else if(id2sigma[id]){
				//color_delta_sigma+=Sigma.SIGMA(({({0,0,0})}),1);
			}
		}

		array oldpossigma1=({id2possigmas[0][oldid],id2possigmas[1][oldid]});
		array oldpossigma2=({id2possigmas[0][id],id2possigmas[1][id]});
		id2possigmas[0][oldid]=oldpossigma1[0]-possigmas[0];
		id2possigmas[0][id]=oldpossigma2[0]+possigmas[0];
		id2possigmas[1][oldid]=oldpossigma1[1]-possigmas[1];
		id2possigmas[1][id]=oldpossigma2[1]+possigmas[1];

		nearby1=my_id2nearby(oldid);//get_nearby_ids(oldid,0)|get_nearby_ids(oldid,1);
		nearby2=my_id2nearby(id);//get_nearby_ids(id,0)|get_nearby_ids(id,1);
#if 0
		//modeldelta_sigma
		do{/*{{{*/
			array list=({});
			foreach(nearby1|nearby2|(<oldid,id>);int id;int ig){
				[mapping modelbefore,int totalbefore]=get_model(id,0);
				[mapping modelafter,int totalafter]=get_model(id,1);
				list+=modeldelta_list(modelbefore,totalbefore,modelafter,totalafter);
			}
			if(sizeof(list))
				modeldelta_sigma=modeldelta_sigma+Sigma.SIGMA(list);
			object check=create_modeldelta_sigma();
			werror("modeldelta_sigma(+) = %O\n",modeldelta_sigma->sigma);
			werror("           check(+) = %O\n",check->sigma);
		}while(0);/*}}}*/
#endif
		//edge_sigma
		do{/*{{{*/
			array list=({});
			//array count=({});
			multiset done=(<>);
			foreach(({({nearby1,oldid}),({nearby2,id})}),[multiset nearby,int id]){
				foreach(nearby;int id2;int ig){
					int kk=myencode(@sort(({id,id2})));
					ASSERT(edges[kk]);
					if(!done[kk]){
						list+=edgedelta_list(kk);
						//count+=pair2counts[0][kk]+pair2counts[1][kk];
						done[kk]=1;
					}
				}
			}

			if(sizeof(list)){
				edge_sigma=edge_sigma+Sigma.SIGMA(list,1/*,count*/);
			}
#if 0
			ASSERT(edge_sigma->abs()>0);
#endif
		}while(0);/*}}}*/
		//array list=map(indices(edges),edgedelta_list)*({});
		//edge_sigma=Sigma.SIGMA(list,0/*,count*/);

		f();
		if(!noback){
			atom_set_id(atom,oldid);
			//ms[k][x][y]=oldid;
			//id2count[oldid]++;
			//id2count[id]--;
			//if(id2count[id]==0) m_delete(id2count,id);
			id2sigmas[0][oldid]=oldsigma1[0];
			id2sigmas[0][id]=oldsigma2[0];
			id2sigmas[1][oldid]=oldsigma1[1];
			id2sigmas[1][id]=oldsigma2[1];
			id2sigma[oldid]=oldgsigma1;
			if(id2sigma[oldid]==0) m_delete(id2sigma,oldid);
			id2sigma[id]=oldgsigma2;
			if(id2sigma[id]==0) m_delete(id2sigma,id);
			color_error_sigma=old_color_error_sigma;
			color_mean_sigma=old_color_mean_sigma;
			color_delta_sigma=old_color_delta_sigma;
			id2possigmas[0][oldid]=oldpossigma1[0];
			id2possigmas[0][id]=oldpossigma2[0];
			id2possigmas[1][oldid]=oldpossigma1[1];
			id2possigmas[1][id]=oldpossigma2[1];
			/*if(x>0){ 
				int k1=myencode(@sort(({oldid,ms[k][x-1][y]})));
				int k2=myencode(@sort(({id,ms[k][x-1][y]})));
				remove_nearby(id,ms[k][x-1][y]);
				add_nearby(oldid,ms[k][x-1][y]);
				pair2counts[k][k1]++;
				pair2counts[k][k2]--;
				if(pair2counts[k][k2]==0) m_delete(pair2counts[k],k2); 
				if(pair2counts[0][k2]==0&&pair2counts[1][k2]==0)
					edges[k2]=0;
				if(!`==(@(mydecode(k1))))
					edges[k1]=1;
			}
			if(x<w-1){ 
				int k1=myencode(@sort(({oldid,ms[k][x+1][y]})));
				int k2=myencode(@sort(({id,ms[k][x+1][y]})));
				remove_nearby(id,ms[k][x+1][y]);
				add_nearby(oldid,ms[k][x+1][y]);
				pair2counts[k][k1]++;
				pair2counts[k][k2]--;
				if(pair2counts[k][k2]==0) m_delete(pair2counts[k],k2); 
				if(pair2counts[0][k2]==0&&pair2counts[1][k2]==0)
					edges[k2]=0;
				if(!`==(@(mydecode(k1))))
					edges[k1]=1;
			}
			if(y>0){ 
				int k1=myencode(@sort(({oldid,ms[k][x][y-1]})));
				int k2=myencode(@sort(({id,ms[k][x][y-1]})));
				remove_nearby(id,ms[k][x][y-1]);
				add_nearby(oldid,ms[k][x][y-1]);
				pair2counts[k][k1]++;
				pair2counts[k][k2]--;
				if(pair2counts[k][k2]==0) m_delete(pair2counts[k],k2); 
				if(pair2counts[0][k2]==0&&pair2counts[1][k2]==0)
					edges[k2]=0;
				if(!`==(@(mydecode(k1))))
					edges[k1]=1;
			}
			if(y<h-1){ 
				int k1=myencode(@sort(({oldid,ms[k][x][y+1]})));
				int k2=myencode(@sort(({id,ms[k][x][y+1]})));
				remove_nearby(id,ms[k][x][y+1]);
				add_nearby(oldid,ms[k][x][y+1]);
				pair2counts[k][k1]++;
				pair2counts[k][k2]--;
				if(pair2counts[k][k2]==0) m_delete(pair2counts[k],k2); 
				if(pair2counts[0][k2]==0&&pair2counts[1][k2]==0)
					edges[k2]=0;
				if(!`==(@(mydecode(k1))))
					edges[k1]=1;
			}*/
#if 0
			modeldelta_sigma=old_modeldelta_sigma;
#endif
			edge_sigma=old_edge_sigma;
		}
	};/*}}}*/
	array expand_coord(int w,int h,int x,int y){/*{{{*/
		array res=({});
		if(x>0) res+=({({x-1,y})});
		if(x<w-1) res+=({({x+1,y})});
		if(y>0) res+=({({x,y-1})});
		if(y<h-1) res+=({({x,y+1})});
		return res;
	}/*}}}*/
	int reduce_one(int k,int x,int y,multiset ids,multiset todo){/*{{{*/
		int oldid=ms[k][x][y];
		float me=0.0;
		function if_change;
		array if_change_args;
		int maxid=-1;
		/*multiset ids=my_id2nearby(oldid);//get_nearby_ids(oldid,0)|get_nearby_ids(oldid,1);
		multiset ids2=(<>);
		foreach(ids;int id;int ig){
			ids2[id]=1;
			ids2=ids2|my_id2nearby(id);
		}*/
		foreach(ids;int id;int ig){
			//int count=id2count[id];
			int count=id2sigma[id]->n;
			//werror(".");
			maxid=max(maxid,id);
			if(count){
				if(id==oldid)
					continue;
				[float e,function type,array args]=try_change_label(PixelAtom(k,x,y),oldid,id);
				if(e>me){
					me=e;
					if_change=type;
					if_change_args=args;
				}
			}
		}
		
		[float e,function type,array args]=try_change_label(PixelAtom(k,x,y),oldid,maxid+1);
		if(e>me){
			me=e;
			if_change=type;
			if_change_args=args;
		}


		if(if_change){
			werror("delta=%f\n",me);
			//Stdio.append_file("mrf.log",sprintf("%d,%d,%d,%d,%d\n",@if_change_args,oldid));
			//newchanged[oldid]=1;
			//newchanged[if_change_args[-1]]=1;
			foreach(expand_coord(w,h,x,y),[int x1,int y1]){
				todo[myencode(x1,y1)]=1;
			}
			if_change(@if_change_args,1,lambda(){});
			return 1;
		}
	};/*}}}*/
	multiset my_id2nearby2(int id)/*{{{*/
	{
		multiset ids=my_id2nearby(id);
		multiset ids2=(<>);
		foreach(ids;int id;int ig){
			ids2[id]=1;
			ids2=ids2|my_id2nearby(id);
		}
		return ids2;
	}/*}}}*/
	void reduce()/*{{{*/
	{
		for(int t=0;t<0;t++){
			write("t=%d\n",t);
			int found;
			multiset todo=(<>);
			for(int k=1;k>=0;k--){
				todo=(<>);
				for(int x=0;x<w;x++){
					for(int y=0;y<h;y++){
						werror("%d %d %d %d (%d)\n",t,k,x,y,found);
						found+=reduce_one(k,x,y,my_id2nearby2(ms[k][x][y]),todo);
					}
				}
				while(sizeof(todo)){
					multiset m=todo;
					todo=(<>);
					foreach(m;int kk;int ig){
						[int x,int y]=mydecode(kk);
						werror("%d %d %d %d (%d)\n",t,k,x,y,found);
						found+=reduce_one(k,x,y,my_id2nearby2(ms[k][x][y]),todo);
					}
				}
			}
			if(!found)
				break;
		}
	}/*}}}*/
#if 0
	void reduce_check2()/*{{{*/
	{
		for(int t=0;t<Math.inf;t++){
			write("t=%d\n",t);
			int found;
			for(int k=1;k>=0;k--){
				for(int x=0;x<w;x++){
					for(int y=0;y<h;y++){
						werror("%d %d %d %d\n",t,k,x,y);
						int oldid=ms[k][x][y];
						multiset ids=my_id2nearby(oldid);//get_nearby_ids(oldid,0)|get_nearby_ids(oldid,1);
						//multiset ids=get_most_nearby_ids(k,x,y)|get_nearby_ids(oldid,1-k)|
						mapping b=backup_status();
						foreach(ids;int id;int one){
							if_change_label(PixelAtom(k,x,y),id,0,lambda(){});
						}
						check_status(b);
						int id=random(ids);
						if_change_label(PixelAtom(k,x,y),id,1,lambda(){});
					}
				}
			}
		}
	}/*}}}*/
	void reduce_check1()/*{{{*/
	{
		for(int i=0;i<1000;i++){
			werror("%d\n",i);
			int k=random(2);
			int x=random(w);
			int y=random(h);
			int oldid=ms[k][x][y];
			multiset ids=my_id2nearby(oldid);//get_nearby_ids(oldid,0)|get_nearby_ids(oldid,1);
			foreach(ids;int id;int one){
				if_change_label(k,x,y,id,0,lambda(){});
			}
			int id=random(ids);
			if_change_label(k,x,y,id,1,lambda(){});
		}
	}/*}}}*/
#endif
		private array modeldelta_list(mapping model1,int total1,mapping model2,int total2)/*{{{*/
		{
			array res=({});
			array totals=({total1,total2});
			array models=({model1,model2});
			sort(totals,models);
			[mapping smallmodel,mapping bigmodel]=models;
			[int smalltotal,int bigtotal]=totals;
			foreach(indices(model1)|indices(model2),mixed key){
				float d=smalltotal*(bigmodel[key]-smallmodel[key]);
				res+=({({d})});
			}
			return res;
		}/*}}}*/
		private float modeldelta_entropy(mapping model1,int total1,mapping model2,int total2)/*{{{*/
		{
			array list=modeldelta_list(model1,total1,model2,total2);
			return `+(0.0,@map(list,lambda(array a){
						float d=a[0];
						ASSERT(modeldelta_sigma->sigma[0][0]>0,lambda(){
							werror("%O",modeldelta_sigma->sigma);
							});
						return Math.log2((d*d+1.0)/(modeldelta_sigma->sigma[0][0])/2)*Math.log2(Math.e);
					}));
		}/*}}}*/
	private multiset get_nearby_ids(int id,int k)/*{{{*/
	{
		return image_query_nearby(idimages[k],idimages[k],id);
	}/*}}}*/
	multiset my_id2nearby(int id)/*{{{*/
	{
		//return get_nearby_ids(id,0)|get_nearby_ids(id,1);
		return (multiset)(indices(id2nearby[id]||([])));
	}/*}}}*/
	private array get_model(int id,int k)/*{{{*/
	{
		mapping res=([]);
		int total=0;
		foreach(get_nearby_ids(id,k);int id2;int one){
			int kk=myencode(@sort(({id,id2})));
			res[kk]=pair2counts[k][kk];
			total+=res[kk];
		}
		if(total){
			foreach(res;string kk;int val){
				res[kk]=1.0*val/total;
			}
		}
		return ({res,total});
	}/*}}}*/
	float mrf_group_entropy(int id,multiset nearby)/*{{{*/
	{
		float res=0.0;
		foreach(nearby;int id2;int one){
			int t=myencode(@sort(({id,id2})));
			int kk=pair2counts[0][t]+pair2counts[1][t];
			if(kk){
				/*res+=
					(Math.log2(1.0*(id2count[id]*4)/kk)+
					Math.log2(1.0*(id2count[id2]*4)/kk))*kk;*/
				res+=
					(Math.log2(1.0*(id2sigma[id]->n*4)/kk)+
					Math.log2(1.0*(id2sigma[id2]->n*4)/kk))*kk;
			}
		}
		return res;
	}/*}}}*/
	array try_change_label(object atom,int oldid,int newid)/*{{{*/
	{
		/* 计熵点：
			 1、改变前后受影响的色块的像素熵的改变量
			 2、对于受影响的色块，马场概率模型发生了变化，所有从这些色块出发的出度边将受到影响，计算其熵变化，需要通过id引用不同类型边的数量
			 3、边界两边的色块位移相等
			 4、前后相续的色块马场概率模型变化量为0
			 5、前后相续的色块的(dr,dg,db,dx,dy)为(0,0,0,0,0)？
			 */
		/* 全局残差：
			 1、像素残差熵不对每个色块计算，每个色块只维持均值，残差视为全局一致的正态分布随机变量。
			 2、如果对每个色块计残差，如果一个色块错误地包含了大块的其它色块像素，这些像素不会被分离出去。
		 */
		object oldsigma1=id2sigma[oldid];
		object oldsigma2=id2sigma[newid];
		object newsigma1,newsigma2;

		object oldedgesigma=edge_sigma;
		object newedgesigma;

		object old_color_error_sigma=color_error_sigma;
		object new_color_error_sigma;
		object old_color_mean_sigma=color_mean_sigma;
		object new_color_mean_sigma;
		object old_color_delta_sigma=color_delta_sigma;
		object new_color_delta_sigma;

		multiset oldnearby1=my_id2nearby(oldid);//get_nearby_ids(oldid,0)|get_nearby_ids(oldid,1);
		multiset oldnearby2=my_id2nearby(newid);//get_nearby_ids(newid,0)|get_nearby_ids(newid,1);
		multiset newnearby1,newnearby2;
		float old_mrf_entropy1=mrf_group_entropy(oldid,oldnearby1);
		float old_mrf_entropy2=mrf_group_entropy(newid,oldnearby2);
		float new_mrf_entropy1,new_mrf_entropy2;
		/*float old_edge_entropy1=edge_group_entropy(oldid,oldnearby1);
		float old_edge_entropy2=edge_group_entropy(newid,oldnearby2);
		float new_edge_entropy1,new_edge_entropy2;
		*/

		/*int dxdy_available=(id2sigmas[oldid]&&id2sigmas[newid]);
		float oldavgx1,oldavgy1,oldavgx2,oldavgy2;
		float newavgx1,newavgy1,newavgx2,newavgy2;
		float edge_e=0.0;
		if(dxdy_available){
			[oldavgx1,oldavgy1]=id2sigmas[oldid]->avgval[3..4];
			[oldavgx2,oldavgy2]=id2sigmas[newid]->avgval[3..4];
		}*/

#if 0
		[mapping model1before,int total1before]=get_model(oldid,0);
		[mapping model2before,int total2before]=get_model(newid,0);
		[mapping model1after,int total1after]=get_model(oldid,1);
		[mapping model2after,int total2after]=get_model(newid,1);
		float old_modeldelta_entropy=0.0;
		float new_modeldelta_entropy=0.0;
		old_modeldelta_entropy+=modeldelta_entropy(model1before,total1before,model1after,total1after);
		old_modeldelta_entropy+=modeldelta_entropy(model2before,total2before,model2after,total2after);
#endif

		if_change_label(atom,newid,0,lambda(){
				newedgesigma=edge_sigma;
				new_color_error_sigma=color_error_sigma;
				new_color_mean_sigma=color_mean_sigma;
				new_color_delta_sigma=color_delta_sigma;
				newsigma1=id2sigma[oldid];
				newsigma2=id2sigma[newid];
				newnearby1=my_id2nearby(oldid);//get_nearby_ids(oldid,0)|get_nearby_ids(oldid,1);
				newnearby2=my_id2nearby(newid);//get_nearby_ids(newid,0)|get_nearby_ids(newid,1);
				new_mrf_entropy1=mrf_group_entropy(oldid,newnearby1);
				new_mrf_entropy2=mrf_group_entropy(newid,newnearby2);
				/*new_edge_entropy1=edge_group_entropy(oldid,oldnearby1);
				new_edge_entropy2=edge_group_entropy(newid,oldnearby2);*/
				/*dxdy_available=(dxdy_available&&id2sigmas[oldid]&&id2sigmas[newid]);
				if(dxdy_available){
					[newavgx1,newavgy1]=id2sigmas[oldid]->avgval[3..4];
					[newavgx2,newavgy2]=id2sigmas[newid]->avgval[3..4];
					float dx1=newavgx1-oldavgx1;
					float dx2=newavgx2-oldavgx2;
					float dy1=newavgy1-oldavgy1;
					float dy2=newavgy2-oldavgy2;
					edge_e=edge_group_entropy(([oldid:({dx1,dy1}),newid:({dx2,dy2})]));
				}*/
#if 0
				[mapping model1before,int total1before]=get_model(oldid,0);
				[mapping model2before,int total2before]=get_model(newid,0);
				[mapping model1after,int total1after]=get_model(oldid,1);
				[mapping model2after,int total2after]=get_model(newid,1);
				new_modeldelta_entropy+=modeldelta_entropy(model1before,total1before,model1after,total1after);
				new_modeldelta_entropy+=modeldelta_entropy(model2before,total2before,model2after,total2after);
#endif
				});
		float delta=0.0;
		//delta+=(oldsigma1&&oldsigma1->entropy())-(newsigma1&&newsigma1->entropy());
		//delta+=(oldsigma2&&oldsigma2->entropy())-(newsigma2&&newsigma2->entropy());
		delta+=old_color_mean_sigma->entropy()-new_color_mean_sigma->entropy();
		delta+=(old_color_delta_sigma&&old_color_delta_sigma->entropy()/2)-(new_color_delta_sigma&&new_color_delta_sigma->entropy()/2);
		delta+=old_color_error_sigma->entropy()-new_color_error_sigma->entropy();
		delta+=old_mrf_entropy1+old_mrf_entropy2-new_mrf_entropy1-new_mrf_entropy2; //边
		//if(oldedgesigma) delta+=oldedgesigma->entropy();
		//if(newedgesigma) delta-=newedgesigma->entropy(); //色块边界
#if 0
		delta+=old_modeldelta_entropy-new_modeldelta_entropy; //色块
#endif

		//werror("delta=%f\n",delta);

		return ({delta,if_change_label,({atom,newid})});
	}/*}}}*/
}

int match_image_main(int argc,array argv)
{
	//mapping args=Arg.parse(argv);
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];

	DECLARE_ARGUMENT_FLAG("mrf",mrf_flag,"Use markov random field.");
	if(Usage.usage(args,"FILE1 FILE2 LEVEL",3))
		return 0;

	HANDLE_ARGUMENTS();

	string target1=rest[0];
	string target2=rest[1];
	int levellimit=(int)(rest[2]);

	object image1=read_image(target1,levellimit);
	object image2=read_image(target2,levellimit);

	object data1=PixelData(.ImageInteger.ImageInteger(image1->xsize(),image1->ysize())+image1);
	object data2=PixelData(.ImageInteger.ImageInteger(image2->xsize(),image2->ysize())+image2);

	int w=image1->xsize();
	int h=image1->ysize();
	object dr=PixelRelationMap(w,h)->load(decode_value(Stdio.read_file("output/"+target1+"-ndrgb.result")));
	object dr2=PixelRelationMap(w,h)->load(decode_value(Stdio.read_file("output/"+target2+"-ndrgb.result")));

	array gstd2=global_std2(dr2->a-({0}));

	//object image1=Image.BMP.decode(Stdio.read_file(target1))->scale(w,h);
	//object image2=Image.BMP.decode(Stdio.read_file(target2))->scale(w,h);
	Stdio.write_file("out_image1.png",Image.PNG.encode(image1));
	Stdio.write_file("out_image2.png",Image.PNG.encode(image2));
	//Stdio.write_file("out.png",Image.PNG.encode(dr->image));
	//exit(0);
	/*object out0=Image.Image(w,h);
	for(int id=0;id<sizeof(dr->a);id++){
		if(dr->a[id]){
			foreach(dr->a[id]->query_selected(),[int k,int i,int j]){
				if(i>48)
					werror("%d,%d,%d;",k,i,j);
			}
			object mask0=dr->query_mask((<id>))[0];
			out0->paste_mask(image1&mask0,mask0,0,0);
		}
	}
	Stdio.write_file("out.png",Image.PNG.encode(out0));
	exit(0);
	*/

	//整图定位
	int gdx,gdy;/*{{{*/
	float bestdiff=Math.inf;
	array bestpos;
	for(int i=0;i<w/2;i++){
		for(int j=0;j<h/2;j++){
			object p,q; float val;
			p=image1->copy(i,j,w-1,h-1);
			q=image2->copy(0,0,w-i-1,h-j-1);
			val=`+(0.0,@(p-q)->sumf())/(w-i)/(h-j);
			//val=p2sumf(p-q)/(w-i)/(h-j);
			if(val<bestdiff){
				bestdiff=val;
				bestpos=({-i,-j});
			}
			p=image2->copy(i,j,w-1,h-1);
			q=image1->copy(0,0,w-i-1,h-j-1);
			val=`+(0.0,@(p-q)->sumf())/(w-i)/(h-j);
			//val=p2sumf(p-q)/(w-i)/(h-j);
			if(val<bestdiff){
				bestdiff=val;
				bestpos=({i,j});
			}
		}
	}
	[gdx,gdy]=bestpos;/*}}}*/
	werror("gdx=%d,gdy=%d\n",gdx,gdy);

	object out=Image.Image(w,h);
	object outdeep=Image.Image(w,h);

	//定位结果存放于此
	mapping id2dx=([]);
	mapping id2dy=([]);
	mapping id2info=([]);

	void init(int gdx,int gdy)/*{{{*/
	{
		foreach(dr->a;int id;object cell){
			if(cell){
				object mask0=dr->query_mask((<id>))[0];
				object mask=mask0->outline(255,255,255,0,0,0);
				object p0=image1&mask;
				[int x0,int y0,int ig1,int ig2]=.ImageInteger.mask_find_autocrop(mask);
				[object mask2,object p,object mask3]=.ImageInteger.mask_autocrop(mask,p0,mask0);

				id2dx[id]=gdx;
				id2dy[id]=gdy;
				id2info[id]=({p,mask3,x0,y0,(<>)});
			}
		}
	};/*}}}*/

	//如果需要以此法计算标准差/*{{{*/
	//float stdx=pow(`+(0.0,@map(map(values(id2dx),`-,gdx),pow,2))/sizeof(id2dx),0.5);
	//float stdy=pow(`+(0.0,@map(map(values(id2dy),`-,gdy),pow,2))/sizeof(id2dx),0.5);/*}}}*/

	mapping id2sdiff=([]);
	float self_diff(int id,object p,object mask)/*{{{*/
	{
		m_delete(id2sdiff,-1);
		if(zero_type(id2sdiff[id])){
			array sum=p->sumf();
			int n=.ImageInteger.mask_count(mask);
			if(n){
				array avg=map(sum,`/,n);
				object avgimage=Image.Image(mask->xsize(),mask->ysize(),0,0,0);
				avgimage->paste_alpha_color(mask,(int)avg[0],(int)avg[1],(int)avg[2]);
				float res=`+(0.0,@(avgimage-p)->sumf());
				werror("sdiff=%f\n",res);
				id2sdiff[id]=res;
				//return res;
			}else{
				id2sdiff[id]=0.0;
			}
		}
		return id2sdiff[id];
	};/*}}}*/
	array create_cover_mask(int id,object mask,int i,int j,array frontlist)/*{{{*/
	{
		object tmp=Image.Image(mask->xsize(),mask->ysize(),0,0,0);
		foreach(frontlist,int id2){
			[object p2,object mask2,int x2,int y2,multiset flags2]=id2info[id2];
			tmp->paste_mask(mask2,mask2,x2-i,y2-j);
		}
		/*if(i<0)
			tmp->box(0,0,-i-1,mask->ysize()-1,255,255,255);
		if(j<0)
			tmp->box(0,0,mask->xsize()-1,-j-1,255,255,255);
		if(i+mask->xsize()>w) //超了多少切多少，从右边切
			tmp->box(mask->xsize()-(i+mask->xsize()-w),0,mask->xsize()-1,mask->ysize()-1,255,255,255);
		if(j+mask->ysize()>h) //超了多少切多少，从下边切
			tmp->box(0,mask->ysize()-(j+mask->ysize()-h),mask->xsize()-1,mask->ysize()-1,255,255,255);
			*/
			
		return ({i,j,tmp->invert()&mask,tmp&mask});

	};/*}}}*/

	//以(gdx,gdy)为预期位移，定位id的最佳位置
	void foo(int id,float gdx,float gdy,int dxdir,mapping id2frontlist,function(int,int:float) get_nearby_diff,function(int,int:float) get_unexplained_diff)/*{{{*/
	{
		object mask0=dr->query_mask((<id>))[0];
		object mask=mask0->outline(255,255,255,0,0,0);
		object p0=image1&mask;
		[int x0,int y0,int ig1,int ig2]=.ImageInteger.mask_find_autocrop(mask);
		[object mask2,object p,object mask3]=.ImageInteger.mask_autocrop(mask,p0,mask0);
		float sdiff=self_diff(id,p,mask2);
		array frontlist=({});
		if(dxdir){
			array keys=indices(id2dx);
			array vals=values(id2dx);
			sort(vals,keys);
			if(dxdir==-1)// 往左，所有dx比当前小的形成前景
				;
			else{// 往右，所有dx比当前大的形成前景
				vals=reverse(vals);
				keys=reverse(keys);
			}
			int n;
			for(n=0;vals[n]!=id2dx[id];n++)
				;
			keys=keys[..n-1];//最前面的前景在最前面
			frontlist=reverse(keys);
		}else if(id2frontlist){
			frontlist=reverse(id2frontlist[id]||({}));
		}
		//这是静态的，不对，应该对于每一个具体的位置计算遮挡
		/*
		[object p1,object mask1,int x1,int y1,multiset flags1]=id2info[id];
		object big1=Image.Image(w,h,0,0,0)->paste(mask1,x1+id2dx[id],y1+id2dy[id]);
		foreach(frontlist,int id2){
			[object p2,object mask2,int x2,int y2,multiset flags2]=id2info[id2];
			object big2=Image.Image(w,h,0,0,0)->paste(mask2,x2+id2dx[id2],y2+id2dy[id2]);
			object mask_both=big1&big2;
			if(mask_both!=0){ //将p中mask_both所覆盖的部分修改为id2中的部分
				//object mask_both1=mask_both->copy(x1+id2dx[id],y2+id2dy[id],x1+id2dx[id]+p1->xsize()-1,y1+id2dy[id]+p1->ysize()-1);
				object mask_both2=mask_both->copy(
						x2+id2dx[id2],
						y2+id2dy[id2],
						x2+id2dx[id2]+p2->xsize()-1,
						y2+id2dy[id2]+p2->ysize()-1);
				p->paste_mask(p2,mask_both2,
						x2+id2dx[id2]-x1-id2dx[id],
						y2+id2dy[id2]-y1-id2dy[id]);
			}
		}
		*/

		//werror("%d %d",mask2->xsize(),mask2->ysize());

		float bestdiff=Math.inf;
		multiset bestflags=(<>);
		array bestpos;

		if(x0+gdx+mask2->xsize()/2>0&&y0+gdy+mask2->ysize()/2>0
				&&x0+gdx+mask2->xsize()/2<w-1&&y0+gdy+mask2->ysize()/2<h-1){
			for(int i=0-mask2->xsize();i<w;i++){
				for(int j=0-mask2->ysize();j<h;j++){
					int is_sdiff=0;
					//object q=image2->copy(i,j,i+mask2->xsize()-1,j+mask2->ysize()-1)&mask2;
					[int xx,int yy,object mm,object um]=create_cover_mask(id,mask2,i,j,frontlist);
					object q=image2->copy(xx,yy,xx+mm->xsize()-1,yy+mm->ysize()-1)&mm;
					object p=image1->copy(xx-(i-x0),yy-(j-y0),xx-(i-x0)+mm->xsize()-1,yy-(j-y0)+mm->ysize()-1)&mm;
					float val=`+(0.0,@(p-q)->sumf());
					if(um!=0){
						//object p=image1->copy(xx-(i-x0),yy-(j-y0),xx-(i-x0)+mm->xsize()-1,yy-(j-y0)+mm->ysize()-1)&um;
						//val+=self_diff(-1,p,um);
					}
					if(val>sdiff){
						val=sdiff;
						is_sdiff=1;
					}
					val+=get_nearby_diff(i-x0,j-y0);
					val+=get_unexplained_diff(i-x0,j-y0);
					if(val<bestdiff){
						bestdiff=val;
						bestpos=({i,j});
						bestflags=is_sdiff?(<"SDIFF">):(<>);
					}
				}
			}
		}
		if(bestpos){
			id2dx[id]=bestpos[0]-x0;
			id2dy[id]=bestpos[1]-y0;
		}else{
			id2dx[id]=(int)gdx;
			id2dy[id]=(int)gdy;
		}
		id2info[id]=({p,mask3,x0,y0,bestflags});
		//out->paste_mask(p,mask3,@bestpos);
		//outdeep->paste_mask(Image.Image(mask3->xsize(),mask3->ysize(),({(int)(deep/w*255)})*3),mask3,x0,y0);
	};/*}}}*/

	//以周围的平均位移为预期位移
#if 0
	//并入update2
	void update(int n,int dxdir)/*{{{*/
	{
		array idlist,difflist;
		for(int k=0;k<n;k++){
			werror("phase %d\n",k);
			idlist=({});
			difflist=({});
			for(int id=0;id<sizeof(dr->a);id++){
				if(dr->a[id]){
					idlist+=({id});
					//werror("%O %O %O %O\n",id2dx[id],gdx,id2dy[id],gdy);
					difflist+=({pow(0.0+id2dx[id]-gdx,2)+pow(0.0+id2dy[id]-gdy,2)});
				}
			}
			sort(difflist,idlist);
			foreach(reverse(idlist),int id){
				array ids=(array)(dr->query_nearby(id))&indices(id2info);
				if(sizeof(ids)){
					float avgdx=`+(0.0,@map(ids,id2dx))/sizeof(ids);
					float avgdy=`+(0.0,@map(ids,id2dy))/sizeof(ids);
					float gdx1=avgdx;
					float gdy1=avgdy;

					foo(id,gdx1,gdy1,dxdir);
				}
			}
		}
	};/*}}}*/
#endif

	mapping id2color=([]);
	for(int i=0;i<sizeof(dr->a);i++){
		if(dr->a[i]){
				id2color[i]=data1->average_value(dr,(<i>))->avgval;
		}
	}
	//使用单调背景分离技术
	void update2(int n,int dxdir,mapping id2frontlist)/*{{{*/
	{
		array idlist,difflist;
		for(int k=0;k<n;k++){
			werror("phase %d\n",k);
			idlist=({});
			difflist=({});
			for(int id=0;id<sizeof(dr->a);id++){
				if(dr->a[id]){
					idlist+=({id});
					//werror("%O %O %O %O\n",id2dx[id],gdx,id2dy[id],gdy);
					difflist+=({pow(0.0+id2dx[id]-gdx,2)+pow(0.0+id2dy[id]-gdy,2)});
				}
			}
			sort(difflist,idlist);
			foreach(reverse(idlist),int id){
				mapping m=dr->query_raw_nearby_detail(id);
				array color1=id2color[id];
				[object p1,object mask1,int x1,int y1,multiset flags1]=id2info[id];
				int count1=.ImageInteger.mask_count(mask1);
				float get_nearby_diff(int dx,int dy)/*{{{*/
				{
					float sum=0.0;
					float count=0.0;
					foreach(m;int id2;array list)
					{
						array color2=id2color[id2];
						//位移的平方项：理论上的支持在于，色块的绝对值项与位移的平方项线性组合所驱动的最优化过程是对于分辨率不变的；对w,h归一化处理以后，对于色深也是不变的
						sum+=pow(diffa(({id2dx[id2]*256/w,id2dy[id2]*256/h}),({dx*256/w,dy*256/h})),2)*sizeof(list);
						count+=sizeof(list);
						//颜色吸收距离：有一定改善，但不足以称之为成功
						//sum+=pow(diffa(({id2dx[id2]*256/w,id2dy[id2]*256/h}),({dx*256/w,dy*256/h})),2)*1.0/diffa(color2,color1)*sizeof(list);
						//count+=1.0/diffa(color2,color1)*sizeof(list);
						//纯粹工程性的尝试
						//sum+=pow(diffa(({id2dx[id2],id2dy[id2]}),({dx,dy})),2)/(diffa(color2,color1)+1);
						//count+=sizeof(list);
						/*foreach(list,[int x,int y]){
							array color2=image1->getpixel(x,y);
							float diffval=pow(diffa(color2+({id2dx[id2]*256/w,id2dy[id2]*256/h}),color1+({dx*256/w,dy*256/h})),2);
							sum+=diffval;
						}*/
					}
					//位移平方项的平均值，与像素数无关
					return sum/count;
					//return sum/count*count1;
				};/*}}}*/

				/*object bigmask=Image.Image(w,h);
				for(int i=0;i<sizeof(dr->a);i++){
					if(dr->a[i]&&i!=id){
						[object p0,object mask0,int x0,int y0]=id2info[id];
						bigmask->paste(mask0,x0+id2dx[i],x0+id2dy[i]);
					}
				}
				bigmask=bigmask->invert();
				mapping id2center=([]);
				for(int i=0;i<sizeof(dr->a);i++){
					if(dr->a[i]&&i!=id){
						[object p0,object mask0,int x0,int y0]=id2info[id];
						id2center[i]=
					}
				}
				for(int i=0;i<w;i++){
					for(int j=0;j<h;j++){
						if(bigmask->getpixel(i,j)[0]){
							for(int i=0;i<sizeof(dr->a);i++){
								if(dr->a[i]&&i!=id){
									array color=id2color[i];
									
								}
							}
						}
					}
				}*/
				float get_unexplained_diff(int dx,int dy)
				{
					return 0.0;
				};

				array ids=(array)(dr->query_nearby(id))&indices(id2info);
				if(sizeof(ids)){
					float avgdx=`+(0.0,@map(ids,id2dx))/sizeof(ids);
					float avgdy=`+(0.0,@map(ids,id2dy))/sizeof(ids);
					float gdx1=avgdx;
					float gdy1=avgdy;

					foo(id,gdx1,gdy1,dxdir,id2frontlist,get_nearby_diff,get_unexplained_diff);
				}
			}
		}

	};/*}}}*/
#if 0
	//以周围颜色最接近的色块的位移为预期位移
	void update3(int n,int dxdir)/*{{{*/
	{
		array idlist,difflist;
		for(int k=0;k<n;k++){
			werror("phase %d\n",k);
			idlist=({});
			difflist=({});
			for(int id=0;id<sizeof(dr->a);id++){
				if(dr->a[id]){
					idlist+=({id});
					//werror("%O %O %O %O\n",id2dx[id],gdx,id2dy[id],gdy);
					difflist+=({pow(0.0+id2dx[id]-gdx,2)+pow(0.0+id2dy[id]-gdy,2)});
				}
			}
			sort(difflist,idlist);
			foreach(reverse(idlist),int id){
				array color1=id2color[id];
				array ids=(array)(dr->query_nearby(id))&indices(id2info);
				if(sizeof(ids)){
					float mindiff=Math.inf;
					int minid;
					foreach(ids,int id2){
						array color2=id2color[id2];
						float diffval=diffa(color1,color2);
						if(diffval<mindiff){
							mindiff=diffval;
							minid=id2;
						}
					}

					foo(id,id2dx[minid],id2dy[minid],dxdir);
				}
			}
		}
	};/*}}}*/
#endif
	init(gdx,gdy);
	update2(1,0,([]));

	//计算遮挡关系

	int dxdir;
	mapping id2frontlist=([]);

	void update_cover_relation()/*{{{*/
	{
		id2frontlist=([]);
		float checkerror1=0.0;
		float checkerror2=0.0;
		int checkcount=0;
		int checkcount1=0;
		int checkcount2=0;
		for(int id=0;id<sizeof(dr->a);id++){
			if(dr->a[id]){
				if(id2info[id]){
					//werror("got\n");
					[object p1,object mask1,int x1,int y1,multiset flags1]=id2info[id];
					object big1=Image.Image(w,h,0,0,0)->paste(mask1,x1+id2dx[id],y1+id2dy[id]);
					object image_big1=Image.Image(w,h,0,0,0)->paste(p1,x1+id2dx[id],y1+id2dy[id]);
					multiset m=dr->query_nearby(id);
					foreach(m;int id2;int ig){
						if(id2info[id2]){
							//werror("got2\n");
							[object p2,object mask2,int x2,int y2,multiset flags2]=id2info[id2];
							object big2=Image.Image(w,h,0,0,0)->paste(mask2,x2+id2dx[id2],y2+id2dy[id2]);
							object mask_both=big1&big2;
							if(mask_both!=0){
								object image_big2=Image.Image(w,h,0,0,0)->paste(p2,x2+id2dx[id2],y2+id2dy[id2]);
								object image_both=image2&mask_both;
								object image_both1=image_big1&mask_both;
								object image_both2=image_big2&mask_both;

								float diffval1=`+(0.0,@(image_both-image_both1)->sumf());
								float diffval2=`+(0.0,@(image_both-image_both2)->sumf());
								//float diffval1=p2sumf(image_both-image_both1);
								//float diffval2=p2sumf(image_both-image_both2);

								//werror("diffval1=%f diffval2=%f\n",diffval1,diffval2);

								if(id2dx[id]!=id2dx[id2]&&diffval1!=diffval2){
									//write("COVER TEST %d vs %d: %d %d\n",id,id2,id2dx[id]>id2dx[id2],diffval1>diffval2);
									if(diffval1>diffval2){
										id2frontlist[id]=id2frontlist[id]||({});
										id2frontlist[id]+=({id2});
									}
									if(id2dx[id]<id2dx[id2]){
										if(diffval1>diffval2){
											checkerror1+=pow(diffval1,2);
											checkcount1++;
										}else{
											checkerror2+=pow(diffval1,2);
											checkcount2++;
										}
									}else{
										if(diffval2>diffval1){
											checkerror1+=pow(diffval2,2);
											checkcount1++;
										}else{
											checkerror2+=pow(diffval2,2);
											checkcount2++;
										}
									}

									//checkerror1+=pow(id2dx[id]<id2dx[id2]?max(0,0,diffval1-diffval2):max(0,0,diffval2-diffval1),2);//dx1<dx2时，如果diff1<diff2不计算熵
									//checkerror2+=pow(id2dx[id]>id2dx[id2]?max(0,0,diffval1-diffval2):max(0,0,diffval2-diffval1),2);//dx1>dx2时，如果diff1<diff2不计算熵

									//checkerror1+=pow(0.0+(diffval1>diffval2)-(id2dx[id]>id2dx[id2]),2);//y=x
									//checkerror2+=pow(0.0+(diffval1>diffval2)-(1-(id2dx[id]>id2dx[id2])),2);//y=1-x
									checkcount++;
								}
							}
						}
					}
				}
			}
		}
		dxdir=0;
		if(checkcount1&&checkcount2){
			float std1=pow(checkerror1/checkcount1,0.5);
			float std2=pow(checkerror2/checkcount2,0.5);
			werror("std(x=y):%f std(x=1-y):%f\n",std1,std2);
			//sample -> sample2 是往左移动，dx越小的距离越近，dx小的要遮盖dx大的，遮盖部分的颜色应该更接近dx小的一方的颜色，即条件为：dx1<dx2 结论为diffval1<diffval2 std(x=y)应该有较小的值
			if(std1<std2)
				dxdir=-1; //向左移动
			else
				dxdir=1; //向右移动
		}
		//dxdir=1;
		werror("dxdir=%d\n",dxdir);
	};/*}}}*/

	/*update_cover_relation();
	update2(1,0,id2frontlist);

	update_cover_relation();
	update2(1,0,id2frontlist);
	*/

	update_cover_relation();

	if(mrf_flag){
		object mrf=ERMRF2L(dr,data1,data2,id2dx,id2dy,id2frontlist);
		mrf->reduce();
		
#if 0
#if 0
		float mrf_entropy1(int i,int j)/*{{{*/
		{
			int n=sizeof(id2count);
			array(float) e=({});
			e+=({Math.log2(1.0*w*h/id2count[m[i][j]])});
			if(i>0){
				mapping mm=id2dir2id2count[m[i-1][j]]["1:0"]||([]);
				if(mm[m[i][j]]){
					e+=({Math.log2(1.0*id2count[m[i-1][j]]/mm[m[i][j]])});
				}
			}
			if(i<w-1){
				mapping mm=id2dir2id2count[m[i+1][j]]["-1:0"]||([]);
				if(mm[m[i][j]]){
					e+=({Math.log2(1.0*id2count[m[i+1][j]]/mm[m[i][j]])});
				}
			}
			if(j>0){
				mapping mm=id2dir2id2count[m[i][j-1]]["0:1"]||([]);
				if(mm[m[i][j]]){
					e+=({Math.log2(1.0*id2count[m[i][j-1]]/mm[m[i][j]])});
				}
			}
			if(j<h-1){
				mapping mm=id2dir2id2count[m[i][j+1]]["0:-1"]||([]);
				if(mm[m[i][j]]){
					e+=({Math.log2(1.0*id2count[m[i][j+1]]/mm[m[i][j]])});
				}
			}
			return entropy_average(e,5);
		};/*}}}*/
		float mrf_entropy2(int i,int j)/*{{{*/
		{
			int n=sizeof(id2count);
			array(float) e=({});
			//e+=({Math.log2(1.0*w*h/id2count[m[i][j]])});
			int gap;
			if(i>0){
				mapping mm=id2dir2id2count[m[i-1][j]]["1:0"]||([]);
				if(mm[m[i][j]]){
					e+=({Math.log2(1.0*(w-1)*h/mm[m[i][j]])});
				}else{
					gap++;
				}
			}
			if(i<w-1){
				mapping mm=id2dir2id2count[m[i+1][j]]["-1:0"]||([]);
				if(mm[m[i][j]]){
					e+=({Math.log2(1.0*(w-1)*h/mm[m[i][j]])});
				}else{
					gap++;
				}
			}
			if(j>0){
				mapping mm=id2dir2id2count[m[i][j-1]]["0:1"]||([]);
				if(mm[m[i][j]]){
					e+=({Math.log2(1.0*(h-1)*w/mm[m[i][j]])});
				}else{
					gap++;
				}
			}
			if(j<h-1){
				mapping mm=id2dir2id2count[m[i][j+1]]["0:-1"]||([]);
				if(mm[m[i][j]]){
					e+=({Math.log2(1.0*(h-1)*w/mm[m[i][j]])});
				}else{
					gap++;
				}
			}
			return `+(0.0,@e)/*/sizeof(e)*/+
				gap*Math.log2(1.0*w*h);//断裂熵
		};/*}}}*/
#endif
		float mrf_entropy(int k,int i,int j/*,int oldid*/)/*{{{*/
		{
			int n=sizeof(id2count);
			array(float) e=({});
			//array color=dr->image->getpixel(i,j);
			//int id=dr->color2id(color);
			int id=ms[k][i][j];
			int gap;
			foreach(({({-1,0}),({1,0}),({0,-1}),({0,1})}),array dir){
				if(i+dir[0]>=0&&i+dir[0]<w&&j+dir[1]>=0&&j+dir[1]<h){
					//array color2=dr->image->getpixel(i+dir[0],j+dir[1]);
					//int id2=dr->color2id(color2);
					int id2=ms[k][i+dir[0]][j+dir[1]];
					int t=myencode(@sort(({id,id2})));
					int kk=pair2counts[0][t]+pair2counts[1][t];
					kk++;
					if(kk>0){
						//对于每个像素，如果我们已知它的标签为id，我们统计从任意一个标签为id的像素到任意一个相邻的像素的弧的概率分布，包括到id自身的情况，如果我们知道了每个情况的概率分布，我们可以计算从id出发的弧的熵为：对所有的id2求和[ln(count(id)*4/count(id,id2))]
						/*e+=({
								Math.log2(1.0*(id2count[id]*4)/k)+
								Math.log2(1.0*(id2count[id2]*4)/k)
								});*/

						//先区分边界和非边界，对于边界，按上法计熵，因为不再计算内部的弧了，所以熵应该是：对所有的id2求和[ln(edge_count(id)/count(id,id2))]
						//配套的，需要为每一个独立色块指定id，即如果像素的新id和周围的像素id都不同，计ln(idcount)，对应的，老id如果和周围像素id都不同，要减去ln(idcount)。还有将两个分离的块连成一体的情况，处理起来比较复杂
						if(id!=id2){
							e+=({
									Math.log2(1.0*(id2count[id]*4)/kk)+
									Math.log2(1.0*(id2count[id2]*4)/kk)
									//+Math.log2(1.0*total_count/self_count)
									});
						}else{
							e+=({
									//Math.log2(1.0*total_count/(total_count-self_count))
									});
						}
					}else{
						gap++;
					}
					/*[object p1,object mask1,int x1,int y1,multiset flags1]=id2info[id];
					[object p2,object mask2,int x2,int y2,multiset flags2]=id2info[id2];
					e+=({
							pow((1.0*id2xsum2[id]/id2n2[id]-x1)-(1.0*id2xsum2[id2]/id2n2[id2]-x2),2.0)/2+
							pow((1.0*id2ysum2[id]/id2n2[id]-y1)-(1.0*id2ysum2[id2]/id2n2[id2]-y2),2.0)/2});*/
				}
			}
			/*[object p1,object mask1,int x1,int y1,multiset flags1]=id2info[id];
			object mask2=iit->id_create_mask(idimage,id);
			[int x2,int y2,int ig1,int ig2]=.ImageInteger.mask_find_autocrop(mask2);
			[mask2]=.ImageInteger.mask_autocrop(mask2);*/
			return `+(0.0,@e)
				//+Math.log2(1.0*total_count/self_count)*self_count+Math.log2(1.0*total_count/(total_count-self_count))*(total_count-self_count);
				//+gap*Math.log2(1.0*total_count)//断裂熵
				//+(gap?Math.log2(1.0*total_count/gap)*gap+Math.log2(1.0*total_count/(total_count-gap))*(total_count-gap):0)//断裂熵 这需要在全局统计gap总量
				//+relative_sharp_entropy(mask2,mask1)
				//-(oldid_solo?Math.log2(n):0)
				//+(newid_solo?Math.log2(n):0)
				;
		};/*}}}*/
		array edge_std2s()/*{{{*/
		{
			mapping id2xsum1=id2xsums[0];
			mapping id2ysum1=id2xsums[0];
			mapping id2n1=id2ns[0];
			mapping id2xsum2=id2xsums[1];
			mapping id2ysum2=id2xsums[1];
			mapping id2n2=id2ns[1];
			array list1=({});
			array list2=({});
			foreach(edges;string k;int ig){
				//sscanf(k,"%d,%d",int id1,int id2);
				[int id1,int id2]=mydecode(k);
				if(id2n2[id1]&&id2n2[id2]&&id2n1[id1]&&id2n1[id2]){
					float dcolor=pow(diffa(dr->a[id1]->info->avgval,dr->a[id2]->info->avgval),0.5);
					float dmove=pow(diffa(({
									(id2xsum2[id1]/id2n2[id1])[*]-(id2xsum1[id1]/id2n1[id1])[*],
									(id2ysum2[id1]/id2n2[id1])[*]-(id2ysum1[id1]/id2n1[id1])[*]
									}),({
										(id2xsum2[id2]/id2n2[id2])[*]-(id2xsum1[id2]/id2n1[id2])[*],
										(id2ysum2[id2]/id2n2[id2])[*]-(id2ysum1[id2]/id2n1[id2])[*]
										 })),0.5);
					if(sw[id2swidx[k]]){
						list1+=({({dcolor,dmove})});
					}else{
						list2+=({({dcolor,dmove})});
					}
				}
			}
			list2+=({({`+(0.0,@column(list1,0))/sizeof(list1),`+(0.0,@column(list1,1))/sizeof(list1)})});

			array sigma1=coordlist2sigma(list1);
			array sigma2=coordlist2sigma(list2);
			[array v1,array l1]=.eig(sigma1);
			[array v2,array l2]=.eig(sigma2);

			return ({({l1[0][0],l1[1][1]}),({l2[0][0],l2[1][1]})});
		};/*}}}*/
		for(int t=0;t<Math.inf;t++){
			array old_edge_std2s=edge_std2s();
			write("t=%d\n",t);
			int found;
			float me=0.0;
			int type=-1;
			int mid;
			array mxy;
			int msw;
			int|string mswid;

			float nearby_entropy(int k,int x,int y,int id,array old_edge_std2s,int|void using_edge_std2s)/*{{{*/
			{
				int oldid=ms[k][x][y];
				float e;
				array color=image2->getpixel(x,y);
				e+=`+(0.0,@map(color[*]-id2sigmas[oldid]->avgval[..2][*],pow,2.0)[*]/gstd2[*])/2*Math.log2(Math.e);
				e+=mrf_entropy(x,y);
				mapping changed=([]);
				if(x>0){ 
					int k1=myencode(@sort(({oldid,ms[k][x-1][y]})));
					int k2=myencode(@sort(({id,ms[k][x-1][y]})));
					changed[k1]--;
					changed[k2]++;
				}
				if(x<w-1){ 
					int k1=myencode(@sort(({oldid,ms[k][x+1][y]})));
					int k2=myencode(@sort(({id,ms[k][x+1][y]})));
					changed[k1]--;
					changed[k2]++;
				}
				if(y>0){ 
					int k1=myencode(@sort(({oldid,ms[k][x][y-1]})));
					int k2=myencode(@sort(({id,ms[k][x][y-1]})));
					changed[k1]--;
					changed[k2]++;
				}
				if(y<h-1){ 
					int k1=myencode(@sort(({oldid,ms[k][x][y+1]})));
					int k2=myencode(@sort(({id,ms[k][x][y+1]})));
					changed[k1]--;
					changed[k2]++;
				}
				[array istd2s,array ostd2s]=old_edge_std2s;
				foreach(changed;string k;int ig){
					if(sw[id2swidx[k]]){
						//sscanf(k,"%d,%d",int id1,int id2);
						[int id1,int id2]=mydecode(k);
						//这两个值不但和sw有关而且和m[x][y]:oldid->id的变化有关
						if(id1!=id2&&(pair2counts[0][k]+pair2counts[1][k])){
							if(sw[id2swidx[k]]){
								foreach(istd2s,float std2)
									e+=(pair2counts[0][k]+pair2counts[1][k])*0.5*Math.log2(2*Math.pi*Math.e*(1.0+std2));
							}else{
								foreach(ostd2s,float std2)
									e+=(pair2counts[0][k]+pair2counts[1][k])*0.5*Math.log2(2*Math.pi*Math.e*(1.0+std2));
							}

						}
					}
				}
				if_change_label(PixelAtom(k,x,y),id,0,lambda(){
					//这两个值只和m[x][y]:oldid->id的变化有关
					e-=`+(0.0,@map(color[*]-id2sigmas[id]->avgval[..2][*],pow,2.0)[*]/gstd2[*])/2*Math.log2(Math.e);
					e-=mrf_entropy(x,y);
					if(using_edge_std2s)
						[istd2s,ostd2s]=edge_std2s();
					foreach(changed;string kk;int ig){
						if(sw[id2swidx[kk]]){
							//sscanf(kk,"%d,%d",int id1,int id2);
							[int id1,int id2]=mydecode(k);
							//这两个值不但和sw有关而且和m[x][y]:oldid->id的变化有关
							if(id1!=id2&&(pair2counts[0][kk]+pair2counts[1][kk])){
								if(sw[id2swidx[kk]]){
									foreach(istd2s,float std2)
										e-=(pair2counts[0][kk]+pair2counts[1][kk])*0.5*Math.log2(2*Math.pi*Math.e*(1.0+std2));
								}else{
									foreach(ostd2s,float std2)
										e-=(pair2counts[0][kk]+pair2counts[1][kk])*0.5*Math.log2(2*Math.pi*Math.e*(1.0+std2));
								}

							}
						}
					}
					//这两个值不但和sw有关而且和m[x][y]:oldid->id的变化有关
					//e-=0.5*Math.log2(2*Math.pi*Math.e*(1.0+ostd2dx))*(sizeof(sw)-`+(0.0,@sw)+1.0);
					//e-=0.5*Math.log2(2*Math.pi*Math.e*(1.0+ostd2dy))*(sizeof(sw)-`+(0.0,@sw)+1.0);
				});
				return e;
			};/*}}}*/
#if 0
			float switch_entropy(string swid,int v,array old_edge_std2s)/*{{{*/
			{
				float e;
				int oldv=sw[id2swidx[swid]];
				if(v==oldv)
					return 0.0;
				//[float gstd2dx,float gstd2dy,float ostd2dx,float ostd2dy]=old_edge_std2s;
				[array istd2s,array ostd2s]=old_edge_std2s;
				//sscanf(swid,"%d,%d",int id1,int id2);
				[int id1,int id2]=mydecode(swid);
				if(id1==id2)
					return 0.0;

				//XXX: 这里不对，应该按边累加，不应该按点累加
				for(int i=0;i<w;i++){
					for(int j=0;j<h;j++){
						if(m[i][j]==id1||m[i][j]==id2){
							//这两个值不但和sw有关而且和m[x][y]:oldid->id的变化有关
							if(id2n2[id1]&&id2n2[id2]&&id1!=id2){
								//e+=1.0*pow(id2xsum2[id1]/id2n2[id1]-id2xsum2[id2]/id2n2[id2],2.0)/gstd2dx/2*Math.log2(Math.e);
								//e+=1.0*pow(id2ysum2[id1]/id2n2[id1]-id2ysum2[id2]/id2n2[id2],2.0)/gstd2dy/2*Math.log2(Math.e);
								if(sw[id2swidx[myencode(@sort(({id1,id2})))]]==1){
									foreach(istd2s,float std2)
										e+=0.5*Math.log2(2*Math.pi*Math.e*(1.0+std2));
									//e+=0.5*Math.log2(2*Math.pi*Math.e*(1.0+gstd2dx));
									//e+=0.5*Math.log2(2*Math.pi*Math.e*(1.0+gstd2dy));
								}else{
									foreach(ostd2s,float std2)
										e+=0.5*Math.log2(2*Math.pi*Math.e*(1.0+std2));
									//e+=0.5*Math.log2(2*Math.pi*Math.e*(1.0+ostd2dx));
									//e+=0.5*Math.log2(2*Math.pi*Math.e*(1.0+ostd2dy));
								}
							}
						}
					}
				}
				//这两个值不但和sw有关而且和m[x][y]:oldid->id的变化有关
				//e+=0.5*Math.log2(2*Math.pi*Math.e*(1.0+ostd2dx))*(sizeof(sw)-`+(0.0,@sw)+1.0);
				//e+=0.5*Math.log2(2*Math.pi*Math.e*(1.0+ostd2dy))*(sizeof(sw)-`+(0.0,@sw)+1.0);
				sw[id2swidx[swid]]=v;
				//[gstd2dx,gstd2dy,ostd2dx,ostd2dy]=edge_std2s();
				[istd2s,ostd2s]=edge_std2s();
				for(int i=0;i<w;i++){
					for(int j=0;j<h;j++){
						if(m[i][j]==id1||m[i][j]==id2){
							//这两个值不但和sw有关而且和m[x][y]:oldid->id的变化有关
							if(id2n2[id1]&&id2n2[id2]&&id1!=id2){
								//e+=1.0*pow(id2xsum2[id1]/id2n2[id1]-id2xsum2[id2]/id2n2[id2],2.0)/gstd2dx/2*Math.log2(Math.e);
								//e+=1.0*pow(id2ysum2[id1]/id2n2[id1]-id2ysum2[id2]/id2n2[id2],2.0)/gstd2dy/2*Math.log2(Math.e);
								if(sw[id2swidx[myencode(@sort(({id1,id2})))]]==1){
									foreach(istd2s,float std2)
										e-=0.5*Math.log2(2*Math.pi*Math.e*(1.0+std2));
									//e-=0.5*Math.log2(2*Math.pi*Math.e*(1.0+gstd2dx));
									//e-=0.5*Math.log2(2*Math.pi*Math.e*(1.0+gstd2dy));
								}else{
									foreach(ostd2s,float std2)
										e-=0.5*Math.log2(2*Math.pi*Math.e*(1.0+std2));
									//e-=0.5*Math.log2(2*Math.pi*Math.e*(1.0+ostd2dx));
									//e-=0.5*Math.log2(2*Math.pi*Math.e*(1.0+ostd2dy));
								}
							}
						}
					}
				}
				//这两个值不但和sw有关而且和m[x][y]:oldid->id的变化有关
				//e-=0.5*Math.log2(2*Math.pi*Math.e*(1.0+ostd2dx))*(sizeof(sw)-`+(0.0,@sw)+1.0);
				//e-=0.5*Math.log2(2*Math.pi*Math.e*(1.0+ostd2dy))*(sizeof(sw)-`+(0.0,@sw)+1.0);
				sw[id2swidx[swid]]=oldv;
				return e;
			};/*}}}*/
#endif
			for(int k=0;k<2;k++){
				for(int x=0;x<w;x++){
					for(int y=0;y<h;y++){
						//werror("%d,%d\n",x,y);
						array t=0;
						if(t==0){
							float me=0.0;
							int mid;
							array mxy;
							foreach(id2count;int id;int count){
								if(id==ms[k][x][y])
									continue;
								float e=nearby_entropy(k,x,y,id,old_edge_std2s);
								if(e>me){
									werror("[%d,%d] e=%f me=%f\n",x,y,e,me);
									me=e;
									mid=id;
									mxy=({k,x,y});
								}
							}
							t=({me,mid,mxy});
						}
						if(t[0]>me){
							[me,mid,mxy]=t;
							type=1;
						}
					}
				}
			}
			if(type==1){
				float e=nearby_entropy(@mxy,mid,old_edge_std2s,1);
				if(e<=0.0){
					me=0.0;
					mid=0;
					mxy=0;
					type=-1;
				}
			}
			/*if(type!=1){
				foreach(indices(edges),int|string id){
					array t=0;
					if(t==0){
						float me=0.0;
						int mswid;
						int msw;
						for(int v=0;v<=1;v++){
							float e=switch_entropy(id,v,old_edge_std2s);
							if(e>me){
								me=e;
								mswid=id;
								msw=v;
							}
						}
						werror("A mswid=%O\n",mswid);
						t=({me,msw,mswid});
					}
					if(t[0]>me){
						[me,msw,mswid]=t;
						werror("B mswid=%O\n",mswid);
						type=2;
					}
				}
			}*/
			if(type==1){ //改变了对某个像素所属于的类别的看法
				[int k,int x,int y]=mxy;
				werror("[%d,%d] %d -> %d\n",x,y,ms[k][x][y],mid);
				found++;
				int oldid=ms[k][x][y];
				int id=mid;
				if_change_label(PixelAtom(k,x,y),id,1,lambda(){});
				/*
				ms[k][x][y]=id;
				id2xsums[k][oldid]-=x;
				id2ysums[k][oldid]-=y;
				id2ns[k][oldid]--;
				id2xsums[k][id]+=x;
				id2ysums[k][id]+=y;
				id2ns[k][id]++;
				if(x>0){
					int k1=myencode(@sort(({oldid,ms[k][x-1][y]})));
					int k2=myencode(@sort(({id,ms[k][x-1][y]})));
					pair2counts[k][k1]--;
					pair2counts[k][k2]++;
					if(pair2counts[0][k1]==0&&pair2counts[1][k1]==0)
						edges[k1]=0;
					if(!`==(@(mydecode(k2))))
						edges[k2]=1;
				}
				if(x<w-1){
					int k1=myencode(@sort(({oldid,ms[k][x+1][y]})));
					int k2=myencode(@sort(({id,ms[k][x+1][y]})));
					pair2counts[k][k1]--;
					pair2counts[k][k2]++;
					if(pair2counts[0][k1]==0&&pair2counts[1][k1]==0)
						edges[k1]=0;
					if(!`==(@(mydecode(k2))))
						edges[k2]=1;
				}
				if(y>0){
					int k1=myencode(@sort(({oldid,ms[k][x][y-1]})));
					int k2=myencode(@sort(({id,ms[k][x][y-1]})));
					pair2counts[k][k1]--;
					pair2counts[k][k2]++;
					if(pair2counts[0][k1]==0&&pair2counts[1][k1]==0)
						edges[k1]=0;
					if(!`==(@(mydecode(k2))))
						edges[k2]=1;
				}
				if(y<h-1){
					int k1=myencode(@sort(({oldid,ms[k][x][y+1]})));
					int k2=myencode(@sort(({id,ms[k][x][y+1]})));
					pair2counts[k][k1]--;
					pair2counts[k][k2]++;
					if(pair2counts[0][k1]==0&&pair2counts[1][k1]==0)
						edges[k1]=0;
					if(!`==(@(mydecode(k2))))
						edges[k2]=1;
				}*/
			}
			/* 马场熵归约的基本逻辑是：把每条边视为双向的两条单向边，求所有单向边要被
			 * 表达一次的最小熵表述。在这个体系面，最原始的现象是每个点的颜色，这个点
			 * 最可能属于的色块是一种测量，边的形态是这个测量的推论，一条边在一个顶点
			 * 所属的色块已知的情况下第二个顶点属于哪个色块的概率是先验知识。之所以产
			 * 生熵归约的效果是因为对先验知识加以运用，将现象停靠在先验知识附近。 
			 * 
			 * 一条边界两边的色块位移相等是一个约束，约束本身并不会导致熵归约，相反添
			 * 加约束增加了计熵的点，约束越多熵越大。熵归约的本质是将批量现象转换成一
			 * 个同一概率解释的现象。那么色块位移相等的约束可以视为色块位移差值满足以
			 * 0为数学期望的某个正态分布，这就导致了熵归约。而添加约束应该被视为两个
			 * 熵归约合并进行，如果多个约束有因果关系，合并进行就会比分别进行的熵减少
			 * 量减少得更多。注意到上述正态分布的方差，是后验的，不符合此约束的样本如
			 * 果被归并进来导致方差上升，熵增加。所以在对约束进行表述的时候只表述数学
			 * 期望不表述方差。
			 *
			 * 如果我们考察像素熵归约的案例，我们会发现数学期望也是后验的。那么一条边
			 * 界两边的色块位移相等的表述应该被转换为：对边界两边的色块位移差作熵归约
			 * 。归约参数熵的问题，归约节点的参数，即是色块的数学期望，其熵取决于其在
			 * 全局的后验概率分布。
			 *
			 * 现在的问题是：1、马场的约束是什么？2、是否有可能使像素分块收敛于最有利
			 * 于确定位移的尺寸和位置？3、马场的远程调整分类和熵归约的近程归并如何统
			 * 一？
			 *
			 * 马场的约束是：1、将先验的相邻概率表乘以当前帧被归约到此色块的边的总数
			 * ，得到当前边期望，当前观测到的从此色块出发的各类边的计数称为当前边分布
			 * ，将当前边期望与当前边分布相等作为约束；2、对于每个色块统计其平均位移
			 * (dx,dy)，相邻色块位移相同。
			 *
			 * 概率分配的一般准则：有两个集合，每个集合的元素可以被分成N类，问这两个
			 * 集合是同一个随机变量的两次采样的概率。先将两次采样合并，统计各类出现的
			 * 概率，然后用这个概率分别计算两次采样各类元素应该出现的期望次数，将期望
			 * 次数和实测次数的差作平方和取平均。
			 *
			 * 总结规则如下：
			 *
			 * 1、在x,y,t轴方向同一个色块内的像素到不同色块的概率分配相对于坐标轴的增
			 * 量为0
			 * 2、在x,y,t轴方向同一个色块内的像素颜色分布相对于坐标轴的增量为0
			 * 3、在x,y,t轴方向同一个色块的位置相对于坐标轴的增量为0
			 *
			 * 异构网络熵归并的问题：如果将原子值和增量值时作两次观察，它们相互印证。
			 * 和同构网络一样，异构网络的每一个现象需要被归并到某一个节点，前提是这个
			 * 节点内的所有现象必须是连通的，意思是，如果缺失了其中一个可以根据其它来
			 * 恢复此节点的值。
			 *
			 * 改变对某个色块的(dx,dy)的信任
			 *
			 * 如果我们不信任某个色块的(dx,dy)的测量值，我们应该：
			 *
			 * 1、使用与这个色块相连续的周围色块的(dx,dy)值的平均值来预测这个色块的(dx,dy)
			 * 2、计算这个色块的(dx,dy)的测量值的熵
			 *
			 * 反之，如果我们信任这个色块的(dx,dy)的测量值，我们应该：
			 *
			 * 1、计这个色块的(dx,dy)的测量值的熵为0
			 * 2、计算这个色块与所有与之相连续的周围色块的位移差值(ddx,ddy)
			 * 3、对于任意连个相邻的(ddx1,ddy1),(ddx2,ddy2)，对其差值计熵
			 *
			 */
			if(type==2){
				/* 改变了对于某个边界(id1,id2)的连续性看法
					 如果我们不相信某个边界是连续的，我们应该：

					 1、对于这个边界的(ddx,ddy)计熵
					 2、在其他计算中，视这个边界为不连续

					 反之，如果我们信任某个边界时连续的，我们应该：

					 1、对于这个边界的(ddx,ddy)不计熵
					 2、对于任意与这个边界连续的边界(ddx2,ddy2)，对于(ddx2-ddx,ddy2-ddy)计熵
				 */
				//sscanf(mswid,"%d,%d",int id1,int id2);
				[int id1,int id2]=mydecode(swid);
				werror("SWITCH %s -> %d\n",mswid,msw);
				found++;
				sw[id2swidx[mswid]]=msw;
			}
			write("found=%d\n",found);
			if(!found)
				break;
		}
#endif
		for(int k=0;k<=1;k++){
			PixelRelationMap r=PixelRelationMap(w,h);
			foreach(mrf->id2sigma;int id;object ig){
				PixelNode node=PixelNode(1,1,w,h);
				for(int i=0;i<w;i++){
					for(int j=0;j<h;j++){
						if(mrf->ms[k][i][j]==id){
							node->select(0,i,j);
						}
					}
				}
				r->add(node,id);
			}
			output_image("out-mrf-"+k,({image1,image2})[k],r,"image",0);
		}
		foreach(mrf->id2sigma;int id;object sigma){
			if(sigma&&mrf->id2possigmas[0][id]&&mrf->id2possigmas[1][id]){
				//id2dx[id]=id2xsums[1][id]/n-id2xsums[0][id]/id2ns[0][id];
				//id2dy[id]=id2ysums[1][id]/n-id2ysums[0][id]/id2ns[0][id];
				id2dx[id]=mrf->id2possigmas[1][id]->avgval[0]-mrf->id2possigmas[0][id]->avgval[0];
				id2dy[id]=mrf->id2possigmas[1][id]->avgval[1]-mrf->id2possigmas[0][id]->avgval[1];
			}
		}

		for(int id=0;id<sizeof(dr->a);id++){
			if(dr->a[id]){
				[object p,object mask1,int x1,int y1,multiset flags1]=id2info[id];
				[object mask,int x0,int y0]=({mask1,x1,y1});
				out->paste_mask(p,mask,(int)(x0+id2dx[id]),(int)(y0+id2dy[id]));
				float z=0.0+dxdir*id2dx[id];
				outdeep->paste_mask(Image.Image(mask->xsize(),mask->ysize(),({128+(int)(z/w*127)})*3),mask,x0,y0);
				if(mrf->id2possigmas[1][id]==0){
					outdeep->paste_mask(Image.Image(mask->xsize(),mask->ysize(),({255,0,0})),mask,x0,y0);
				}
			}
		}
		Stdio.write_file("output/out-match.png",Image.PNG.encode(out));
		Stdio.write_file("output/out-deep.png",Image.PNG.encode(outdeep));
	}else{

		//输出结果

		/*
		array check_id2frontlist()
		{
			array res=({});
			multiset working=(<>);
			void check(int id)
			{
				if(working[id]){
					werror("loop found: %d\n",id);
				}else{
					working[id]=1;
					foreach(id2frontlist[id]||({}),int id2){
							check(id2);
					}
					res+=({id});
					working[id]=0;
				}
			};
			for(int id=0;id<sizeof(dr->a);id++){
				if(id2info[id]){
					check(id);
				}
			}
			return res;
		};
		array idlist=check_id2frontlist();
		idlist=reverse(idlist);
		*/


		/*array zlist=({});
		array idlist=({});
		for(int id=0;id<sizeof(dr->a);id++){
			if(id2info[id]){
				float z=0.0+dxdir*id2dx[id];
				zlist+=({z});
				idlist+=({id});
			}
		}
		sort(zlist,idlist);
		*/
		/*foreach(idlist,int id){
				[object p,object mask,int x0,int y0]=id2info[id];
				out->paste_mask(p,mask,x0+id2dx[id],y0+id2dy[id]);
				float z=0.0+dxdir*id2dx[id];
				outdeep->paste_mask(Image.Image(mask->xsize(),mask->ysize(),({128+(int)(z/w*127)})*3),mask,x0,y0);
		}*/

		for(int id=0;id<sizeof(dr->a);id++){
			if(dr->a[id]){
				array frontlist=id2frontlist[id]||({});
				[object p,object mask1,int x1,int y1,multiset flags1]=id2info[id];
				object big1=Image.Image(w,h,0,0,0)->paste(mask1,x1+id2dx[id],y1+id2dy[id]);
				foreach(frontlist,int id2){
					[object p2,object mask2,int x2,int y2,multiset flags2]=id2info[id2];
					object big2=Image.Image(w,h,0,0,0)->paste(mask2,x2+id2dx[id2],y2+id2dy[id2]);
					object mask_both=big1&big2;
					if(mask_both!=0){ //将p中mask_both所覆盖的部分修改为id2中的部分
						//object mask_both1=mask_both->copy(x1+id2dx[id],y2+id2dy[id],x1+id2dx[id]+p1->xsize()-1,y1+id2dy[id]+p1->ysize()-1);
						object mask_both2=mask_both->copy(
								x2+id2dx[id2],
								y2+id2dy[id2],
								x2+id2dx[id2]+p2->xsize()-1,
								y2+id2dy[id2]+p2->ysize()-1);
						p->paste_mask(p2,mask_both2,
								x2+id2dx[id2]-x1-id2dx[id],
								y2+id2dy[id2]-y1-id2dy[id]);
					}
				}
				[object mask,int x0,int y0]=({mask1,x1,y1});
				out->paste_mask(p,mask,x0+id2dx[id],y0+id2dy[id]);
				float z=0.0+dxdir*id2dx[id];
				outdeep->paste_mask(Image.Image(mask->xsize(),mask->ysize(),({128+(int)(z/w*127)})*3),mask,x0,y0);
				if(flags1["SDIFF"]){
					outdeep->paste_mask(Image.Image(mask->xsize(),mask->ysize(),({0,0,0})),mask,x0,y0);
				}
			}
		}

		Stdio.write_file("output/out-match.png",Image.PNG.encode(out));
		Stdio.write_file("output/out-deep.png",Image.PNG.encode(outdeep));
	}
}

void output_global_error(string file,object image,object r)
{
	array a=allocate(image->xsize(),allocate(image->ysize(),0.0));
	float min_diff=Math.inf,max_diff=0.0;
	float sum=0.0;
	int count=0;
	foreach(r->a;int id;object node){
		if(node){
			array val=node->info->avgval;
			foreach(node->query_selected(),[int k,int i,int j]){
				array color=image->getpixel(i,j);
				float d=diffa(val,color);
				a[i][j]=d;
				sum+=d*d;
				count++;
				min_diff=min(min_diff,d);
				max_diff=max(max_diff,d);
			}
		}
	}
	werror("global_std2=%f\n",sum/count);
	float len=max_diff-min_diff;
	if(len>0.0&&len!=Math.inf){
		object res=Image.Image(image->xsize(),image->ysize());
		for(int i=0;i<image->xsize();i++){
			for(int j=0;j<image->ysize();j++){
				res->setpixel(i,j,({(int)((a[i][j]-min_diff)*255/len)})*3);
			}
		}
		Stdio.write_file(sprintf("output/%s.png",file),Image.PNG.encode(res));
	}
}
int parse_image_main(int argc,array argv)
{
	//mapping args=Arg.parse(argv);
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];

	DECLARE_ARGUMENT_STRING("mode",mode_flag,mode_str,"=D1X|D1Y|DX|DY|RGB|NDRGB|MOVE|MERGE|EDGE\tDefault is RGB.");
	DECLARE_ARGUMENT_FLAG("test-tuned-box",test_tuned_box_flag,"");
	DECLARE_ARGUMENT_FLAG("scale",scale_flag,"");
	DECLARE_ARGUMENT_FLAG("far",far_flag,"");
	DECLARE_ARGUMENT_FLAG("deep",deep_flag,"");
	DECLARE_ARGUMENT_FLAG("using-dynamic-colorrange-cost",using_dynamic_colorrange_cost_flag,"");
	DECLARE_ARGUMENT_FLAG("range",range_flag,"");

	if(Usage.usage(args,"FILE LEVEL",2))
		return 0;

	HANDLE_ARGUMENTS();

	string target=rest[0];
	int levellimit=(int)(rest[1]);

	signal(signum("SIGINT"),lambda(){ master()->handle_error(({"sigint",backtrace()}));exit(0);});

	coprime=Choose.Coprime(256,(int)pow(2.0,levellimit));

	mode_str=upper_case(mode_str);
	mapping all=prepare_pixeldata(target,levellimit,test_tuned_box_flag,scale_flag);

	if(mode_str=="RDD2"){
		all->d0->update_cost();
		all->d1x->update_cost();
		all->d1y->update_cost();
		all->d2x->update_cost();
		all->d2y->update_cost();
		object reducer=finish_reduce(do_feed(create_fast_reducer(create_image_relation_map(all->image,levellimit,0),({all->d0,all->d1x,all->d1y,all->d2x,all->d2y}))));
		output_result(target+"-rdd2",reducer->r);
		output_image(target+"-rdd2",all->image,reducer->r,"image",0);
	}else if(mode_str=="4DIR"){
		all->d0->update_cost();
		all->dy_up->update_cost();
		all->dy_down->update_cost();
		all->dx_left->update_cost();
		all->dx_right->update_cost();
		if(using_dynamic_colorrange_cost_flag){
			all->d0->set_cost(all->d0->cost()/1);
			all->dy_up->set_cost(all->dy_up->cost()/1);
			all->dy_down->set_cost(all->dy_down->cost()/1);
			all->dx_left->set_cost(all->dx_left->cost()/1);
			all->dx_right->set_cost(all->dx_right->cost()/1);
		}
		//object reducer=parse_image("dy",all->image,({all->dy_up}),levellimit);
		object reducer=finish_reduce(do_feed(create_fast_reducer(create_image_relation_map(all->image,levellimit,0),({all->d0,all->dx_left,all->dx_right,all->dy_up,all->dy_down}))->set_using_dynamic_colorrange_cost(using_dynamic_colorrange_cost_flag)));
		if(range_flag){
			object r=PixelRelationLevel2Map(reducer->r);
			object data=RangeData(3*5,reducer->r)->set_cost((all->d0->cost()+all->dy_up->cost()+all->dy_down->cost()+all->dx_left->cost()+all->dx_right->cost()));
			werror("costval=%f\n",data->costval);
			object reducer2=finish_reduce(do_feed(create_multidata_reducer(r,({data}))));

			//output_dumpdata(target+"-dy",reducer->r);
			output_result(target+"-4dir",reducer2->r);
			output_image(target+"-4dir",all->image,reducer2->r,"image",0);

		}else if(far_flag){
			reducer->r->nearby_level2=1;
			finish_reduce(reducer);
			output_result(target+"-planes",reducer->r);
			output_image(target+"-planes",all->image,reducer->r,"image",0);

		}else if(deep_flag){
			object r=PixelRelationLevel2Map(reducer->r);
			object data=MinMaxData(3*5,reducer->r)->set_cost((all->d0->cost()+all->dy_up->cost()+all->dy_down->cost()+all->dx_left->cost()+all->dx_right->cost())*2);
			werror("costval=%f\n",data->costval);
			object reducer2=finish_reduce(do_feed(create_multidata_reducer(r,({data}))));

			//output_dumpdata(target+"-dy",reducer->r);
			output_result(target+"-4dir",reducer2->r);
			output_image(target+"-4dir",all->image,reducer2->r,"image",0);
		}else{
			output_result(target+"-4dir",reducer->r);
			output_image(target+"-4dir",all->image,reducer->r,"image",0);
		}
	}else if(mode_str=="D1X"){
		all->d1x->update_cost();
		object reducer=finish_reduce(do_feed(create_fast_reducer(create_image_relation_map(all->image,levellimit,far_flag),({all->d1x}))));
		//output_dumpdata(target+"-dx",reducer->r);
		output_result(target+"-d1x",reducer->r);
		output_result_text(target+"-d1x",reducer->r);
		output_image(target+"-d1x",all->image,reducer->r,"image",0);
	}else if(mode_str=="D1Y"){
		all->d1y->update_cost();
		//object reducer=parse_image("dy",all->image,({all->dy_up}),levellimit);
		object reducer=finish_reduce(do_feed(create_fast_reducer(create_image_relation_map(all->image,levellimit,far_flag),({all->d1y}))));
		//output_dumpdata(target+"-dy",reducer->r);
		output_result(target+"-d1y",reducer->r);
		output_image(target+"-d1y",all->image,reducer->r,"image",0);
	}else if(mode_str=="PLANES"){
		all->d1x->update_cost();
		all->d1y->update_cost();
		all->d0->update_cost();

		array data_list=prepare_planes_data(target,all);
		map(data_list,"update_cost");

		object reducer=finish_reduce(do_feed(create_fast_reducer(create_image_relation_map(all->image,levellimit,far_flag),data_list)));
		//output_dumpdata(target+"-dy",reducer->r);
		output_result(target+"-planes",reducer->r);
		output_image(target+"-planes",all->image,reducer->r,"image",0);

	}else if(mode_str=="DX"){
		all->dx_left->update_cost();
		object reducer=finish_reduce(do_feed(create_fast_reducer(create_image_relation_map(all->image,levellimit,far_flag),({all->dx_left}))));
		//output_dumpdata(target+"-dx",reducer->r);
		output_result(target+"-dx",reducer->r);
		output_result_text(target+"-dx",reducer->r);
		output_image(target+"-dx",all->image,reducer->r,"image",0);
	}else if(mode_str=="DY"){
		all->dy_up->update_cost();
		//object reducer=parse_image("dy",all->image,({all->dy_up}),levellimit);
		object reducer=finish_reduce(do_feed(create_fast_reducer(create_image_relation_map(all->image,levellimit,far_flag),({all->dy_up}))));
		//output_dumpdata(target+"-dy",reducer->r);
		output_result(target+"-dy",reducer->r);
		output_image(target+"-dy",all->image,reducer->r,"image",0);
	}else if(mode_str=="RGB"||mode_str==0){
		all->d0->update_cost();
		//object reducer=parse_image("image",all->image,({all->d0}),levellimit);
		object reducer=finish_reduce(do_feed(create_fast_reducer(create_image_relation_map(all->image,levellimit,far_flag),({all->d0}))));
		//output_dumpdata(target+"-rgb",reducer->r);
		output_result(target+"-rgb",reducer->r);
		output_image(target+"-rgb",all->image,reducer->r,"image",0);
	}else if(mode_str=="NDRGB"||mode_str==0){
		all->d0->update_cost();
		all->d0->set_cost(all->d0->costval/2/*+Math.log2(2.0*all->d0->data->xsize()+2.0*all->d0->data->ysize())*/);//ln(2*w+2*h)是旋转角度熵，0到180度
		werror("cost=%f\n",all->d0->costval);
		//object reducer=parse_image("image",all->image,({all->d0}),levellimit);
		object reducer=finish_reduce(do_feed(create_nd_reducer(create_image_relation_map(all->image,levellimit,far_flag),({all->d0}))));
		//output_dumpdata(target+"-rgb",reducer->r);
		output_result(target+"-ndrgb",reducer->r);
		output_image(target+"-ndrgb",all->image,reducer->r,"image",0);
		output_global_error(target+"-globalerror",all->image,reducer->r);
	}else if(mode_str=="NDDX"){
		all->dx_left->update_cost();
		all->dx_left->set_cost(all->dx_left->costval/2/*+Math.log2(2.0*all->dx_left->data->xsize()+2.0*all->dx_left->data->ysize())*/);//ln(2*w+2*h)是旋转角度熵，0到180度
		werror("cost=%f\n",all->dx_left->costval);
		//object reducer=parse_image("image",all->image,({all->dx_left}),levellimit);
		object reducer=finish_reduce(do_feed(create_nd_reducer(create_image_relation_map(all->image,levellimit,far_flag),({all->dx_left}))));
		//output_dumpdata(target+"-rgb",reducer->r);
		output_result(target+"-nddx",reducer->r);
		output_image(target+"-nddx",all->image,reducer->r,"image",0);
	}else if(mode_str=="NDDY"){
		all->dy_up->update_cost();
		all->dy_up->set_cost(all->dy_up->costval/2/*+Math.log2(2.0*all->dy_up->data->xsize()+2.0*all->dy_up->data->ysize())*/);//ln(2*w+2*h)是旋转角度熵，0到180度
		werror("cost=%f\n",all->dy_up->costval);
		//object reducer=parse_image("image",all->image,({all->dy_up}),levellimit);
		object reducer=finish_reduce(do_feed(create_nd_reducer(create_image_relation_map(all->image,levellimit,far_flag),({all->dy_up}))));
		//output_dumpdata(target+"-rgb",reducer->r);
		output_result(target+"-nddy",reducer->r);
		output_image(target+"-nddy",all->image,reducer->r,"image",0);
	}
#ifndef REMOVE_CONT_IN_ENTROPYINFO
	else if(mode_str=="MOVE"){
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
	}
#endif
	else if(mode_str=="EDGE"){
		//all->d0->update_cost();
		[object d0,object dx_left,object dx_right,object dy_up,object dy_down]=({all->d0,all->dx_left,all->dx_right,all->dy_up,all->dy_down});
		dx_left->set_cost(0); dx_right->set_cost(0); dy_up->set_cost(0); dy_down->set_cost(0);
		//d0->set_cost(ICOLOR+12*3*2);//XXX: why
		object gr=d0->global_range();
		float icolor=gr->atom_entropy();
		werror("icolor=%O\n",icolor);
#ifndef OLDMERGE
		d0->set_cost(/*icolor+*/
				(icolor+3+(/*Math.log2(0.0+d0->data->xsize())+*/1)*3)+
				(icolor+3+(/*Math.log2(0.0+d0->data->ysize())+*/1)*3)); 
		//本来应该是 ICOLOR*2+IDX+IDY 但所有边界都被两边解释，意味着全局只需要一个ICOLOR来表示基准值，每个聚合类需要一个ICOLOR来表示范围，dx,dy用分数表示，分子熵为icolor+3，3为符号位；分母熵为(Math.log2(WIDIT_OR_HEIGHT)+1)*3，理由如下：如果dx,dy的精度精细到跨越整个图像范围也不改变0.5个点的值，那么dx,dy叠加考虑，跨越整个图像范围，也不会改变1个点的值，精细到超过这个程度就没有意义，因此最大的精细度是1/WIDIT_OR_HEIGHT/2，所以小数点以后的位数的熵为ln(WIDIT_OR_HEIGHT)+1，小数点以前的熵是ICOLOR/3，因为ICOLOR是三色总计，再加上一个符号位，然后总体乘3。
		//使用using_dynamic_colorrange_cost，表示范围的icolor会动态计算
		//使用using_dynamic_dxdy_precision_cost，上述依赖于色块宽度高度的小数部分会动态计算。
#else
		d0->set_cost(icolor+
				(icolor+3+(Math.log2(0.0+d0->data->xsize())+1)*3)+
				(icolor+3+(Math.log2(0.0+d0->data->ysize())+1)*3)); 
#endif
		d0->set_weight(1);
		object reducer=finish_reduce(do_feed(create_plane_reduce(create_edge_relation_map(all->image,levellimit),({/*dx_left,dy_up,dx_right,dy_down*/}),d0,dx_left,dy_up)));
		output_result(target+"-edge",reducer->r);
		output_image2(target+"-edge",all->image,reducer->r,"image",0);
	}else if(mode_str=="BOX"){
		/* 口子形的归约元，同时做r归约和dx,dy归约 
			 每个归并结果被视为斜面，r范围约束其边界，用于预测
		 */
		all->d0->update_cost();
		all->dx_internal->update_cost();
		all->dy_internal->update_cost();
		if(using_dynamic_colorrange_cost_flag){
			all->d0->set_cost(all->d0->cost()/1);
			all->dx_internal->set_cost(all->dx_internal->cost()/1);
			all->dy_internal->set_cost(all->dy_internal->cost()/1);
		}
		object reducer=finish_reduce(do_feed(create_multidata_reducer(create_box_relation_map(all->image,levellimit),({all->d0,all->dx_internal,all->dy_internal}))->set_using_dynamic_colorrange_cost(using_dynamic_colorrange_cost_flag)));
		output_result(target+"-box",reducer->r);
		output_image2(target+"-box",all->image,reducer->r,"image",0);
	}
}
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
#ifndef REMOVE_CONT_IN_ENTROPYINFO
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
#endif
int security_main(int argc,array argv)/*{{{*/
{

	//mapping args=Arg.parse(argv);
	mapping args=Arg.parse(argv)+([0:argv[0]]);
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
int test_eig_main(int argc,array argv)/*{{{*/
{
	write("%O",eig(({({1.0,0.0}),({0.0,1.0})})));
	write("%O",eig(({({1.0,1.0}),({1.0,1.0})})));
}/*}}}*/

int main(int argc,array argv)/*{{{*/
{
	//mapping args=Arg.parse(argv);
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];

	DECLARE_ARGUMENT_EXECUTE("parse-image",parse_image_main,"")
	DECLARE_ARGUMENT_EXECUTE("match-image",match_image_main,"")
	DECLARE_ARGUMENT_EXECUTE("security",security_main,"")
	DECLARE_ARGUMENT_EXECUTE("test-spliter",test_spliter_main,"")
	DECLARE_ARGUMENT_EXECUTE("test-empty-mask",test_empty_mask_main,"")
	DECLARE_ARGUMENT_EXECUTE("test-eig",test_eig_main,"")

	if(Usage.usage(args,"",0)){
		return 0;
	}

	HANDLE_ARGUMENTS();
}/*}}}*/