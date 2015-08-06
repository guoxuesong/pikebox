class Exception{
	inherit Error.Generic;
	
}
private int mysearch(function(int:mixed) fetch,function valueof,mixed value,int first,int last)
{
	if(first==last)
		return first;
	if(last<first)
		throw(Exception("not found.",backtrace()));

	int middle=(first+last)/2;
	object ob0=fetch(middle);
	while(ob0==0){
		middle++;
		if(middle>last)
			throw(Exception("not found.",backtrace()));
		ob0=fetch(middle);
	}
	object ob=ob0;
	if(middle-1>=first){
		object ob1=fetch(middle-1);
		while(ob1==0||valueof(ob1)==valueof(ob0)){
			middle--;
			if(middle-1<=first)
				return first;
			ob1=fetch(middle-1);
		}
		middle--;
		ob=ob1;
	}

	//werror("curr id=%d\n",middle);
	object t1,t2;
	t1=valueof(ob);
	t2=value;
	if(t1<t2){
		return mysearch(fetch,valueof,value,middle+1,last);
	}else if(t1>t2){
		return mysearch(fetch,valueof,value,first,middle);
	}else{
		return middle;
	}
}

int search(function(int:mixed) fetch,function valueof,mixed value,int begin,int end)
{
	return mysearch(fetch,valueof,value,begin,end-1);
}
