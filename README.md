The main reason to create PikeBox is the DynClass idea.

Just do this:

sh box.sh
home
vi systems/MyProj.pmod

You get this:

#include <class.h>
#define CLASS_HOST "MyProj"
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

class MyProjMode{
	class Interface{
	}
	class Default{
	}
}

class MyProj{
	inherit MyProjMode.Interface;
}

object default_program=CLASS(MyProj,MyProjMode.Default);

#include <args.h>
int main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	if(Usage.usage(args,"",0)){
		return 0;
	}
	HANDLE_ARGUMENTS();
}

This is a empy application using DynClass, you can using "run MyProj" to run it.How to handle arguments see include/args.h

Create a project under systems means:

* your project always changes,
* you do not have a final design of it,
* you want to change from one idea to another as smoothly as posible.

or

* you want facet-oriented programming

Facet-oriented programming means you have some abstract classes A,B,C,... ,
every abstract class has maybe a large number of implements
a_1,a_2,...,a_n;b_1,b_2,...,b_m;c_1,c_2,...,c_p;... every combination of them
is just posible.

Technological, we just need a C++-template-class-like macro, for example
CLASS(Base,a_3,b_9,c_6) return a class inherits Base,a_3,b_9 and c_6, Base is a
class inherits A,B,C.

I will explain why a changing-design project is similar to facet-oriented.
There are two kind of changes:

1) totally change, this is rarely happened, if it happened, backup your project
and create a new one.

2) some parts of some classes changes together, if this happened, split the
changing part of every class, as a abstract base class, and add two implements
of it: the one before change, and the one after.

If a part of a class changes, it always changes again, or changes back. You
will got a abstract class for the changing part, and a lot of implements for
every idea.

By name the implements properly, for example a_design1,b_design1,c_desgn1,...
you can mark what is changed together. By doing a search-replace, you can
easily switch back to the old design, if the new design not works.

