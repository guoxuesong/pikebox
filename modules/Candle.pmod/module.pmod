private class FillTool{
protected array fill_max(float maxval,multiset maxpos,float val,multiset pos)/*{{{*/
{
	if(!multisetp(pos))
		throw(({"bad pos.\n",backtrace()}));
	if(val>maxval){
		maxval=val;
		maxpos=pos;
	}else if(val==maxval){
		maxpos+=pos;
	}
	return ({maxval,maxpos});
}/*}}}*/
protected array fill_min(float minval,multiset minpos,float val,multiset pos)/*{{{*/
{
	if(!multisetp(pos))
		throw(({"bad pos.\n",backtrace()}));
	if(val<minval){
		minval=val;
		minpos=pos;
	}else if(val==minval){
		minpos+=pos;
	}
	return ({minval,minpos});
}/*}}}*/
};



class Item(int timeval){
	inherit FillTool;
	inherit Save.Save;
	
	float maxval,minval,openval,closeval;
	multiset maxpos,minpos;
	int volume;
	void feed(array hrt,float val,int vol)
	{
		if(volume==0){
			maxval=minval=openval=closeval=val;
			volume=vol;
			maxpos=(<hrt>);minpos=(<hrt>);
		}else{
			[maxval,maxpos]=fill_max(maxval,maxpos,val,(<hrt>));
			[minval,minpos]=fill_min(minval,minpos,val,(<hrt>));
			closeval=val;
			volume+=vol;
		}
	}
}


mixed save_item(object item)
{
	//return item->save();
	
	if(item->volume==0){
		return ({item->timeval});
	}else{
		return ({item->timeval,item->minval,item->maxval,item->openval,item->closeval,item->volume,item->minpos,item->maxpos});
	}
}
object load_item(mixed data)
{
	/*object item=Item(data->timeval);
	[item->minval,item->maxval,item->openval,item->closeval,item->volume]=({data->minval,data->maxval,data->openval,data->closeval,data->volume});*/
	object item=Item(data[0]);
	if(sizeof(data)>1)
		[item->minval,item->maxval,item->openval,item->closeval,item->volume,item->minpos,item->maxpos]=data[1..];
	return item;
}

#define USING_BIGARRAY
#if !constant(Gdbm)
#define USING_FAKEGDBM
#endif

class CalendarLine{/*{{{*/
	extern mixed a;
	object calendar_line(string type,int|void alter_seconds,object|void res,int|void start,int|void skiplast)/*{{{*/
	{
		mapping type2interval=(["day":3600*24,"week":3600*24*7,"month":3600*24*31,"year":3600*24*366]);
		res=res||line(type2interval[type]);
		mapping day2item=([]);
		if(sizeof(res->a)){
			object day=Calendar.ISO.Second(res->a[-1]->timeval+alter_seconds)[type]();
			int t=day->unix_time()-alter_seconds;
			day2item[t]=res->a[-1];
		}
		int i;
		for(i=start;i<sizeof(a);i++){
			object item=a[i];
			if(item&&item->volume){
				object day=Calendar.ISO.Second(item->timeval+alter_seconds)[type]();
				int t=day->unix_time()-alter_seconds;
				if(day2item[t]==0){
					day2item[t]=day2item[t]||Save.load(Item(t),item->save());
					day2item[t]->timeval=t;
					if(skiplast&&i==sizeof(a)-1){
						day2item[t]->volume=0;
					}
				}else{
					day2item[t]->minval=min(day2item[t]->minval,item->minval);
					day2item[t]->maxval=max(day2item[t]->maxval,item->maxval);
					day2item[t]->closeval=item->closeval;
					if(skiplast&&i==sizeof(a)-1){
						;
					}else{
						day2item[t]->volume+=item->volume;
					}
				}
			}
		}
		if(i<sizeof(a)){
			object item=a[i];
			object day=Calendar.ISO.Second(item->timeval+alter_seconds)[type]();
			int t=day->unix_time()-alter_seconds;
			if(day2item[t]==0){
				day2item[t]=Item(t);
			}
		}
		foreach(SortMapping.sort(day2item);int t;object item){
			if(sizeof(res->a)&&res->a[-1]->timeval==item->timeval){
				res->a[-1]=item;
			}else{
				res->a+=({item});
			}
		}
		return res;
	}/*}}}*/
	object day_line(int|void alter_seconds,object|void res,int|void start,int|void skiplast)
	{
		return calendar_line("day",alter_seconds,res,start,skiplast);
	}
	object week_line(int|void alter_seconds,object|void res,int|void start,int|void skiplast)
	{
		return calendar_line("week",alter_seconds,res,start,skiplast);
	}
	object month_line(int|void alter_seconds,object|void res,int|void start,int|void skiplast)
	{
		return calendar_line("month",alter_seconds,res,start,skiplast);
	}
	object year_line(int|void alter_seconds,object|void res,int|void start,int|void skiplast)
	{
		return calendar_line("year",alter_seconds,res,start,skiplast);
	}
}/*}}}*/

