#include <assert.h>
void testgroup_1d256(function f)/*{{{*/
{
	for(int i=0;i<256;i++){
		f(i);
	}
}/*}}}*/
void testgroup_2d256(function f)/*{{{*/
{
	for(int i=0;i<256;i++){
		for(int j=0;j<256;j++){
			f(i,j);
		}
	}
}/*}}}*/

object image_over(object a,object b)/*{{{*/
{
	//要比较a,b哪个大，做(a|b)-b
	//含义是：先将a中比b小的部分提高到和b一样
	//然后减去b，剩下的是大的，大多少
	return (a|b)-b;
}/*}}}*/
void test_image_over(int n,int m)/*{{{*/
{
	object ob=Image.Image(1,1,({n,n,n}));
	object b=Image.Image(1,1,({m,m,m}));
	object res=image_over(ob,b);
	if(res->getpixel(0,0)[0]!=max(0,n-m)){
		werror("%d over %d = %d, got %d\n",n,m,max(0,n-m),res->getpixel(0,0)[0]);
	}
}/*}}}*/
void test_image_over_group()/*{{{*/
{
	testgroup_2d256(test_image_over);
}/*}}}*/

object div_mult_255(object a,int|array b)/*{{{*/
{
	if(intp(b))
		b=({b,b,b});
	object res=image_over(a,Image.Image(a->xsize(),a->ysize(),b[0]-1,b[1]-1,b[2]-1))*255.0;
	int flag;
	array mask=({0,0,0});
	for(int i=0;i<sizeof(b);i++){
		if(b[i]==0){
			flag=1;
			mask[i]=0xff;
		}
	}
	if(flag){
		res=res|mask;
	}
	return res;

}/*}}}*/
void test_div_mult_255(int n)/*{{{*/
{
	object ob=Image.Image(1,1,({n,n-1,0}));
	object res=div_mult_255(ob,n);
	if(res->getpixel(0,0)[0]!=255){
		werror("%d error1 want 255 got %d\n",n,res->getpixel(0,0)[0]);
	}
	if(res->getpixel(0,0)[1]!=0&&n>0){
		werror("%d error2 want 0 got %d\n",n,res->getpixel(0,0)[1]);
	}
}/*}}}*/
void test_div_mult_255_group()/*{{{*/
{
	testgroup_1d256(test_div_mult_255);
}/*}}}*/

object scale_255_to(object a,int n)/*{{{*/
{
	return a*({n,n,n});
}/*}}}*/
void test_scale_255_to(int n)/*{{{*/
{
	object ob=Image.Image(1,1,({255,254,0}));
	object res=scale_255_to(ob,n);
	if(res->getpixel(0,0)[0]!=n){
		werror("%d error1 want %d got %d\n",n,0,res->getpixel(0,0)[0]);
	}
	if(res->getpixel(0,0)[1]==n&&n!=0){
		werror("%d error2 want %d got %d\n",n,n,res->getpixel(0,0)[1]);
	}
}/*}}}*/
void test_scale_255_to_group()/*{{{*/
{
	testgroup_1d256(test_scale_255_to);
}/*}}}*/

#if 0
object div(object a,int n)/*{{{*/
{
	return a/n;
}/*}}}*/
void test_div(int n,int m)/*{{{*/
{
	object ob=Image.Image(1,1,({n,n,n}));
	object res=div(ob,m);
	if(res->getpixel(0,0)[0]!=n/m){
		werror("%d/%d=%d got %d\n",n,m,n/m,res->getpixel(0,0)[0]);
	}
}/*}}}*/
void test_div_group()/*{{{*/
{
	for(int i=0;i<255;i++){
		for(int j=i;j<255;j++){
			if(j!=0)
				test_div(i,j);
		}
	}
}/*}}}*/
#endif

object mod(object a,int n)/*{{{*/
{
	return a%n;
}/*}}}*/
void test_mod(int n,int m)/*{{{*/
{
	if(m!=0){
		object ob=Image.Image(1,1,({n,n,n}));
		object res=mod(ob,m);
		if(res->getpixel(0,0)[0]!=n%m){
			werror("%d%%%d=%d got %d\n",n,m,n%m,res->getpixel(0,0)[0]);
		}
	}
}/*}}}*/
void test_mod_group()/*{{{*/
{
	testgroup_2d256(test_mod);
}/*}}}*/

