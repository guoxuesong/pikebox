private mixed call_out_id;
extern int timeout;
extern mapping container;
extern array globald_path;
extern string key;
int touch()/*{{{*/
{
	if(call_out_id)
		remove_call_out(call_out_id);
	call_out_id=call_out(lambda(object ob){
			//mixed l=GLOBALD->mutex->lock();
			m_delete(container,predef::`->(ob,key));
			if(globald_path){
				GLOBALD->delete(globald_path+({predef::`->(ob,key)}));
				/*foreach(GLOBALD->subglobalds;string key;object globald){
					globald->delete(globald_path+({predef::`->(ob,key)}));
				}*/
			}
			destruct(ob);
			//destruct(l);
			},timeout,this);
}/*}}}*/