class TimevalSearch{
	extern mixed a;
	int search(int timeval)
	{
		mixed e=catch{
		return BinarySearch.search(lambda(int pos){
				return a[pos];
				},lambda(object item){
				return item->timeval;
				},timeval,0,sizeof(a));
		};
		if(e){
			if(objectp(e)&&object_program(e)==BinarySearch.Exception){
				return -1;
			}else{
				throw(e);
			}
		}
	}
}

class line(int interval)
{
	inherit CalendarLine;
	inherit TimevalSearch;
	array a=({});
	int query_timeval(int pos)
	{
		if(pos<sizeof(a)){
			return a[pos]->timeval;
		}else{
			return a[-1]->timeval+interval;
		}
	}
	void create(Stdio.FILE|void file)
	{
		if(file){
			string s=file->gets();
			while(s){/*{{{*/
				//werror("parse %s\n",s);
				int timeval;
				float minval;
				float maxval;
				float openval;
				float closeval;
				int volume;
				if(sscanf(s,"%d,%f,%f,%f,%f,%d",timeval,minval,maxval,openval,closeval,volume)==6){
					if(volume){
						//werror("ok\n");
						a+=({
								Save.load(Item(timeval),([
										"timeval":timeval,
										"minval":minval,
										"maxval":maxval,
										"openval":openval,
										"closeval":closeval,
										"volume":volume,
										]))
								});
					}
				}
				s=file->gets();
			}/*}}}*/
		}
	}
}

class Line
{
	inherit CalendarLine;
	inherit TimevalSearch;
	object db;
	BigArray.BigArray|array a;

#if 0
	mapping index;
#endif
	void create(string path,int interval,string gdbm_open_mode)
	{
#ifdef USING_BIGARRAY
#ifdef USING_FAKEGDBM
		a=BigArray.BigArray(db=FakeGdbm.gdbm(path+"/"+interval+".db"),"size",save_item,load_item);
#else
		a=BigArray.BigArray(db=MassGdbm.gdbm(path+"/"+interval+".db",gdbm_open_mode),"size",save_item,load_item);
#endif
#else
		a=decode_value(Stdio.read_file(path+"/"+interval+".db"));
#endif
#if 0
		if(!Stdio.is_file(path+"/"+interval+".idx")){
			Stdio.write_file(path+"/"+interval+".idx",encode_value(([])));
		}
		index=decode_value(Stdio.read_file(path+"/"+interval+".idx"));
#endif
	}
	void close()
	{
		db->close();
	}
}

constant all_intervals=({/*5,15,30,60,60*5,*/60*15,60*30,3600});