object mult(object a,int n)/*{{{*/
{
	return a*(1.0*n);
}/*}}}*/
void test_mult(int n,int m)/*{{{*/
{
	object ob=Image.Image(1,1,({n,n,n}));
	object res=mult(ob,m);
	if(res->getpixel(0,0)[0]!=min((n*m),255)){
		werror("%d*%d=%d (,%d) got %d\n",n,m,n*m,min((n*m),255),res->getpixel(0,0)[0]);
	}
}/*}}}*/
void test_mult_group()/*{{{*/
{
	testgroup_2d256(test_mult);
}/*}}}*/

object image_filter_gteq(object a,int n)/*{{{*/
{
	object mask=div_mult_255(a,n);
	/*if(n==255){
		werror("m=%O",mask->getpixel(0,0));
		werror("a&m=%O",(a&mask)->getpixel(0,0));
	}*/
	return a&mask;
}/*}}}*/
object image_filter_lteq(object a,int n)/*{{{*/
{
	object mask=div_mult_255(a,n+1);
	mask=mask->invert();
	return a&mask;
}/*}}}*/
void test_image_filter_lteq()/*{{{*/
{
	object ob=Image.Image(100,100,({0,254,255}));
	object res=image_filter_lteq(ob,254);
	if(!equal(res->getpixel(0,0),({0,254,0}))){
		werror("want %O got %O\n",({0,254,0}),res->getpixel(0,0));
	}
}/*}}}*/
void test_image_filter_gteq()/*{{{*/
{
	object ob=Image.Image(100,100,({0,254,255}));
	object res=image_filter_gteq(ob,254);
	if(!equal(res->getpixel(0,0),({0,254,255}))){
		werror("want %O got %O\n",({0,254,255}),res->getpixel(0,0));
	}
}/*}}}*/

void test_image_add_255(int a,int b)/*{{{*/
{
	object aa=Image.Image(100,100,({a,a,a}));
	object bb=Image.Image(100,100,({b,b,b}));
	[object res,object carry]=image_add_255(aa,bb);

	int resval=res->getpixel(0,0,0)[0];
	int carryval=carry->getpixel(0,0,0)[0];
	if(resval!=(a+b)%255||carryval!=(a+b)/255){
		werror("%d+%d=%d,%d got %d,%d\n",a,b,(a+b)/255,(a+b)%255,carryval,resval);
	}
}/*}}}*/
void test_image_add_255_group()/*{{{*/
{
	test_image_add_255(1,2);
	test_image_add_255(128,128);
	test_image_add_255(128,129);
	test_image_add_255(254,254);
	test_image_add_255(255,254);
}/*}}}*/

void test_image_integer_add(int a,int b)/*{{{*/
{
	object aa=ImageInteger(100,100)+Image.Image(100,100,({a,a,a}));
	object bb=ImageInteger(100,100)+Image.Image(100,100,({b,b,b}));
	object res=image_integer_add(aa,bb);

	int resval=res->getpixel(0,0,0)[0];
	if(resval!=a+b){
		werror("%d+%d=%d (,%d) got %d\n",a,b,a+b,(a+b)%255,resval);
	}
}/*}}}*/
void test_image_integer_add_group()/*{{{*/
{
	test_image_integer_add(1,2);
	test_image_integer_add(128,128);
	test_image_integer_add(128,129);
	test_image_integer_add(254,254);
	test_image_integer_add(255,254);
}/*}}}*/

void test_setpixel()/*{{{*/
{
	object aa=ImageInteger(100,100);
	aa->setpixel(0,0,-1000,0,1000);
	if(!equal(aa->getpixel(0,0),({-1000,0,1000}))){
		werror("got %O\n",aa->getpixel(0,0));
	}
}/*}}}*/

void test_min_max()
{
	object aa=ImageInteger(100,100);
	for(int i=0;i<100;i++){
		for(int j=0;j<100;j++){
			aa->setpixel(i,j,i*100-j*100,j*100-i*100,0);
		}
	}
	//aa->setpixel(0,0,0*100-2*100,0,0);
	//aa->setpixel(0,0,-300,300,0);
	//aa->setpixel(0,1,300,-300,0);
	//werror("TT=%d\n",aa->getpixel(0,0)[0]);
	werror("%O",aa->min());
	werror("%O",aa->max());
}
void test_min_max2()
{
	object aa=ImageInteger(100,100);
	object image=Image.Image(100,100,50,50,50);
	object mask=Image.Image(100,100,255,255,255);
	for(int i=0;i<100;i++){
		image->setpixel(i,i,20+i,20+i/2,20+i/3);
	}
	aa+=image;

	werror("%O",image->min());
	werror("%O",aa->min(mask));

	werror("%O",image->max());
	werror("%O",aa->max(mask));
}

