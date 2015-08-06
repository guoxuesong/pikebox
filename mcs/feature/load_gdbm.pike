DAEMON:
mapping gdbms=set_weak_flag(([]),Pike.WEAK_VALUES);//because using WEAK, only fs_gdbm can be used, or no close will be called
object load_gdbm(string file,string|void flag)
{
	if(gdbms[file]==0){
		//gdbms[file]=Gdbm.gdbm(file,flag||"rwcs");
		gdbms[file]=FakeGdbm.fs_gdbm(file);
#ifndef __NT__
		chown(file,WORKING_UID,WORKING_GID);
#endif
	}
	return gdbms[file];
}


void destroy()/*{{{*/
{
	werror("Info: Close gdbms.\n");
	foreach(gdbms;string key;object db)
	{
		db->close();
	}
}/*}}}*/