class Lines{
	array a;
	void create(string path,string|void gdbm_open_mode)
	{
		a=map(all_intervals,Function.curry(Line)(path),gdbm_open_mode);
	}
	object line(int interval)
	{
		int n=search(all_intervals,interval);
		if(n>=0)
			return a[n];
	}
	array locate(array hrt,int|void interval)/*{{{*/
	{
		interval=interval||all_intervals[0];
		int timeval=Time.align(hrt[0],interval);
		int timeval0=a[0]->a[0]->timeval;
		int pos=(timeval-timeval0)/interval;
		return ({all_intervals[0],pos});
	}/*}}}*/
	array scale(array pos,int delta)/*{{{*/
	{
		[int interval,int k]=pos;
		int timeval;
		if(k<sizeof(line(interval)->a))
			timeval=line(interval)->a[k]->timeval;
		else
			timeval=line(interval)->a[-k]->timeval+interval;

		int base=a[0]->a[0]->timeval;
		int p=search(all_intervals,interval);
		if(p>=0&&p-delta>=0&&p-delta<sizeof(all_intervals)){
			int detail_interval=all_intervals[p-delta];
			int detail_sn=(timeval-base)/detail_interval;
			return ({detail_interval,detail_sn});
		}
		return ({0,0});
	}/*}}}*/

#if 0
	array locate(array hrt)
	{
		int interval=all_intervals[0];

		object day=Calendar.ISO.Second(hrt[0])->day();
		object nday=(Calendar.ISO.Second(hrt[0])->day()+1);

		int timeval=Time.align(hrt[0],interval);
		int base=timeval_base(interval,day);

		int res;
		int pos=a[0]->index[day->unix_time()];
		int npos=a[0]->index[nday->unix_time()]||sizeof(a[0]->a);

		werror("pos=%O npos=%O\n",pos,npos);

		res=min(pos+(timeval-base)/interval,npos);
		return ({all_intervals[0],res});
	}
	
	int timeval_base(int interval,object day)
	{
		object aa=line(interval);
		int base=aa->a[aa->index[day->unix_time()]]->timeval;
		return base;
	}
	array scale(array pos,int delta)/*{{{*/
	{
		[int interval,int k]=pos;
		int timeval;
		if(k<sizeof(line(interval)->a))
			timeval=line(interval)->a[k]->timeval;
		else
			timeval=line(interval)->a[-k]->timeval+interval;
		object day=Calendar.ISO.Second(timeval)->day();
		int base=timeval_base(interval,day);
		int p=search(all_intervals,interval);
		if(p>=0&&p-delta>=0&&p-delta<sizeof(all_intervals)){
			int detail_interval=all_intervals[p-delta];
			int detail_sn=(timeval-base)/detail_interval;
			return ({detail_interval,detail_sn});
		}
		return ({0,0});
	}/*}}}*/
array find_scale_limit(array pos1,array pos2)/*{{{*/
{
	while(pos1[0]<pos2[0]){
		pos1=scale(pos1,-1);
	}
	while(pos2[0]<pos1[0]){
		pos2=scale(pos2,-1);
	}
	while(pos1[0]!=all_intervals[-1]&&scale(pos1,-1)[1]!=scale(pos2,-1)[1]){
		pos1=scale(pos1,-1);
		pos2=scale(pos2,-1);
	}
	return ({pos1,pos2});
}/*}}}*/
	void walk(array hrbegin,array hrend,function f)
	{
		werror("begin=%O,end=%O\n",hrbegin,hrend);

		array beginpos=locate(hrbegin);
		array endpos=locate(hrend);

		werror("beginpos=%O,endpos=%O\n",beginpos,endpos);

		[array begin_scaled,array end_scaled]=find_scale_limit(beginpos,endpos);

		array p=beginpos;
		while(!equal(p,begin_scaled)){
			while(equal(scale(scale(p,-1),1),p)&&!equal(p,begin_scaled)){
				p=scale(p,-1);
			}
			object item=line(p[0])->a[p[1]];
			f(item);
			p[1]++;
		}
		while(!equal(p,end_scaled)){
			object item=line(p[0])->a[p[1]];
			f(item);
			p[1]++;
		}
		while(!equal(p,endpos)){
			while(equal(find_scale_limit(p,endpos)[0],p)){
				p=scale(p,1);
			}
			object item=line(p[0])->a[p[1]];
			f(item);
			p[1]++;
		}
	}
#endif
	void close()
	{
		foreach(a,object line){
			line->close();
		}
	}
}