void test_invert()
{
	object image0=Image.BMP.decode(Stdio.read_file("picture.bmp"))->scale(128,128);
	object ob=ImageInteger(image0->xsize(),image0->ysize());
	ob->a+=({image0});
	object ob1=ob->invert();
	Stdio.write_file("out.bmp",Image.BMP.encode(ob1->a[0]));
}

void test_delta()
{
	object image0=Image.Image(100,100)->random();
	object dx=ImageInteger(image0->xsize()-1,image0->ysize())+image0->copy(0,0,image0->xsize()-2,image0->ysize()-1);
	dx-=image0->copy(1,0,image0->xsize()-1,image0->ysize()-1);
	for(int i=0;i<99;i++){
		for(int j=0;j<99;j++){
			array left=image0->getpixel(i,j);
			array right=image0->getpixel(i+1,j);
			array delta=dx->getpixel(i,j);
			if(delta[0]!=left[0]-right[0]){
				werror("%d-%d=%d got %d\n",left[0],right[0],left[0]-right[0],delta[0]);
			}
		}
	}

}

//255进制，返回({结果，进位}) 0xfe+0x03=({0x02,0x01})
array image_add_255(object left,object right)/*{{{*//*{{{*/
{
	object res=left+right;
	object carry=scale_255_to(res,1);
	object mask=carry*255.0;

	object delta=right->invert();	//delta=0xfe-x
	object beyond255=image_over(left,delta);
	res=res-mask+beyond255;

	return ({res,carry});
}/*}}}*//*}}}*/

#if 0
//返回({结果，进位}) 0xff+0x03=({0x02,0x01})
array image_add(object left,object right)/*{{{*/
{
	object delta=right->invert();	//delta=0xff-x=0x100-1-x
	//如果我们先把delta做+1，对于x==0的情况我们是得不到256这个数的
	//我们想要的是y>0x100-x，现在只能得到y>0x100-1-x
	//可以做254进制计算

	object beyond255=image_over(left,delta); //y > 0x100-1-x
	object carry=(beyond255&({1,1,1}));
	object mask_hi=carry->change_color(1,1,1,255,255,255);	//只要非0，就扩大到255
	object beyond256=beyond255*({254,254,254});	// * 254/255 等于 sub 1
	object mask_low=mask_hi->invert();
	object tmp=(left&mask_low)+(right&mask_low);
	object res=tmp+beyond256;
	//werror("left: %O right %O result %O carry %O T %O\n",left->getpixel(0,0)[0],right->getpixel(0,0)[0],res->getpixel(0,0)[0],carry->getpixel(0,0)[0],
			//(beyond255/(1.0/255))->getpixel(0,0)[0]);
	return ({res,carry});
}/*}}}*/
#endif

object image_integer_add(object lhd,object rhd)/*{{{*/
{
	if(lhd->width!=rhd->width||lhd->height!=rhd->height)
		throw(({"size not match.\n",backtrace()}));
	object res=ImageInteger(lhd->width,lhd->height);
	array res_a=({});
	object res_sig;
	object carry=lhd->zero;
	int length=max(sizeof(lhd->a),sizeof(rhd->a));
	array a1=lhd->a+({lhd->sig})*(length-sizeof(lhd->a));
	array a2=rhd->a+({rhd->sig})*(length-sizeof(rhd->a));
	object sig1=lhd->sig;
	object sig2=rhd->sig;
	for(int i=0;i<length;i++){
		object left=a1[i];
		object right=a2[i];
		
		
		[object res1,object carry1]=image_add_255(left,right);
		[object res2,object carry2]=image_add_255(res1,carry);
		carry=carry1+carry2;
		/*
		[object res2,object carry]=image_add_255(left,right+carry);
		*/
		res_a+=({res2});
	}
	//以下是关于256进制的讨论，现已改用256进制
	//如果最终发生了进位
	//如果两个数都为正，直接进位
	//	1+0+0=1			mod 256 =1
	//如果一正一负，结果为正；未发生进位结果为负
	//	1+0xff=0x100		mod 256 =0
	//如果都为负数，直接忽略掉进位
	//	1+0xff+0xff=0x1ff	mod 256=ff
	//综上：把进位和两个符号位加起来对256取模

