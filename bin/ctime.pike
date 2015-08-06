#! /bin/env pike
int main(int argc,array argv)
{
	write("%s",ctime((int)argv[1]));
}