#if 0
class Wave(object lines){
	inherit FillTool;
	inherit Save.Save;
	float maxval=-Math.inf,minval=Math.inf;
	multiset maxpos=(<>),minpos=(<>);
	array begin()
	{
		return ({lines->a[0]->a[0]->timeval,0});
		//werror("%O\n" ,sizeof(lines->a[0]->a));
		//foreach(lines->a[0]->a[0]->minpos;array hrt;int one){
			//return ({hrt[0]*all_intervals[0]/all_intervals[-1],0});
		//}
	}
	array end()
	{
		return ({lines->a[0]->a[-1]->timeval+all_intervals[0],0});
	}
	void walk(array hrbegin,array hrend)
	{
		maxval=-Math.inf;minval=Math.inf;
		maxpos=(<>);minpos=(<>);

		lines->walk(hrbegin,hrend,lambda(object item)
				{
				if(item->volume){
					[maxval,maxpos]=fill_max(maxval,maxpos,item->maxval,item->maxpos);
					[minval,minpos]=fill_min(minval,minpos,item->minval,item->minpos);
				}
				});
	}
}
#endif




class Parser{
	inherit Lines;
	mapping interval2list=([]);
#if 0
	object last_hour;
	object curr_hour;
#endif
	void create(string outpath)
	{
		::create(outpath,"rwcf");
		foreach(all_intervals;int i;int interval){
			interval2list[interval]=a[i]->a;
		}
	}
#if 0
	void output(object hour,mapping interval2list)/*{{{*/
	{
		int size=sizeof(interval2list[all_intervals[-1]])*all_intervals[-1];
		foreach(all_intervals,int interval){
			while(sizeof(interval2list[interval])<size/interval){
				interval2list[interval]+=({.Item(interval2list[interval][-1]->timeval+interval)});
			}
		}
		foreach(all_intervals,int interval){
			if(last_hour==0||hour->day()!=last_hour->day()){
				object day=hour->day();
				mapping idx=interval2list[interval]->index;
				idx[day->unix_time()]=sizeof(interval2list[interval]->a);
				Stdio.write_file(outpath+"/"+interval+".idx",encode_value(idx));
			}
		}
#if 0
		foreach(all_intervals,int interval){
#ifdef USING_BIGARRAY
#ifdef USING_FAKEGDBM
			object db=FakeGdbm.gdbm(outpath+"/"+interval+".db");
#else
			object db=MassGdbm.gdbm(outpath+"/"+interval+".db","rwcf");
#endif
			object a=BigArray.BigArray(db,"size",save_item,load_item);
#else
			array a=({});
#endif
			if(last_hour==0||hour->day()!=last_hour->day()){
				object day=hour->day();
				mapping idx=([]);
				if(Stdio.is_file(outpath+"/"+interval+".idx"))
					idx=decode_value(Stdio.read_file(outpath+"/"+interval+".idx"));
				idx[day->unix_time()]=sizeof(a);
				Stdio.write_file(outpath+"/"+interval+".idx",encode_value(idx));
			}
			a+=interval2list[interval]||({});
#ifdef USING_BIGARRAY
			db->close();
#else
			Stdio.write_file(outpath+"/"+interval+".db",encode_value(a));
#endif
		}
#endif
		last_hour=hour;
	}/*}}}*/
#endif