	//以下是关于255进制的讨论
	//两个数相加，只可能进1位，所有所有的可能性枚举入校
	//	进位	sig1	sig2	求和	255进制表述	符号	数值进位
	//	0	0	0	0	0,0		+	0
	//	0	0	254	254	0,254		-	0
	//	0	254	254	508	1,253		-	0
	//	1	254	254	509	1,254		-	1
	//	1	254	0	255	1,0		+	0
	//	1	0	0	1	0,1		+	1
	object left=sig1;
	object right=sig2;
	[object res1,object carry1]=image_add_255(left,right);
	[object res2,object carry2]=image_add_255(res1,carry);
	/*
	[object res2,object carry2]=image_add_255(left,right+carry);
	*/

	//werror("res2=%O",res2->getpixel(0,0));

	//获取进位，carry2==1&&res2=254||res2=1
	carry=image_filter_gteq(carry2,1)&
		(scale_255_to(div_mult_255(image_filter_gteq(res2,254),254),1))
		|image_filter_gteq(image_filter_lteq(res2,1),1);
	if(carry!=lhd->zero){
		res_a+=({carry});
	}
	//要获得符号，去掉1，把0xfd提升到0xfe
	res_sig=scale_255_to(div_mult_255(res2,128),254);
	res->a=res_a;
	res->sig=res_sig;
	return res;
}/*}}}*/

int shift_sum(mixed ... args)/*{{{*/
{
	//werror("%O\n",args);
	int res;
	foreach(args,int n)
		res=(res*255)+n;
	return res;
}/*}}}*/
array shift_sign(array sigval,array val,int n){/*{{{*/
	int limit=(int)pow(255.0,n);
	array res=({});
	for(int i=0;i<3;i++){
		if(sigval[i]){
			res+=({val[i]-limit});
		}else{
			res+=({val[i]});
		}
	}
	return res;
};/*}}}*/
int unsignk(int n)
{
	return (int)(ceil(log(abs(n)*1.0+1.0)/log(255.0)));
}
int unsign(int n,int k)/*{{{*/
{
	if(n>=0)
		return n;
	return (int)(pow(255.0,k)+n);
}/*}}}*/

int min_diffcount,max_diffcount;

void finish()
{
	werror("min_diffcount=%d max_diffcount=%d\n",min_diffcount,max_diffcount);
}
int mask_count(object|int mask)/*{{{*/
{
	if(intp(mask)&&mask==0)
		return 0;
	mask=mask->change_color(255,255,255,1,1,1);
	return mask->sum()[0];
}/*}}}*/

array mask_autocrop(object mask,mixed ... args)/*{{{*/
{
	object image=Image.Image(mask->xsize()+2,mask->ysize()+2,0,0,0);
	image->paste(mask,1,1);
	array range=image->find_autocrop();
	range=map(range,`-,1);
	range=map(range,max,0);
	range[2]=min(range[2],mask->xsize()-1);
	range[3]=min(range[3],mask->ysize()-1);
	return map(({mask})+args,"copy",@range);
}/*}}}*/
array mask_find_autocrop(object mask)/*{{{*/
{
	object image=Image.Image(mask->xsize()+2,mask->ysize()+2,0,0,0);
	image->paste(mask,1,1);
	array range=image->find_autocrop();
	range=map(range,`-,1);
	range=map(range,max,0);
	range[2]=min(range[2],mask->xsize()-1);
	range[3]=min(range[3],mask->ysize()-1);
	return range;
}/*}}}*/

class ImageInteger
{
	constant is_image_integer=1;
	object zero;
	object sig;
	array a=({});
	int width,height;
	int copy_offset_x,copy_offset_y;
	int copy_limit_x=Int.NATIVE_MAX,copy_limit_y=Int.NATIVE_MAX;

	object set_copy_offset(int x,int y,int|void x2,int|void y2)
	{
		copy_offset_x=x;
		copy_offset_y=y;
		if(!zero_type(x2)&&!zero_type(y2)){
			copy_limit_x=x2;
			copy_limit_y=y2;
		}
		return this;
	}

	object clone()
	{
		return normlize();
	}

	object paste_mask(object tile,Image.Image mask,int x,int y)
	{
		object res=ImageInteger(width,height);
		res->sig->paste_mask(tile->sig,mask,x,y);
		expand(sizeof(tile->a));
		for(int i=0;i<sizeof(a);i++){
			a[i]->paste_mask(tile->a[i],mask,x,y);
		}
		return this;

	}

