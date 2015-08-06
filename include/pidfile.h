string pidfile;

void kill_pidfile()
{
	if(pidfile)
		rm(pidfile);
}

void pidfile_quit()
{
	exit(0);
}

#define DECLARE_PIDFILE() DECLARE_ARGUMENT_STRING("pid-file",pid_file_flag,pid_file_str,"=FILE\tWrite pid.")
#define HANDLE_PIDFILE() _handle_pidfile(args,1)
#define HANDLE_PIDFILE_NOSIGNAL() _handle_pidfile(args,0)
void _handle_pidfile(mapping args,int regsig)
{
	pidfile=args["pid-file"];
	if(pidfile){
		if(Stdio.exist(pidfile)){
			int pid;
			sscanf(Stdio.read_file(pidfile),"%d",pid);
			if(pid&&Stdio.is_dir("/proc/"+pid)){
				werror("Process exists, quit.\n");
				exit(1);
			}
		}
		Stdio.write_file(pidfile,sprintf("%d",getpid()));
		atexit(kill_pidfile);
		if(regsig){
			signal(signum("SIGINT"),pidfile_quit);
			signal(signum("SIGTERM"),pidfile_quit);
			signal(signum("SIGKILL"),pidfile_quit);
		}
	}
}

