/*private object align_day=Calendar.ISO.Day();
int align(int t,int sec)
{
	if(sec<=3600*24){
		int daytime=align_day->unix_time();
		int tod=t-daytime;
		return daytime+tod/sec*sec;
	}else if(sec%(3600*24)==0){
		int daytime=align_day->unix_time();
		int tod=t-daytime;
		return daytime/sec*sec;
	}else{
		throw(({"not support.\n",backtrace()}));
	}
}*/
int align(int t,int sec)
{
	if(sec<=3600*24){
		return t/sec*sec;
	}else if(sec%3600==0){
		if(sec%(24*3600)==0){
			int n=sec/(24*3600);
			object second=Calendar.ISO.Second(t);
			return second->year()->unix_time()+(second->day()->year_day()%n)*3600*24;
		}else{
			int n=sec/3600;
			object second=Calendar.ISO.Second(t);
			return second->day()->unix_time()+(second->hour()->hour_no()%n)*3600;
		}
	}
}
array hrtime()
{
	int t=time();
	float u=time(t);
	if(u>1.0){
		t++;
		u-=1.0;
	}
	return ({t,(int)(u*1000000)});
}

class Sleeper(int t){
	int last_time;
	mixed `()(function f,mixed ... args)
	{
		while(time()-last_time<t){
			sleep(1);
		}
		last_time=time();
		return f(@args);
	}
}

class Waker(int t){
	int last_time;
	mixed `()(function f,mixed ... args)
	{
		if(time()-last_time<t){
			//sleep(1);
			return UNDEFINED;
		}
		last_time=time();
		return f(@args);
	}
}

class Idler(int t){
	int last_time;
	mixed `()(function f,mixed ... args)
	{
		if(time()-last_time<t){
			//sleep(1);
			last_time=time();
			return UNDEFINED;
		}
		last_time=time();
		return f(@args);
	}
}

float timeof(function f,mixed ... args)
{
	int base=time();
	float begin=time(base);
	f(@args);
	float end=time(base);
	return end-begin;
}