	array getpixel(int x,int y)/*{{{*/
	{
		array sigval=sig->getpixel(x,y);
		array aa=map(reverse(a),"getpixel",x,y);
		array val=Array.sum_arrays(shift_sum,({0,0,0}),@aa);
		return shift_sign(sigval,val,sizeof(a));
	}/*}}}*/
	void expand(int size)
	{
		while(size>=sizeof(a))
			a+=({sig->clone()});
	}
	object setpixel(int x,int y,int r,int g,int b)/*{{{*/
	{
		sig->setpixel(x,y,r<0?0xfe:0,g<0?0xfe:0,b<0?0xfe:0);
		int k=predef::max(sizeof(a),unsignk(r),unsignk(g),unsignk(b));
		//werror("k=%O\n",k);
		r=unsign(r,k);g=unsign(g,k);b=unsign(b,k);

		int p=0;
		while(r||g||b||p<sizeof(a)){
			expand(p);
			a[p]->setpixel(x,y,r%255,g%255,b%255);
			r/=255;g/=255;b/=255;
			//r>>=8;g>>=8;b>>=8;
			p++;
		}
		return this;
	}/*}}}*/

	object `&(object mask)/*{{{*/
	{
		object res=ImageInteger(width,height);
		res->sig=sig&mask;
		foreach(a,object ob){
			res->a+=({ob&mask});
		}
		return res;
	}/*}}}*/
	object `|(object mask)/*{{{*/
	{
		object res=ImageInteger(width,height);
		res->sig=sig|mask;
		foreach(a,object ob){
			res->a+=({ob|mask});
		}
		return res;
	}/*}}}*/

	private int unsign_mode;
	void enter_unsign_mode()/*{{{*/
	{
		unsign_mode++;
		a+=({sig,scale_255_to(div_mult_255(sig->invert(),255),1)});
		sig=zero->clone();
	}/*}}}*/
	void leave_unsign_mode()/*{{{*/
	{
		sig=a[-2];
		a=a[..<2];
		unsign_mode--;
		if(unsign_mode<0){
			throw(({"leave_unsign_mode not match with enter_unsign_mode.\n",backtrace()}));
		}
	}/*}}}*/

