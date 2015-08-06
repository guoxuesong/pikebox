#! /bin/env pike

array filename_split(string fullname)
{
	string filename,ext;
	if(search(fullname,".")>0){
		filename=((fullname/".")[..<1])*".";
		ext=(fullname/".")[-1];
	}else{
		filename=fullname;
		ext="";
	}
	//werror("fullname=%O",file);
	return ({filename,ext});
}

array gen_vim_args(string tmppath,string vimsee_tmppath,int argc,array argv,int|void setmakeprg)
{
	array vim_args=({});
	//werror("argc=%d,argv=%O\n",argc,argv);
	if(argc==2&&argv[1]!="-"){
		rm(tmppath+"/pikebox_template");
		string file=argv[1];
		if(has_suffix(file,".pmod/")){
			file=argv[1]=file[..<1];
		}
		if(!Stdio.exist(file)||Stdio.is_dir(file)){
			if(has_suffix(file,".pmod")&&!has_suffix(file,"/module.pmod")&&file!="module.pmod"){
				mkdir(file);
				file=argv[1]=file+"/module.pmod";
			}
			if(!has_prefix(file,"/")){
				file=combine_path(getcwd(),file);
			}
		}

		string fullname=basename(file);
		[string filename,string fileext]=filename_split(fullname);

		string dir=basename(dirname(file));
		[string pathname,string pathext]=filename_split(dir);

		string modulename;
		if(pathext=="pmod"){
			modulename=pathname;
		}else if(fileext=="pmod"){
			//modulename=filename;
			modulename="Unkonwn";
		}else{
			modulename="Unkonwn";
		}
		if(!Stdio.exist(file)){
			werror("%s not exist.\n",file);
			Stdio.write_file(tmppath+"/pikebox_template","");
			array a=explode_path(file);
			if(sizeof(a)>2){
				int p=2;
				while(p<sizeof(a)){
					string pathname=a[-p];
					string uppath=combine_path(@a[..<p]);

					string template=combine_path(uppath,"templates/"+pathname+"."+fileext+".template");
					if(Stdio.exist(template)){
						Stdio.write_file(tmppath+"/pikebox_template",replace(Stdio.read_file(template),([
										"$(FILENAME)":filename,
										"$(FILEEXT)":fileext,
										"$(MODULE)":modulename,
										])));
						break;
					}
					p++;
				}
			}
			vim_args+=({
					"-c",sprintf("sil 0 read %s/pikebox_template",vimsee_tmppath)
					});
		}
		if(modulename!="Unkonwn"&&setmakeprg){
			if(getenv("USING_SPEAR")==0){
				vim_args+=({
						"-c",sprintf("set makeprg=%s/bin/run.pike\\ %s",getenv("PIKEBOX"),modulename)
						});
			}else{
				vim_args+=({
						"-c",sprintf("set makeprg=spear\\ --path=%s/sopath\\ %s/bin/run.pike\\ %s",getenv("HOME"),getenv("PIKEBOX"),modulename)
						});
			}
		}
	}
	return vim_args+argv[1..];
}

int main(int argc,array argv)
{
	array vim_args=({
			"-c","set path+=~/PikeBox/include"
			});
	vim_args+=gen_vim_args("/tmp","/tmp",argc,argv,1);
	Process.exec("/usr/bin/vim",@vim_args);
}
