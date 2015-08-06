#! /bin/env pike
#include <args.h>
#include <mcs.h>
int main(int argc,array argv)
{
	if(this_player()){
		object user=this_player();
		werror("%s\n",user->name);
		write("%s\n",user->name);
	}else{
		werror("%s\n","NOBODY");
		write("%s\n","NOBODY");
	}
}