	array sum()/*{{{*/
	{
		/*
		enter_unsign_mode();
		array res=map(a[-1]->sum(),predef::`-,width*height);
		for(int i=1;i<sizeof(a);i++){
			res=map(res,predef::`*,255);
			array t=a[-(i+1)]->sum();
			res=res[*]+t[*];
		}
		leave_unsign_mode();
		*/
		array res=({0,0,0});
		for(int i=0;i<width;i++){
			for(int j=0;j<height;j++){
				array color=getpixel(i,j);
				res[0]+=color[0];
				res[1]+=color[1];
				res[2]+=color[2];
			}
		}
		return res;
	}/*}}}*/
	array sumf()/*{{{*/
	{
		return map(sum(),predef::`+,0.0);
	}/*}}}*/
	array average(object|void mask)/*{{{*/
	{
		/*
		object curr=this;
		float count=0.0+width*height;
		if(mask!=0){
			count=0.0+mask_count(mask);
			array range=mask_find_autocrop(mask);
			curr=(this->copy(@range))&(mask->copy(@range));
			//curr=this&mask;
		}

		array total=curr->sum();
		array res=map(total,predef::`/,count);
		werror("average return %O\n",res);
		return res;
		*/

		mask=mask||zero->invert();

		array res=({0.0,0.0,0.0});
		int count=0;
		for(int i=0;i<width;i++){
			for(int j=0;j<height;j++){
				array color=getpixel(i,j);
				array m=mask->getpixel(i,j);
				if(m[0]==255&&m[1]==255&&m[2]==255){
					count++;
					res[0]+=color[0];
					res[1]+=color[1];
					res[2]+=color[2];
				}else if(m[0]!=0||m[1]!=0||m[2]!=0){
					throw(({"bad mask.\n",backtrace()}));
				}
			}
		}
		if(count)
			return ({res[0]/count,res[1]/count,res[2]/count});
		else
			return ({0.0,0.0,0.0});
	}/*}}}*/
	array min(object|void mask)/*{{{*/
	{
		enter_unsign_mode();
		//map(a,dump_image);

		//mask: 255表示选中
		mask=mask||zero->invert();
		object umask=mask->invert();
		array res;
		array res_array=({0,0});
		int phase=0;
		//for(int phase=0;phase<=1;phase++){
			int p=sizeof(a)-1;
			res=({});
			while(p>=0){
				//所有不要的，提升至254，所有位都是254的，是最大值，无论正负
				object t=a[p]|scale_255_to(umask,254);
				//werror("a[%d]=%O",p,a[p]->getpixel(0,0));
				//werror("t=%O",t->getpixel(0,0));
				//取最小值，如果取到了255，意味着取到了被mask标
				//注为不要的值，因为mask只会把更多的数标注为不
				//要，如果min已经取到了255，意味着那个channel就
				//没有任何值，在我们把正数负数统一处理的时候这
				//个是不成立的，所以如果取到了255，我们不处理。
				//在使用了mask以后，是有可能出现这种情况的
				res+=({t->min()});
				//werror("res[-1]=%O",res[-1]);
				//t=t->change_color(@res[-1],0,0,0);
				//需要把和最小值一样的转换为255，其它转换为0
				//invert 最小变最大，然后提升到255
				if(phase==0){
					mask=mask&div_mult_255(t->invert(),map(res[-1],lambda(int v){return 255-v;} ));
					umask=mask->invert();
				}
				//werror("mask[%d]=%O",p,mask->getpixel(0,0));
				p--;
			}
			res_array[phase]=res;
			//werror("mask[%d]=%O\n",p,mask->getpixel(0,0));
			//werror("umask[%d]=%O\n",p,umask->getpixel(0,0));
			//werror("res[%d]=%O",phase,res);
		//}
		//if(!equal(@res_array)){
			//min_diffcount++;
		//}
		//werror("res=%O",res);
		//werror("sig0=%O",sig->getpixel(0,0));
		//werror("sig=%O",(sig&mask)->max());

		leave_unsign_mode();
		array sigval=res[1];
		foreach(res[0];int i;int val){
			if(val==254)
				sigval[i]=0;
		}
		res=res[2..];

		return shift_sign(sigval,Array.sum_arrays(shift_sum,({0,0,0}),@res),sizeof(a));
	}/*}}}*/
	array max(object|void mask)/*{{{*/
	{
		enter_unsign_mode();

		//mask: 255表示选中
		mask=mask||zero->invert();
		object umask=mask->invert();
		//object mask=sig->invert()->change_color(@(sig->invert()->max()),255,255,255);
		//werror("mask=%O\n",mask->getpixel(0,0));
		array res;
		array res_array=({0,0});
		int phase=0;
		//for(int phase=0;phase<=1;phase++){
			int p=sizeof(a)-1;
			res=({});
			while(p>=0){
				//所有不要的清零，所有位都是0的，是最小值，无论正负
				object t=a[p]&mask;
				//此时调用max，会得到正确的数据，和0
				//无法区分0是表示数据抑或是不要的
				//那些不要的数据会导致在div_mult_255的时候
				//把一些错误的区域划进mask
				//用mask=mask&...来避免；在把正数负数统一处理以
				//后不存在这个问题了
				//现在走了一轮下来mask必然是对的了

				
				//werror("a[p]=%O\n",a[p]->getpixel(0,0));
				//werror("mask=%O\n",mask->getpixel(0,0));
				//werror("t=%O\n",t->getpixel(0,0));
				res+=({t->max()});
				if(phase==0){
					mask=mask&div_mult_255(t,res[-1]);
					umask=mask->invert();
				}
				//mask=(t->change_color(res[-1],255,255,255)*({1,1,1}))*255.0;
				p--;
			}
			res_array[phase]=res;
			//werror("mask[%d]=%O\n",p,mask->getpixel(0,0));
			//werror("umask[%d]=%O\n",p,umask->getpixel(0,0));
		//}
		//if(!equal(@res_array)){
			//max_diffcount++;
		//}
		leave_unsign_mode();
		array sigval=res[1];
		foreach(res[0];int i;int val){
			if(val==0)
				sigval[i]=254;
		}
		res=res[2..];
		//werror("res=%O\n",res);
		//res=map(res,replace,255,0);
		return shift_sign(sigval,Array.sum_arrays(shift_sum,({0,0,0}),@res),sizeof(a));
	}/*}}}*/

	void create(int w,int h)/*{{{*/
	{
		width=w;height=h;
		zero=Image.Image(w,h,0,0,0);
		sig=Image.Image(w,h,0,0,0);
	}/*}}}*/

	object normlize()
	{
		object res=ImageInteger(width,height);
		return res+this;
	}

	object invert()/*{{{*/
	{
		object res=ImageInteger(width,height);
		object f(object v)
		{
			//254-v
			return image_over(Image.Image(width,height,254,254,254),v);
		};
		res->sig=f(sig);
		res->a=map(a,f);
		return res;
	}/*}}}*/

