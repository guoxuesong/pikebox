mapping tasks=([]);
MIXIN Session{
	//extern function gen_uniq_id;
	extern function write;
	PUBLIC jobs()
	{
		foreach(tasks;string id;mapping info){
			write("%s %s %ds %d/%s\n",id,info->pause?"Stoped":"",info->interval,info->step,info->iterator&&info->iterator->_sizeof?info->iterator->_sizeof()+"":"-",);
		}
	}
	private void step(string id,Iterator i,int interval,function f,function on_end,mixed ... args){

		object old_session=THIS_SESSIOND->this_session();
		THIS_SESSIOND->set_this_session(this);
		//GLOBALD->curr_session=this;

		int err;

		if(i)
			err=f(i->index(),i->value(),@args);
		else
			err=f(@args);

		THIS_SESSIOND->set_this_session(old_session);
		//GLOBALD->curr_session=old_session;


		tasks[id]->step++;
		if((i==0||i->next())&&!err){
			tasks[id]->call_out_id=call_out(step,interval,id,i,interval,f,on_end,@args);
		}else{
			if(on_end)
				on_end(@args);
			m_delete(tasks,id);
		}
	}
	int add_task(string key,int after,Iterator i,int interval,function|array f,mixed ... args)
	{
		string id=key;
		if(tasks[id])
			return 1;
		function on_end;
		if(arrayp(f)){
			[f,on_end]=f;
		}
			
		tasks[id]=tasks[id]||(["iterator":i,"func":f,"interval":interval,"call_out_id":0,"step":0,"pause":0,"on_end":on_end,"args":args]);
		tasks[id]->call_out_id=call_out(step,after,id,i,interval,f,on_end,@args);
	}
	int kill_task(string id)
	{
		if(tasks[id]){
			remove_call_out(tasks[id]->call_out_id);
			m_delete(tasks,id);
		}else{
			return 1;
		}
	}
	SUPERUSER kill(string id)
	{
		return kill_task(id);
	}

	int pause_task(string id)
	{
		if(tasks[id]){
			remove_call_out(tasks[id]->call_out_id);
			tasks[id]->pause=1;
		}else{
			return 1;
		}
	}
	SUPERUSER stop(string id)
	{
		return pause_task(id);
	}

	int resume_task(string id)
	{
		if(tasks[id]&&tasks[id]->pause){
			tasks[id]->call_out_id=call_out(step,0,id,tasks[id]->iterator,tasks[id]->interval,tasks[id]->func,tasks[id]->on_end,@tasks[id]->args);
			remove_call_out(tasks[id]->call_out_id);
			tasks[id]->pause=1;
		}else{
			return 1;
		}
	}

	SUPERUSER resume(string id)
	{
		return resume_task(id);
	}

}