	object last_hrt;
	int feed(array hrt,float val,int vol)
	{
		/*object ca=CompareArray.CompareArray(hrt);
		if(last_hrt&&last_hrt>ca){
			throw(({"timestamp not increase.\n",backtrace()}));
		}
		last_hrt=ca;
		*/

#if 0
		object hour=Calendar.ISO.Second(hrt[0])->hour();
		if(curr_hour==0)
			curr_hour=hour;
		if(hour!=curr_hour){
			output(curr_hour,interval2list);
			//interval2list=([]);
			curr_hour=hour;
		}
#endif
		int res=-1;

		int base=Time.align(hrt[0],all_intervals[-1]);
		foreach(all_intervals;int level;int interval){
			int curr=Time.align(hrt[0],interval);
			//interval2list[interval]=interval2list[interval]||({.Item(base)});
			if(sizeof(interval2list[interval])==0){
				interval2list[interval]->`+=(({.Item(base)}));
				res=level;
			}
			while(interval2list[interval][-1]->timeval<curr){
				interval2list[interval]->`+=(({.Item(interval2list[interval][-1]->timeval+interval)}));
				res=level;
			}
			[int ig,int pos]=locate(hrt,interval);
			//if(pos==sizeof(interval2list[interval])-1){
				object item=interval2list[interval][pos];
				//werror("item=%O\n",item->save());
				item->feed(hrt,val,vol);;
				interval2list[interval][pos]=item;
			//}else{
				//werror("ignore old data.\n");
			//}
		}
		return res;
	}
	void drain()
	{
#if 0
		output(curr_hour,interval2list);
#endif
		//close();
	}
}

void test_create()
{
	object parser=Parser(".");
	int timebase=Time.align(time(),3600);
	float price=1000.0;
	for(int i=0;i<20;i++){
		parser->feed(({timebase+i*3600/100,0}),price,1);
		price-=1.0;
	}
	for(int i=20;i<90;i++){
		parser->feed(({timebase+i*3600/100,0}),price,1);
		price+=1.0;
	}
	for(int i=90;i<100;i++){
		parser->feed(({timebase+i*3600/100,0}),price,1);
		price-=1.0;
	}
	parser->drain();
	parser->close();
}

#if 0
void test_wave()
{
	object w=Wave(Lines("."));
	w->walk(w->begin(),w->end());
	werror("%O\n",w->save());
}
#endif

class ParseFile(string savepath,function id_filter,function on_advance,object|void logfile){
	mapping parsers=([]);
	void parse(object file)
	{
		string s=file->gets();
		while(s){
			sscanf(s,"%s,%d,%d,%f,%d",string inst,int sec,int usec,float val,int vol);
			string accept="-";
			if(/*all_flag&&inst!=""||has_prefix(inst,prefix)*/id_filter(inst)){
				if(parsers[inst]==0){
					mkdir(savepath+"/"+inst);
					parsers[inst]=Parser(savepath+"/"+inst);
				}
				int level=parsers[inst]->feed(({sec,usec}),val,vol);
				if(level>=0)
					on_advance(level);
				accept="o";
				//werror("o\n");
			}else{
				accept="x";
				//werror("x\n");
			}
			(logfile||Stdio.stderr)->write(sprintf("%s,%s\n",s,accept));
			(logfile||Stdio.stderr)->sync();
			s=file->gets();
		}
		foreach(parsers;string inst;object parser)
			parser->drain();
	}
	void close()
	{
		foreach(parsers;string inst;object parser)
			parser->close();
	}
}