	object `+(object rhd)/*{{{*/
	{
		if(!rhd.is_image_integer){
			object t=ImageInteger(rhd->xsize(),rhd->ysize());
			t->a=({rhd});
			rhd=t;
		}
		return image_integer_add(this,rhd);
	}/*}}}*/
	object `-(object rhd)/*{{{*/
	{
		if(!rhd.is_image_integer){
			object t=ImageInteger(rhd->xsize(),rhd->ysize());
			t->a=({rhd});
			rhd=t;
		}
		rhd=rhd->normlize()->invert()+Image.Image(rhd->xsize(),rhd->ysize(),1,1,1);
		return image_integer_add(this,rhd);
	}/*}}}*/

	object copy(int x1,int y1,int x2,int y2)/*{{{*/
	{
		object res=ImageInteger(x2-x1+1,y2-y1+1);
		if(x2<=copy_limit_x&&y2<=copy_limit_y){
			res->a=map(a,"copy",x1-copy_offset_x,y1-copy_offset_y,x2-copy_offset_x,y2-copy_offset_y);
			res->sig=sig->copy(x1-copy_offset_x,y1-copy_offset_y,x2-copy_offset_x,y2-copy_offset_y);
			return res;
		}else{
			abort();
		}
	}/*}}}*/

#if 0
	array linear_fit(object mask)
	{
		if(mask->xsize()!=xsize()||mask->ysize()!=ysize())
			throw(({"size not match.\n",backtrace()}));
		array x=({});
		array y1=({}),y2=({}),y3=({});
		multiset iset=(<>),jset=(<>);
		for(int i=0;i<mask->xsize();i++){
			for(int j=0;j<mask->ysize();j++){
				if(mask->getpixel(i,j)[0]){
					x+=({({1,i,j})});
					iset[i]=1;jset[j]=1;
					array color=getpixel(i,j);
					y1+=({({color[0]})});
					y2+=({({color[1]})});
					y3+=({({color[2]})});
				}
			}
		}
		if(sizeof(x)<=1)
			return ({({0,0,0}),({0,0,0}),({})});
		if(sizeof(x)==2){/*{{{*/
			array a=({});
			for(int i=0;i<mask->xsize();i++){/*{{{*/
				for(int j=0;j<mask->ysize();j++){
					if(mask->getpixel(i,j)[0]){
						array color=getpixel(i,j);
						a+=({({i,j,color})});
					}
				}
			}/*}}}*/
			array dxval=({0,0,0});
			if(a[0][0]!=a[1][0]){
				array color1=a[0][2];
				array color2=a[1][2];
				array delta=color1[*]-color2[*];
				dxval=map(delta,`/,0.0+a[0][0]-a[1][0]);
			}
			array dyval=({0,0,0});
			if(a[0][1]!=a[1][1]){
				array color1=a[0][2];
				array color2=a[1][2];
				array delta=color1[*]-color2[*];
				dyval=map(delta,`/,0.0+a[0][1]-a[1][1]);
			}
			return ({dxval,dyval,({})});
		}/*}}}*/
		if(sizeof(iset)==1){
			x=map(x,lambda(array a){return a[..0]+a[2..];});
		}
		if(sizeof(jset)==1){
			x=map(x,lambda(array a){return a[..1];});
		}
		object X=Public.Nix.Math.LinearAlgebra.NMatrix(x);
		object X1=X->transpose();
		object A=X1*X;
		object Y1=Public.Nix.Math.LinearAlgebra.NMatrix(y1);
		object Y2=Public.Nix.Math.LinearAlgebra.NMatrix(y2);
		object Y3=Public.Nix.Math.LinearAlgebra.NMatrix(y3);
		array res1,res2,res3;
		mixed e=catch{
			res1=A->solveLinearEquations(X1*Y1);
			res2=A->solveLinearEquations(X1*Y2);
			res3=A->solveLinearEquations(X1*Y3);
		};
		if(e){
			werror("X=\n%O\n",X);
			werror("Y=\n%O\n%O\n%O\n",Y1,Y2,Y3);
			throw(e);
		}
		//werror("%O",(array)res->transpose()[0]);
		//exit(0);
		if(sizeof(iset)>1&&sizeof(jset)>1){
			[int c1,int a1,int b1]=((array)res1->transpose())[0];
			[int c2,int a2,int b2]=((array)res2->transpose())[0];
			[int c3,int a3,int b3]=((array)res3->transpose())[0];
			return ({({a1,a2,a3}),({b1,b2,b3}),({c1,c2,c3})});
		}else if(sizeof(iset)==1){
			[int c1,int b1]=((array)res1->transpose())[0];
			[int c2,int b2]=((array)res2->transpose())[0];
			[int c3,int b3]=((array)res3->transpose())[0];
			return ({({0,0,0}),({b1,b2,b3}),({c1,c2,c3})});
		}else if(sizeof(jset)==1){
			[int c1,int a1]=((array)res1->transpose())[0];
			[int c2,int a2]=((array)res2->transpose())[0];
			[int c3,int a3]=((array)res3->transpose())[0];
			return ({({a1,a2,a3}),({0,0,0}),({c1,c2,c3})});
		}
	}
#endif

