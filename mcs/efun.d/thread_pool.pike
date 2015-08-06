
Thread.Fifo fifo_out;
Thread.Fifo fifo_in;
private void heartbeat()
{
	while(fifo_out->size()){
		[function f,array args]=fifo_out->read();
		f(@args);
	}
	call_out(heartbeat,2);
}
private int len;
void create(int _len,int|void n)
{
	len=_len;
	fifo_out=Thread.Fifo(len);
	fifo_in=Thread.Fifo(len);
	call_out(heartbeat,n||2);
}

protected void call_in(function f,mixed ... args)
{
	checkout();
	fifo_out->write(({f,args||({})}));
}
private void checkin()
{
	werror("fifo_in.size()=%d\n",fifo_in.size());
	//Pike.DefaultBackend(0.0);
	_do_call_outs();

	while(fifo_in.size()>=len){
		_do_call_outs();
		//Pike.DefaultBackend(0.1);
		sleep(0.1);
	}
	fifo_in->write(0);
}

multiset checkout_flags=set_weak_flag((<>),Pike.WEAK);
private void checkout()
{
	int flag=checkout_flags[this_thread()];
	if(flag==0){
		checkout_flags[this_thread()]=1;
		fifo_in->read();
	}
}

protected mixed thread_pool(mixed ...  args)
{
	checkin();
	mixed e=catch{
	return Thread.Thread(Function.curry(lambda(function f,mixed ... args)
			{
			//Thread.Local()->set("checkout_flag",0);
			mixed res=f(@args);
			checkout();
			return res;
			})(@args));
	};
	if(e){
		fifo_in->read();
		throw(e);
	}
}
