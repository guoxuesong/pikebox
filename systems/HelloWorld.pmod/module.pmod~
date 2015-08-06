#include <class.h>
#define CLASS_HOST "HelloWorld"
class DynClass{
#include <class_imp.h>
}

class UniqIDStatic{
	class Static{
		int sn;
	};
}

class UniqID{
	int id=++(STATIC(UniqIDStatic)->sn);
}

class HelloWorldMode{
	class Interface{
		void helloworld();
	}
	class Default{
		void helloworld()
		{
			werror("Default mode\n");
			write("hello world\n");
		}
	}
	class PerChar{
		void helloworld()
		{
			werror("PerChar mode\n");
			foreach("hello world\n"/"",string c){
				write("%s",c);
			}
		}
	}
}

class HelloWorld{
	inherit HelloWorldMode.Interface;
}

object default_program=CLASS(HelloWorld,HelloWorldMode.Default);

#include <args.h>
int main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	DECLARE_ARGUMENT_FLAG("per-char",per_char_flag,"Write it one charactor a time.")
	if(Usage.usage(args,"",0)){
		return 0;
	}
	HANDLE_ARGUMENTS();

	if(per_char_flag){
		CLASS(HelloWorld,HelloWorldMode.PerChar)()->helloworld();
	}else{
		default_program()->helloworld();
	}
}