	int xsize(){return width;}
	int ysize(){return height;}
	void save(string file)
	{
		Stdio.write_file(file,encode_value(({width,height,sig})+a));
	}
	void load(string file)
	{
		array t=decode_value(Stdio.read_file(file));
		[width,height,sig]=t[0..2];
		zero=Image.Image(width,height,0,0,0);
		a=t[3..];
	}
}

void dump_image(object image)
{
	for(int i=0;i<image->xsize();i++){
		for(int j=0;j<image->ysize();j++){
			werror("%03d/%03d/%03d ",@image->getpixel(i,j));
		}
		werror("\n");
	}
	werror("\n");
}


void main()
{
	/*
	object ob=ImageInteger(1,1);
	ob->load("debug_dump.o");
	object mask;
	[mask]=decode_value(Stdio.read_file("debug_dump_mask.o"));
	dump_image(mask);
	dump_image(ob->sig);
	map(ob->a,dump_image);
	werror("min=%O\n",ob->min(mask));
	werror("max=%O\n",ob->max(mask));
	*/
	//test_scale_255_to_group();
	//test_div_mult_255_group();
	//test_image_over_group();
	//test_scale_255_to_group();
	//test_mod_group();
	//test_div_group(); //not work
	//test_mult_group();

	test_min_max();
	//test_setpixel();
	//test_invert();
	//test_delta();
	//test_image_filter_lteq();
	//test_image_filter_gteq();
	//test_image_add_255_group();
	//test_image_integer_add_group();
	
	/*
	int w=200,h=200;
	int v0=254;
	object a=ImageInteger(w,h,Image.Image(w,h,v0,v0,v0));
	//a+=a;
	//v0+=v0;
	for(int i=0;i<10;i++){
		//int v=random(128)+128;
		int v=random(255);
		object b=ImageInteger(w,h,Image.Image(w,h,v,v,v),0);
		//b+=b;
		//v+=v;
		werror("%d+%d=%d\n",v0,v,v0+v);
		werror("=> %d+%d=?\n",a->getpixel(0,0)[0],b->getpixel(0,0)[0]);
		v0+=v;
		a=a+b;
		werror("sum=%d ",a->getpixel(0,0)[0]);
		werror("sig=%d ",a->sig->getpixel(0,0)[0]);
		werror("sum0=%d ",a->a[0]->getpixel(0,0)[0]);
		//werror("sum1=%d ",a->a[1]->getpixel(0,0)[0]);
		werror("\n");
	}
	*/
	
	
	/*
	int w=20,h=20;
	object a=ImageInteger(w,h,);
	a->a=({Image.Image(w,h,150,150,150),Image.Image(w,h,1,1,1),});
	object b=ImageInteger(w,h,);
	b->a=({Image.Image(w,h,106,106,106),Image.Image(w,h,7,7,7),});
	object c=a+b;
	werror("%O",c->getpixel(0,0)[0]);
	*/

	/*
	int w=20,h=20;
	object a=ImageInteger(w,h,Image.Image(w,h,150,150,150),1);
	a->a=({Image.Image(w,h,150,150,150),Image.Image(w,h,1,1,1),});
	a->a[0]->setpixel(0,0,255,255,255);
	werror("%O",a->max());
	*/

	/*
	werror("-1=%x\n",unsign(-1));
	werror("-127=%x\n",unsign(-127));
	werror("-2147483648=%x\n",unsign(-2147483648));
	*/

	
	/*
	int w=20,h=20;
	object a=ImageInteger(w,h);
	a->setpixel(0,0,-2147483648,0,0);
	werror("%O",a->getpixel(0,0));
	werror("%O",a->invert()->getpixel(0,0));
	*/
	
}
