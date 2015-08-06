#! /bin/env pike
#include <args.h>
#include <awl.h>
int main(int argc,array argv)
{
	show(
			WIDGETD->horizontal_panel(({
				WIDGETD->textarea("ta1","hello world!"),
				WIDGETD->button("OK","echo [ta1]"),
				}))
			);
}