#include <args.h>
int collect_main(int argc,array argv)
{
	mapping args=Arg.parse(argv);
	if(Usage.usage(argv,"",0)){
		werror(
#" -h,  --help          Show this help.
 [--has-prefix=PREFIX]
 [--all]
 --save-path=PATH
");
		return 0;
	}
	ARGUMENT_STRING("has-prefix",has_prefix_flag,prefix)
	ARGUMENT_FLAG("all",all_flag)
	REQUIRED ARGUMENT_STRING("save-path",path_flag,savepath)

	object pf=ParseFile(savepath,lambda(string inst){
			return all_flag&&inst!=""||has_prefix(inst,prefix);
			},lambda(){});
	pf->parse(Stdio.stdin);
	pf->close();
}

private object create_line(object lines,string interval)
{
	object line;
	if(interval=="day"){
		line=lines->a[-1]->day_line(0,0,0,0);
	}else if(has_prefix(interval,"day+")){
		sscanf(interval,"day+%d",int m);
		line=lines->a[-1]->day_line(-3600*m,0,0,0);
	}else if(interval=="week"){
		line=lines->a[-1]->week_line(0,0,0,0);
	}else if(has_prefix(interval,"week+")){
		sscanf(interval,"week+%d.%d",int n,int m);
		line=lines->a[-1]->week_line(-3600*24*n-3600*m,0,0,0);
	}else if(interval=="month"){
		line=lines->a[-1]->month_line(0,0,0,0);
	}else if(has_prefix(interval,"month+")){
		sscanf(interval,"month+%d.%d",int n,int m);
		line=lines->a[-1]->month_line(-3600*24*n-3600*m,0,0,0);
	}else{
		line=lines->line((int)interval);
	}
	return line;
};

int draw_main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	DECLARE_ARGUMENT_STRING_REQUIRED("inst",inst_flag,inst,"=INST");
	DECLARE_ARGUMENT_STRING_REQUIRED("interval",interval_flag,interval,"=SECONDS|'DAY'[+N]|'WEEK'[+N[.N]]|'MONTH'[+N[.N]]\tExample WEEK+3.8 for btc123");
	DECLARE_ARGUMENT_STRING_REQUIRED("path",path_flag,savepath,"=PATH");
	DECLARE_ARGUMENT_INTEGER("screen-width",screen_width_flag,screen_width_val,"=N");
	DECLARE_ARGUMENT_STRING_LIST("exclude",exclude_flag,exclude_days,"=DAY:...");
	DECLARE_ARGUMENT_INTARRAY_LIST("concept-list",concept_list_flag,concept_list,"=TIMEEND,TIMEEND:...");
	DECLARE_ARGUMENT_FLAG("kdj",kdj_flag,"");
	DECLARE_ARGUMENT_FLAG("ockdj",ockdj_flag,"");
	if(Usage.usage(args,"",0)){
		return 0;
	}
	HANDLE_ARGUMENTS();

	multiset days=(<>);
	if(exclude_flag){
		days=(multiset)map(exclude_days,Calendar.ISO.dwim_day);
	}

	multiset split_point=(<>);
	if(concept_list_flag){
		foreach(concept_list,array a){
			split_point[a[0]]=1;
		}
	}
	
	object lines=Lines(savepath+"/"+inst,"r");
	interval=lower_case(interval);
	object line=create_line(lines,interval);
	float maxval=-Math.inf,minval=Math.inf;
	//werror("sizeof(line->a)=%d",sizeof(line->a));
	foreach(line->a;int j;object item)
	{
		if(days[Calendar.ISO.Second(item->timeval)->day()])
			continue;
		object item=line->a[j];
		if(item->volume){
			//werror("%d\n",j);
			//werror("item=%O\n",item->save());
			minval=min(minval,item->minval);
			maxval=max(maxval,item->maxval);
		}
	}

	object kdj=KDJ.KDJ();
	int hold,last_hold;
	int kdj_width=15;
	string print_curr_kdj()/*{{{*/
	{
		[object ltm,float lk,float ld,float lj]=kdj->query(1);
		[object tm,float k,float d,float j]=kdj->query();
		int upflag=k>d;
		int gx=k>d&&lk<ld;
		int dx=k<d&&lk>ld;
		last_hold=hold;
		hold=dx||upflag&&!gx;

		string res="";
		array vals=({k,d,j});
		array keys=({"k","d","j"});
		sort(vals,keys);
		vals[2]-=vals[1];
		vals[1]-=vals[0];
		foreach(vals;int i;float v){
			res+=" "*(min(10,max(0,(int)(v*10))))+keys[i];
		}
		//return sprintf("%-13s%s %0.2f,%0.2f,%0.2f ",res,hold?"o":"x",k,d,j);
		return sprintf("%-13s%s ",res,hold?"h":" ");
	};/*}}}*/

	int header_size=(sizeof(sprintf("%s",Calendar.ISO.Second(line->a[0]->timeval)->format_time_short()))+1);
	int screen_width=screen_width_val||80;
	int working_width=screen_width-header_size;
	if(kdj_flag||ockdj_flag) working_width-=kdj_width;
	float scale=working_width/(maxval-minval);


	foreach(line->a;int j;object item)
	{
		if(days[Calendar.ISO.Second(item->timeval)->day()])
			continue;

		if(item->volume){ //XXX: 看来volume==0的时候timeval可能不对
			if(split_point[item->timeval]){
				werror("item->timeval=%d\n",item->timeval);
				write("\n");
			}
		}

		//object item=line->a[j];
		float minval_scaled=(item->minval-minval)*scale;
		float maxval_scaled=(item->maxval-minval)*scale;
		float openval_scaled=(item->openval-minval)*scale;
		float closeval_scaled=(item->closeval-minval)*scale;

		openval_scaled=max(minval_scaled,openval_scaled);
		closeval_scaled=max(minval_scaled,closeval_scaled);

		if(item->volume){

			if(kdj_flag){
				kdj->feed(Calendar.ISO.Second(item->timeval),item->openval,item->closeval,item->maxval,item->minval);
			}else if(ockdj_flag){
				kdj->feed(Calendar.ISO.Second(item->timeval),item->openval,item->closeval,max(item->openval,item->closeval),min(item->openval,item->closeval));
			}

			string color,bcolor;
			if(item->closeval>item->openval){
				color=Ansi.RED;
				bcolor=Ansi.BRED;
			}else{
				color=Ansi.GRN;
				bcolor=Ansi.BGRN;
			}
			write("%s ",Calendar.ISO.Second(item->timeval)->format_time_short());
			if(kdj_flag||ockdj_flag){
				write("%s ",print_curr_kdj());
			}
			int i=0;
			while(i<minval_scaled){ write(" "); i++; }
			write("%s",color);
			while(i<openval_scaled&&i<closeval_scaled){ write("-"); i++; }
			int flag;
			while(i<openval_scaled||i<closeval_scaled){ write(bcolor+" "+Ansi.BBLK); i++; flag=1; }
			if(flag==0){ write("|"); i++; }
			while(i<maxval_scaled){ write("-"); i++; }
			write(Ansi.NOR+"\n");
		}
	}
	werror("minval=%f maxval=%f scale=%f (%f pt/blk)\n",minval,maxval,scale,1/scale);
}

