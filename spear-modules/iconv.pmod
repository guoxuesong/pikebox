#pike __REAL_VERSION__


//! Call iconv(3) to perform character set conversion
//! @param from
//!   Encoding convert characters from.
//! @param to
//!   Encoding cconvert characters to.
//! @param s
//!   String to be converted.
//! @returns
//!   String converted.
//!
//! @note
//!   More info see iconv manpage.
string `()(string from,string to,string s,void|int ignore_error)
{
	//werror("enter iconv %s %s %O\n",from,to,s);

	if(s==0)
		return 0;
	if(!stringp(s))
		throw(({"ERROR: bad input\n",backtrace()}));

	Cross.CC("gcc -g -shared -fPIC");
	Cross.INCLUDE(
		"#include <iconv.h>\n"
		"#include <errno.h>\n"
		"#include <string.h>\n" );


	string err;
        string res="";
        C{
		iconv_t cd=iconv_open(STRING{to},STRING{from});
		if(cd==(iconv_t)-1){
			P{err=sprintf("iconv: Can't convert (iconv_open fail): %s (%s -> %s)",s,from,to);}
			return;
		}else{
			size_t insize=strlen(STRING{s});
			char* inbuf=STRING{s};
			char buffer[1025];
			while(insize){
				char* outbuf=buffer;
				size_t outsize=1024;
				size_t n=iconv(cd,&inbuf,&insize,&outbuf,&outsize);
				if(n==-1&&errno!=E2BIG){
					iconv_close(cd);
					P{err=sprintf("iconv: Can't convert (%s): %s (%s -> %s)",STRING{strerror(errno)},s,from,to);}
					return;
				}

				*outbuf='\0';
				char* p=buffer;
				P{ res+=STRING{p}; }
			}
			iconv_close(cd);
		}
	}

	if(!err)
		return res;
	else{
		if(ignore_error)
			return res;
		throw(({sprintf("ERROR: %s\n",err),backtrace()}));
	}

}
