#! /bin/env pike
#include <args.h>
int main(int argc,array argv)
{
	if(Usage.usage(argv,"IN-FILE OUT-FILE",2)){
		werror(
#" -h,	--help		Show this help.
 [-r]
");
		return 0;

	}
	mapping args=Arg.parse(argv);
	array rest=args[Arg.REST];

	ARGUMENT_FLAG("r",reverse_flag);

	[string in,string out]=rest;

	object infile=Stdio.FILE(in);
	object outfile=Stdio.FILE(out,"cwt");

	if(!reverse_flag){

		outfile->write(
				"\\documentclass[CJK]{cctart}\n"
				"\\begin{document}\n"
				);;
		foreach(infile->line_iterator();int i;string line){
			if(has_prefix(String.trim_whites(line),"//tex:")){
				outfile->write(sprintf("%s\n",String.trim_whites(line)[sizeof("//tex:")..]));
			}else if(String.trim_whites(line)==""){
				outfile->write("%s\n",line);
			}else{
				outfile->write(sprintf("%%pike:%s\n",line));
			}
		}
		outfile->write(
				"\\end{document}\n"
			      );
	}else{
		int documentclass_line_found;
		int begin_document_line_found;
		int end_document_line_found;
		foreach(infile->line_iterator();int i;string line){
			if(!documentclass_line_found){
				if(has_prefix(line,"\\documentclass")){
					documentclass_line_found++;
					continue;
				}
			}
			if(!begin_document_line_found){
				if(has_prefix(line,"\\begin{document}")){
					begin_document_line_found++;
					continue;
				}
			}
			if(!end_document_line_found){
				if(has_prefix(line,"\\end{document}")){
					end_document_line_found++;
					continue;
				}
			}
			if(has_prefix(String.trim_whites(line),"%pike:")){
				outfile->write(sprintf("%s\n",String.trim_whites(line)[sizeof("%pike:")..]));
			}else if(String.trim_whites(line)==""){
				outfile->write("%s\n",line);
			}else{
				outfile->write(sprintf("//tex:%s\n",line));
			}
		}
	}
}

