#! /bin/env pike
#include <args.h>
#include <awl.h>
int main(int argc,array argv)
{
	show(
			WIDGETD->text(argv[1..]*" "),
			);
}