int dump_main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	DECLARE_ARGUMENT_STRING_REQUIRED("inst",inst_flag,inst,"=INST")
	DECLARE_ARGUMENT_STRING_REQUIRED("interval",interval_flag,interval,"=SECONDS|'DAY'[+N]|'WEEK'[+N[.N]]|'MONTH'[+N[.N]]\tExample WEEK+3.8 for btc123")
	DECLARE_ARGUMENT_STRING_REQUIRED("path",path_flag,savepath,"=PATH")
	DECLARE_ARGUMENT_FLAG("nice-print",nice_print_flag,"")
	if(Usage.usage(args,"",0)){
		return 0;
	}
	HANDLE_ARGUMENTS();

	object lines=Lines(savepath+"/"+inst,"r");
	interval=lower_case(interval);
	object line=create_line(lines,interval);
	foreach(line->a;int j;object item)
	{
		object item=line->a[j];
		if(nice_print_flag){
			write("%s,%f,%f,%f,%f,%d\n",Calendar.ISO.Second(item->timeval)->format_time_short(),item->minval,item->maxval,item->openval,item->closeval,item->volume);
		}else{
			write("%d,%f,%f,%f,%f,%d\n",item->timeval,item->minval,item->maxval,item->openval,item->closeval,item->volume);
		}
	}
}
int main(int argc,array argv)
{
	if(Usage.usage(argv,"CMD [CMD OPTIONS]",1)){
		werror(
#" -h,  --help          Show this help.
CMD:
 collect draw dump
");
		return 0;
	}
	mapping args=Arg.parse(argv);
	array rest=args[Arg.REST];

	ARGUMENT_EXECUTE("collect",collect_main);
	ARGUMENT_EXECUTE("draw",draw_main);
	ARGUMENT_EXECUTE("dump",dump_main);
}

